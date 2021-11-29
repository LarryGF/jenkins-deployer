#! /bin/bash
#### DOCKER SETUP ###############################################################################
printf "\n[*] Trying to figure out GID of docker.sock"
#Need to set the DOCKER_PATH env var before running the script if it's not running in this path
docker_gid=`ls -ldn ${DOCKER_PATH:-'/var/run/docker.sock'} | awk '{print $4}'`
printf "\n[*] Docker GID: $docker_gid \n Bringing the compose up with correct ownership for docker.sock"

DOCKER_GID=$docker_gid docker-compose up --build --remove-orphans -d

#### VAULT SETUP #################################################################################

### INITIAL VARIABLES ##############################################
SLEEP_BETWEEN_RETRIES_SEC=${SLEEP_BETWEEN_RETRIES_SEC:-'2'}
MAX_RETRIES=${MAX_RETRIES:-'10'}
#Need to set the VAULT_URL env var before running the script if it's running in a different host/port
vault_addr=${VAULT_URL:-'http://127.0.0.1:8200'}
vault_health_url="${vault_addr}/v1/sys/health"
keys_path=${KEYS_PATH:-'./keys/'}
total_key=${TOTAL_KEYS:-6}
used_keys=${USED_KEYS:-3}

vault_user=${VAULT_USER:-'admin'}
vault_pass=${VAULT_PASS:-'admin'}
#############################################################

printf "\n[*] Trying to initialize Vault deployment running on: $vault_addr \nVerifying status of Vault deployment running on: $vault_health_url"
for (( i=1; i<="$MAX_RETRIES"; i++ )); do
    response=$(curl --show-error --location --insecure --silent --write-out "HTTPSTATUS:%{http_code}" "$vault_health_url" || true)
    status=$(echo "$response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
    if [[ "$status" -eq 200 ]]; then
        printf "\n[**] Vault server $server_ip is initialized, unsealed, and active."
        break
        
        elif [[ "$status" -eq 429 ]]; then
        printf "\n[**] Vault server $server_ip is unsealed and in standby mode."
        break
        
        elif [[ "$status" -eq 501 ]]; then
        printf "\n[**] Vault server $server_ip is uninitialized."
        vault operator  init -address=$vault_addr -n $total_key -t $used_keys > output
        vault_token=$(grep 'Initial Root Token:' output | awk '{print substr($NF, 1, length($NF))}')
        echo $vault_token > "${keys_path}token"
        # export VAULT_TOKEN=$vault_token
        cat output | grep Unseal > "${keys_path}key"
        sed  -i 's/Unseal.*: //g' "${keys_path}key"
        sleep "$SLEEP_BETWEEN_RETRIES_SEC"
        printf "\n[**] Vault server $server_ip has been initialized."
        rm output
        elif [[ "$status" -eq 503 ]]; then
        printf "\n[**] Vault server $server_ip is sealed.\n"
        vault_token=$(cat "${keys_path}token")
        head -$used_keys "${keys_path}key" | xargs -L1 vault operator  unseal -address=$vault_addr
        sleep "$SLEEP_BETWEEN_RETRIES_SEC"
        
        printf "\n[*] Determining auth process and user setup\n"
        if [[ ! $(vault auth list | grep userpass) ]]; then
            printf "\n[*] Initializing auth process and user setup\n"
            vault login -address=$vault_addr token=$vault_token
            printf "\n[*] Creating user/password\n"
            vault auth enable  -address=$vault_addr userpass
            vault policy write -address=$vault_addr $vault_user ./consul/config/admin.hcl
            vault write -address=$vault_addr auth/userpass/users/webui password=$vault_pass policies=$vault_user
        else
            printf "\n[*] Auth process and user setup already exists\n"
        
        fi
        
    else
        printf "\nVault server $server_ip returned unexpected status code $status. Will sleep for $SLEEP_BETWEEN_RETRIES_SEC seconds and check again."
        sleep "$SLEEP_BETWEEN_RETRIES_SEC"
    fi
done
