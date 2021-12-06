/* groovylint-disable CompileStatic */
organizationFolder('GitHub Organization Folder') {
    description('GitHub Organization folder configured with JCasC')
    displayName("${GITHUB_REPO_OWNER}")
    triggers {
        cron('H/5 * * * *')
    }
    organizations {
        github {
            repoOwner("${GITHUB_REPO_OWNER}")
            credentialsId('github-app')
            apiUri('https://api.github.com')
            traits {
                gitHubBranchDiscovery {
                    strategyId(1)
                }
                gitHubPullRequestDiscovery {
                    strategyId(1)
                }
            }
        }
    }
}
