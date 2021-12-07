# Running for the first time

```bash
    bash run.sh
```

## Configuration

| VARIABLE                | TYPE                    | Default value | Description                                                  |
| :---------------------- | ----------------------- | ------------- | ------------------------------------------------------------ |
| ADMIN_USERS             | Comma-separated strings |               | Admin GitHub user names                                      |
| GITHUB_CLIENT_ID        | String                  |               | Client ID for the GitHub OAuth App                           |
| GITHUB_CLIENT_SECRET    | String                  |               | Client secret for the GitHub OAuth App                       |
| GITHUB_ACCESS_TOKEN     | String                  |               | Token for the GitHub OAuth App                               |
| GITHUB_APP_ID           | String                  |               | APP ID for the GitHub App                                    |
| GITHUB_REPO_OWNER       | String                  |               | User or Organization that the GitHub App has access to       |
| GITHUB_PRIVATE_KEY      | String -deprecated-     |               | Private key to use authenticating against the GitHub App     |
| SSH_PRIVATE_FILE_PATH   | String                  |               | Path to the Private key (must be a _.pem_ file) to use authenticating against the GitHub App |
| DOCKER_PATH             | String                  |               | Path to the Docker socket (can be remote)                    |
| JENKINS_VAULT_ROLE_ID   | String -automatic-      |               | Role Id that Jenkins will use to fetch secrets from Vault    |
| JENKINS_VAULT_SECRET_ID | String -automatic-      |               | Secret Id that Jenkins will use to fetch secrets from Vault  |
|                         |                         |               |                                                              |
| HOST                    | String                  |               | Hostname where the deployment is going to run                |
|                         |                         |               |                                                              |
| VAULT_ADDR              | String                  |               | Vault address in the form: \<protocol\>://\<hostname\>:\<port\> |
|                         |                         |               |                                                              |
| NGROK_AUTH              | String                  |               | Token for the Ngrok service                                  |
| NGROK_PORT              | Integer                 |               | Port where Ngrok will forward traffic (must be the Jenkins port) |
| NGROK_DEBUG             | Boolean                 |               |                                                              |

### Adding Minikube to Portainer

<https://docs.portainer.io/v/ce-2.9/admin/environments/add/kubernetes>

```bash
```

```bash
minikube service portainer-agent -n portainer
```

Use that _url_ in Portainer
