#! /bin/bash
printf "\nTrying to figure out GID of docker.sock"
#Need to set the DOCKER_PATH env var before running the script if it's not running in this path
docker_gid=`ls -ldn ${DOCKER_PATH:-'/var/run/docker.sock'} | awk '{print $4}'`
printf "\nDocker GID: $docker_gid \n Bringing the compose up with correct ownership for docker.sock"

DOCKER_GID=$docker_gid docker-compose up --build --remove-orphans -d

#Need to set the VAULT_URL env var before running the script if it's running in a different host/port
SLEEP_BETWEEN_RETRIES_SEC=${SLEEP_BETWEEN_RETRIES_SEC:-'2'}
MAX_RETRIES=${MAX_RETRIES:-'10'}
vault_addr=${VAULT_URL:-'http://127.0.0.1:8200'}
vault_health_url="${vault_addr}/v1/sys/health"
export VAULT_ADDR=$vault_addr
keys_file=${KEYS_FILE:-'./keys/keys'}
total_key=${TOTAL_KEYS:-6}
used_keys=${USED_KEYS:-3}

printf "\nTrying to initialize Vault deployment running on: $vault_addr \nVerifying status of Vault deployment running on: $vault_health_url"
for (( i=1; i<="$MAX_RETRIES"; i++ )); do
    response=$(curl --show-error --location --insecure --silent --write-out "HTTPSTATUS:%{http_code}" "$vault_health_url" || true)
    status=$(echo "$response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
    if [[ "$status" -eq 200 ]]; then
        printf "\nVault server $server_ip is initialized, unsealed, and active."
        break
        
        elif [[ "$status" -eq 429 ]]; then
        printf "\nVault server $server_ip is unsealed and in standby mode."
        break
        
        elif [[ "$status" -eq 501 ]]; then
        printf "\nVault server $server_ip is uninitialized.\n"
        vault operator init -n $total_key -t $used_keys > output
        vault_token=$(grep 'Initial Root Token:' output | awk '{print substr($NF, 1, length($NF)-1)}')
        export VAULT_TOKEN=$vault_token
        cat output | grep Unseal > $keys_file
        sed  -i 's/Unseal.*: //g' $keys_file
        rm output
        sleep "$SLEEP_BETWEEN_RETRIES_SEC"
        printf "Vault server $server_ip has been initialized."
        elif [[ "$status" -eq 503 ]]; then
        printf "\nVault server $server_ip is sealed.\n"
        head -$used_keys $keys_file | xargs -L1 vault operator unseal
        sleep "$SLEEP_BETWEEN_RETRIES_SEC"
        
        
    else
        printf "\nVault server $server_ip returned unexpected status code $status. Will sleep for $SLEEP_BETWEEN_RETRIES_SEC seconds and check again."
        sleep "$SLEEP_BETWEEN_RETRIES_SEC"
    fi
done
