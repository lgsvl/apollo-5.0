pipeline {
  agent {
    node {
      label "gpu-builder"
      customWorkspace "/home/jenkins/workspace/apollo-5.0"
    }
  }

  options {
    gitLabConnection("${GITLAB_HOST}")
    skipDefaultCheckout(true)
    buildDiscarder(logRotator(numToKeepStr: '20'))
    timestamps()
  }

  parameters {
    string(name: 'BRANCH_NAME', defaultValue: 'simulator', description: 'Branch from duckietown/apollo-5.0 to build', trim: true)
    string(name: 'DOCKER_IMAGE_NAME', defaultValue: 'lgsvl/apollo-5.0:standalone-x86_64-14.04-5.0-latest', description: 'Name of the docker image built in this branch', trim: true)
    string(name: 'WISE_AWS_ECR_ACCOUNT_ID', defaultValue: '853285614468', description: 'The AWS account ID whose ECR will be used', trim: true)
    string(name: 'WISE_AWS_ECR_REGION', defaultValue: 'us-east-1', description: 'The AWS region where the ECR is located', trim: true)
    credentials( name: 'WISE_AWS_ECR_CREDENTIALS_ID', required: true, defaultValue: "simulator--aws-credentials", description: 'The credentials to be used for accessing the ECR', credentialType: 'com.cloudbees.jenkins.plugins.awscredentials.AWSCredentialsImpl')
  }

  environment {
    PYTHONUNBUFFERED = "1"
    DISPLAY = ":0"
    JENKINS_BUILD_ID = "${BUILD_ID}"
    DOCKER_TAG = "build__${JENKINS_BUILD_ID}"
    GITLAB_REPO = "duckietown/apollo-5.0"
    ECR_REPO = "wise/apollo-5.0"
    // used to keep DOCKER_REPO_SUFFIX empty (normally for master branch, but for apollo this needs to be "simulator")
    DEFAULT_BRANCH_NAME = "simulator"
  }

  stages {
    stage("Git") {
      steps {

        checkout([
          $class: "GitSCM",
          branches: [[name: "refs/heads/${BRANCH_NAME}"]],
          browser: [$class: "GitLab", repoUrl: "https://${GITLAB_HOST}/duckietown/apollo-5.0", version: env.GITLAB_VERSION],
          doGenerateSubmoduleConfigurations: false,
          extensions: [
            [$class: "GitLFSPull"],
            [$class: 'SubmoduleOption',
            disableSubmodules: false,
            parentCredentials: true,
            recursiveSubmodules: true,
            reference: '',
            trackingSubmodules: false]
          ],
          userRemoteConfigs: [[
            credentialsId: "Jenkins-Gitlab",
            url: "git@${GITLAB_HOST}:duckietown/apollo-5.0.git"
          ]]
        ])
      }
    }

    stage("Docker") {
      steps {
        sh """
          docker/build/standalone.x86_64.sh rebuild
          docker image rm lgsvl/apollo-5.0:pcl-x86_64-14.04-5.0-20210319
        """
      }
    }
    stage("uploadGitlab") {
      environment {
        DOCKER = credentials("Jenkins-Gitlab")
      }
      steps {
        sh """
          if [ "${BRANCH_NAME}" != "${DEFAULT_BRANCH_NAME}" ]; then
              DOCKER_REPO_SUFFIX="/`echo ${BRANCH_NAME} | tr / -  | tr [:upper:] [:lower:]`"
          fi
          docker tag ${DOCKER_IMAGE_NAME} ${GITLAB_HOST}:4567/${GITLAB_REPO}\$DOCKER_REPO_SUFFIX:\$DOCKER_TAG
          docker login -u ${DOCKER_USR} -p ${DOCKER_PSW} ${GITLAB_HOST}:4567
          docker push ${GITLAB_HOST}:4567/${GITLAB_REPO}\$DOCKER_REPO_SUFFIX:\$DOCKER_TAG

          docker image rm ${GITLAB_HOST}:4567/${GITLAB_REPO}\$DOCKER_REPO_SUFFIX:\$DOCKER_TAG
        """
      }
    } // uploadGitlab

    stage("uploadECR") {
/*
      when {
        anyOf {
            buildingTag()
            branch 'master'
            environment name: "UPLOAD_TO_ECR", value: "true"
        }
      }
*/
      steps {
        dir("Jenkins") {
          sh "echo Using credentials ${WISE_AWS_ECR_CREDENTIALS_ID}"
          withCredentials([[credentialsId: "${WISE_AWS_ECR_CREDENTIALS_ID}", accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY', $class: 'AmazonWebServicesCredentialsBinding']]) {
            sh """
              DOCKER_REGISTRY="${WISE_AWS_ECR_ACCOUNT_ID}.dkr.ecr.${WISE_AWS_ECR_REGION}.amazonaws.com"
              if [ "${BRANCH_NAME}" != "${DEFAULT_BRANCH_NAME}" ]; then
                  DOCKER_REPO_SUFFIX="/`echo ${BRANCH_NAME} | tr / -  | tr [:upper:] [:lower:]`"
              fi

              if ! docker run -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -t amazon/aws-cli ecr get-login-password --region $WISE_AWS_ECR_REGION | docker login --username AWS --password-stdin \$DOCKER_REGISTRY; then
                echo "ABORT: bad AWS credentials?"
                exit 1
              fi
              if ! docker run -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -t amazon/aws-cli ecr create-repository --repository-name \$ECR_REPO\$DOCKER_REPO_SUFFIX --region $WISE_AWS_ECR_REGION; then
                echo "INFO: aws-cli ecr create-repository --repository-name \$ECR_REPO\$DOCKER_REPO_SUFFIX --region $WISE_AWS_ECR_REGION failed - assuming that it's because the repo already exists in ECR"
              fi

              docker tag ${DOCKER_IMAGE_NAME} \$DOCKER_REGISTRY/\$ECR_REPO\$DOCKER_REPO_SUFFIX:\$DOCKER_TAG
              docker push \$DOCKER_REGISTRY/\$ECR_REPO\$DOCKER_REPO_SUFFIX:\$DOCKER_TAG

              docker image rm \$DOCKER_REGISTRY/\$ECR_REPO\$DOCKER_REPO_SUFFIX:\$DOCKER_TAG ${DOCKER_IMAGE_NAME}
            """
          }
        }
      }
    } // uploadECR
    stage("cleanup docker") {
      steps {
        sh """
          docker stop apollo_5.0_dev_$USER

          docker container prune -f

          docker volume prune -f
          docker image prune -f
        """
      }
    }
  } // stages
}
