pipeline {
    agent any

    environment {
        // Define your environment variables here
        CS_REGISTRY = 'registry.crowdstrike.com'
        CS_CLIENT_ID = credentials('cs-client-id')
        CS_CLIENT_SECRET = credentials('cs-client-secret')
        FALCON_REGION = 'us-2'
        PROJECT_PATH = '.'
        NGINX_IMAGE = 'nginx:latest'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Pull Nginx Image') {
            steps {
                sh 'docker pull ${NGINX_IMAGE}'
            }
        }

        stage('FCS IaC Scan Execution') {
            steps {
                script {
                    def SCAN_EXIT_CODE = sh(
                        script: '''
                            set +x
                            # check if required env vars are set in the build set up

                            scan_status=0
                            if [[ -z "$CS_USERNAME" || -z "$CS_PASSWORD" || -z "$CS_REGISTRY" || -z "$CS_IMAGE_NAME" || -z "$CS_IMAGE_TAG" || -z "$CS_CLIENT_ID" || -z "$CS_CLIENT_SECRET" || -z "$FALCON_REGION" || -z "$PROJECT_PATH" ]]; then
                                echo "Error: required environment variables/params are not set"
                                exit 1
                            else  
                                # login to crowdstrike registry
                                echo "Logging in to crowdstrike registry with username: $CS_USERNAME"
                                echo "$CS_PASSWORD" | docker login "$CS_REGISTRY" --username "$CS_USERNAME" --password-stdin
                                
                                if [ $? -eq 0 ]; then
                                    echo "Docker login successful"
                                    #  pull the fcs container target
                                    echo "Pulling fcs container target from crowdstrike"
                                    docker pull "$CS_IMAGE_NAME":"$CS_IMAGE_TAG"
                                    if [ $? -eq 0 ]; then
                                        echo "fcs docker container image pulled successfully"
                                        echo "=============== FCS IaC Scan Starts ==============="

                                        docker run --network=host --rm "$CS_IMAGE_NAME":"$CS_IMAGE_TAG" --client-id "$CS_CLIENT_ID" --client-secret "$CS_CLIENT_SECRET" --falcon-region "$FALCON_REGION" iac scan -p "$PROJECT_PATH" --fail-on "high=10,medium=70,low=50,info=10"
                                        scan_status=$?
                                        echo "=============== FCS IaC Scan Ends ==============="
                                    else
                                        echo "Error: failed to pull fcs docker image from crowdstrike"
                                        scan_status=1
                                    fi
                                else
                                    echo "Error: docker login failed"
                                    scan_status=1
                                fi
                            fi
                        ''',
                        returnStatus: true
                    )
                    echo "fcs-iac-scan-status: ${SCAN_EXIT_CODE}"
                    if (SCAN_EXIT_CODE == 40) {
                        echo "Scan succeeded & vulnerabilities count are ABOVE the '--fail-on' threshold; Pipeline will be marked as Success, but this stage will be marked as Unstable"
                        currentBuild.result = 'UNSTABLE'
                    } else if (SCAN_EXIT_CODE == 0) {
                        echo "Scan succeeded & vulnerabilities count are BELOW the '--fail-on' threshold; Pipeline will be marked as Success"
                        currentBuild.result = 'SUCCESS'
                    } else {
                        currentBuild.result = 'FAILURE'
                        error "Unexpected scan exit code: ${SCAN_EXIT_CODE}"
                    }
                }
            }
        }
    }

    post {
        success {
            echo 'Build succeeded!'
        }
        unstable {
            echo 'Build is unstable, but still considered successful!'
        }
        failure {
            echo 'Build failed!'
        }
        always {
            echo "FCS IaC Scan Execution complete.."
        }
    }
}