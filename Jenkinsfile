pipeline {
    agent any

    environment {
        // IDs phải khớp với thông tin bạn đã tạo trong Jenkins Credentials UI
        DOCKERHUB_CREDENTIALS = credentials('Duy200506') 
        KUBECONFIG            = credentials('k8s-secret')
        SONAR_TOKEN           = credentials('sonarqube-token') 
        
        DOCKER_USER           = "khanhduy05"
        IMAGE_NAME            = "devops-project"
    }

    stages {
        stage('Install Dependencies') {
            steps {
                // Sử dụng Node.js 20 đã cài để tải thư viện
                sh "npm install"
            }
        }

        stage('Static Analysis (SonarQube)') {
            steps {
                // withSonarQubeEnv sẽ tự động nạp SONAR_HOST_URL từ cấu hình hệ thống
                withSonarQubeEnv('MySonarServer') {
                    sh """
                        npx sonarqube-scanner \
                        -Dsonar.projectKey=nodejs-web-app \
                        -Dsonar.sources=. \
                        -Dsonar.host.url=${SONAR_HOST_URL} \
                        -Dsonar.login=${SONAR_TOKEN} \
                        -Dsonar.exclusions=node_modules/**,terraform/**,ansible/**
                    """
                }
            }
        }

        stage("Quality Gate") {
            steps {
                // Đợi SonarQube phản hồi kết quả phân tích
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
                // Login và push image lên Docker Hub
                sh "echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin"
                sh "docker push $DOCKER_USER/$IMAGE_NAME:${env.BUILD_ID}"
                sh "docker push $DOCKER_USER/$IMAGE_NAME:latest"
            }
        }

        stage('Deploy to AWS K8s') {
            steps {
                // Deploy và ép K8s cập nhật image mới ngay lập tức
                sh "kubectl --kubeconfig=$KUBECONFIG --insecure-skip-tls-verify apply -f k8s/deployment.yaml"
                sh "kubectl --kubeconfig=$KUBECONFIG --insecure-skip-tls-verify rollout restart deployment nodejs-web-app"
            }
        }
    }

    post {
        always {
            // Dọn dẹp sau khi build để tránh đầy ổ cứng VM
            sh "docker logout"
            echo "Pipeline đã hoàn thành!"
        }
    }
}
