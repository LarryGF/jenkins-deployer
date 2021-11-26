multibranchPipelineJob('image-jenkins') {
        branchSources {
          github {
            // The id option in the Git and GitHub branch source contexts is now mandatory (JENKINS-43693).
            id('154563') // IMPORTANT: use a constant and unique identifier
            scanCredentialsId('github-app')
            repoOwner('larrygf')
            //repository('my-repository')
            // apiUri('http://my-github-server/api/v3') // Optional, needed for private github enterprise servers
          }
        }
        orphanedItemStrategy {
          discardOldItems {
            numToKeep(1)
          }
        }
        triggers {
          periodic(5)
        }
      }
