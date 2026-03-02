pipeline {
    agent any
    environment {
        // IDs must match what you created in Jenkins UI
        DOCKERHUB_CREDENTIALS = credentials('Duy200506') 
        KUBECONFIG = credentials('k8s-secret')
        DOCKER_USER = "khanhduy05"
        IMAGE_NAME = "devops-project"
    }
    stages {
        stage('Build Image') {
            steps {
                sh "docker build -t $DOCKER_USER/$IMAGE_NAME:${env.BUILD_ID} ."
                sh "docker tag $DOCKER_USER/$IMAGE_NAME:${env.BUILD_ID} $DOCKER_USER/$IMAGE_NAME:latest"
            }
        }
        stage('Push to Docker Hub') {
            steps {
                sh "echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin"
                sh "docker push $DOCKER_USER/$IMAGE_NAME:${env.BUILD_ID}"
                sh "docker push $DOCKER_USER/$IMAGE_NAME:latest"
            }
        }
        stage('Deploy to AWS K8s') {
            steps {
                // Using the insecure flag because we are connecting via Public IP
                sh "kubectl --kubeconfig=$KUBECONFIG --insecure-skip-tls-verify apply -f k8s/deployment.yaml"
            }
        }
    }
}
