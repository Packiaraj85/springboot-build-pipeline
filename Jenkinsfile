pipeline {
    agent { label 'build' }
    
    environment { 
        registry = "yesudassre/democicd" 
        registryCredential = 'dockerhub' 
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'patch-1', credentialsId: 'GitlabCred', url: 'https://gitlab.com/yesudas.sre/springboot-build-pipeline.git'
            }
        }
    
        stage('Stage I: Build') {
            environment {
                JAVA_HOME = '/usr/lib/jvm/java-8-openjdk-amd64'
                PATH = "${JAVA_HOME}/bin:${env.PATH}"
            }
            steps {
                echo "Building Jar Component..."
                sh "mvn clean package"
            }
        }

        stage('Stage II: Code Coverage') {
            environment {
                JAVA_HOME = '/usr/lib/jvm/java-8-openjdk-amd64'
                PATH = "${JAVA_HOME}/bin:${env.PATH}"
            }
            steps {
                echo "Running Code Coverage..."
                sh "mvn jacoco:report"
            }
        }

        stage('Stage III: SCA') {
            environment {
                JAVA_HOME = '/usr/lib/jvm/java-21-openjdk-amd64'
                PATH = "${JAVA_HOME}/bin:${env.PATH}"
            }
            steps {
                echo "Running Software Composition Analysis using OWASP Dependency-Check..."
                sh '''
                    # Clean up corrupted local cache if present
                    rm -rf ~/.m2/repository/org/owasp/dependency-check-data

                    # Execute Dependency-Check using the official GitHub bulk mirror
                    mvn org.owasp:dependency-check-maven:12.1.0:check \
                      -DnvdDatafeedUrl="https://dependency-check.github.io/DependencyCheck_Builder/nvd_cache/nvdcve-{0}.json.gz"
                '''
            }
        }

        stage('Stage IV: SAST') {
            environment {
                JAVA_HOME = '/usr/lib/jvm/java-21-openjdk-amd64'
                PATH = "${JAVA_HOME}/bin:${env.PATH}"
            }
            steps { 
                echo "Running Static application security testing using SonarQube Scanner..."
                withSonarQubeEnv('mysonarqube') {
                    sh '''
                        mvn sonar:sonar \
                          -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml \
                          -Dsonar.dependencyCheck.jsonReportPath=target/dependency-check-report.json \
                          -Dsonar.dependencyCheck.htmlReportPath=target/dependency-check-report.html \
                          -Dsonar.projectName=wezvatech
                    '''
                }
            }
        }

        stage('Stage V: QualityGates') {
            steps { 
                echo "Running Quality Gates to verify code quality..."
                script {
                    timeout(time: 2, unit: 'MINUTES') {
                        def qg = waitForQualityGate()
                        if (qg.status != 'OK') {
                            error "Pipeline aborted due to quality gate failure: ${qg.status}"
                        }
                    }
                }
            }
        }
        
        stage('Stage VI: Build Image') {
            steps { 
                echo "Build Docker Image..."
                script {
                    docker.withRegistry('', registryCredential) { 
                        myImage = docker.build("${registry}:${BUILD_NUMBER}")
                        myImage.push()
                        myImage.push('latest')
                    }
                }
            }
        }
            
        stage('Stage VII: Scan Image') {
            steps { 
                echo "Scanning Image for Vulnerabilities..."
                sh "trivy image --scanners vuln ${registry}:latest > trivyresults.txt"
            }
        }
              
        stage('Stage VIII: Smoke Test') {
            steps { 
                echo "Smoke Testing the Image..."
                sh "docker run -d --name smokerun -p 8080:8080 ${registry}:latest"
                sh "sleep 30; ./check.sh"
                sh "docker rm --force smokerun"
            }
        }
    }

    post {
        always {
            // Optional: Publish OWASP Dependency-Check Report in Jenkins UI
            dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'
        }
    }
}