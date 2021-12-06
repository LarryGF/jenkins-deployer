#! /bin/bash
#### DOCKER SETUP ###############################################################################
printf "\n[*] Trying to figure out GID of docker.sock"
#Need to set the DOCKER_PATH env var before running the script if it's not running in this path
docker_gid=`ls -ldn ${DOCKER_PATH:-'/var/run/docker.sock'} | awk '{print $4}'`
printf "\n[*] Docker GID: $docker_gid \n Bringing the compose up with correct ownership for docker.sock"

DOCKER_GID=$docker_gid docker-compose up --build --remove-orphans -d vault consul

#### VAULT SETUP #################################################################################

### INITIAL VARIABLES ##############################################
SLEEP_BETWEEN_RETRIES_SEC=${SLEEP_BETWEEN_RETRIES_SEC:-'2'}
MAX_RETRIES=${MAX_RETRIES:-'10'}
#Need to set the VAULT_ADDR env var before running the script if it's running in a different host/port
vault_addr=${VAULT_ADDR:-'http://127.0.0.1:8200'}
export VAULT_ADDR=${vault_addr}
vault_health_url="${vault_addr}/v1/sys/health"
keys_path=${KEYS_PATH:-'./keys/'}
total_key=${TOTAL_KEYS:-6}
used_keys=${USED_KEYS:-3}

vault_user=${VAULT_USER:-'admin'}
vault_pass=${VAULT_PASS:-'admin'}
#############################################################

printf "\n[*] Trying to initialize Vault deployment running on: $vault_addr \nVerifying status of Vault deployment running on: $vault_health_url\n"
for (( i=1; i<="$MAX_RETRIES"; i++ )); do
    response=$(curl --show-error --location --insecure --silent --write-out "HTTPSTATUS:%{http_code}" "$vault_health_url" || true)
    status=$(echo "$response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
    if [[ "$status" -eq 200 ]]; then
        printf "\n[**] Vault server $server_ip is initialized, unsealed, and active.\n"
        vault_token=$(cat "${keys_path}token")
        vault login -address=$vault_addr token=$vault_token
        printf "\n[*] Determining auth process and user setup\n"
        if [[ ! $(vault secrets list | grep kv) ]]; then
            printf "\n[*] Enabling kv secrets \n"
            ##TODO make it work with version 2
            #needed to switch this due to conflicts of jenkins plugin with kv version 2
            vault secrets enable -version=1 kv
        else
            printf "\n[*] kv secrets already enabled \n"
        fi
        if [[ ! $(vault list auth/userpass/users | grep jenkins) ]]; then
            printf "\n[*] Initializing jenkins user \n"
            vault policy write -address=$vault_addr jenkins ./consul/config/jenkins.hcl
            if [[ ! $(vault read auth/approle/role/jenkins | grep policies) ]];then
                printf "\n[*] Creating Jenkins appRole\n"
                vault auth enable -address=$vault_addr approle
                vault write auth/approle/role/jenkins \
                secret_id_ttl=10m \
                token_num_uses=10 \
                token_ttl=20m \
                token_max_ttl=30m \
                secret_id_num_uses=40 \
                token_policies="jenkins"
                vault read auth/approle/role/jenkins/role-id > $keys_path/jenkins_AppRole
                vault write -force auth/approle/role/jenkins/secret-id >> $keys_path/jenkins_AppRole
            fi
        else
            printf "\n[*] jenkins user already exists \n"
        fi
        if [[ ! $(vault list auth/userpass/users | grep ${vault_user}) ]]; then
            printf "\n[*] Creating user/password\n"
            vault auth enable  -address=$vault_addr userpass
            vault policy write -address=$vault_addr $vault_user ./consul/config/admin.hcl
            vault write -address=$vault_addr "auth/userpass/users/${vault_user}" password=$vault_pass policies=$vault_user
            
        else
            printf "\n[*] Auth process and user setup already exists\n"
            
        fi
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
        
        
    else
        printf "\nVault server $server_ip returned unexpected status code $status. Will sleep for $SLEEP_BETWEEN_RETRIES_SEC seconds and check again.\n"
        sleep "$SLEEP_BETWEEN_RETRIES_SEC"
    fi
done

### JENKINS SETUP ##############################################
role_id="$(cat $keys_path/jenkins_AppRole | grep 'role_id' | head -1| awk '{print substr($NF, 1, length($NF))}')"
secret_id="$(cat $keys_path/jenkins_AppRole | grep 'secret_id' | head -1 | awk '{print substr($NF, 1, length($NF))}')"
sed  "s/JENKINS_VAULT_ROLE_ID.*/JENKINS_VAULT_ROLE_ID=${role_id}/" -i .env
sed  "s/JENKINS_VAULT_SECRET_ID.*/JENKINS_VAULT_SECRET_ID=${secret_id}/" -i .env

DOCKER_GID=$docker_gid docker-compose up --build --remove-orphans -d traefik jenkins whoami ngrok
# Need to figure out a way of reloading config instead of restarting container
# DOCKER_GID=$docker_gid docker-compose restart jenkins
