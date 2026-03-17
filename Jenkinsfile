pipeline {
    agent any
    environment {
        DOCKERHUB_CREDENTIALS = credentials('Duy200506') 
        KUBECONFIG = credentials('k8s-secret')
        // Thêm Credential ID của SonarQube Token bạn đã tạo
        SONAR_TOKEN = credentials('sonarqube-token') 
        DOCKER_USER = "khanhduy05"
        IMAGE_NAME = "devops-project"
    }
    stages {
        stage('Install Dependencies') {
            steps {
                // Cài đặt thư viện Node.js trước khi scan/build
                sh "npm install"
            }
        }

        stage('Static Analysis (SonarQube)') {
            steps {
                // Sử dụng Maven để thực hiện quét SonarQube cho dự án JS
                // 'MySonarServer' là tên bạn đặt trong Manage Jenkins > System
                withSonarQubeEnv('MySonarServer') {
                    sh """
                        mvn sonar:sonar \
                        -Dsonar.projectKey=nodejs-web-app \
                        -Dsonar.sources=. \
                        -Dsonar.exclusions=node_modules/**,terraform/**,ansible/** \
                        -Dsonar.host.url=${SONAR_HOST_URL} \
                        -Dsonar.login=${SONAR_TOKEN}
                    """
                }
            }
        }

        stage("Quality Gate") {
            steps {
                // Pipeline sẽ dừng nếu SonarQube chấm "Fail"
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

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
                sh "kubectl --kubeconfig=$KUBECONFIG --insecure-skip-tls-verify apply -f k8s/deployment.yaml"
                // Thêm lệnh để restart deployment, đảm bảo K8s kéo image mới nhất
                sh "kubectl --kubeconfig=$KUBECONFIG --insecure-skip-tls-verify rollout restart deployment nodejs-web-app"
            }
        }
    }
}
