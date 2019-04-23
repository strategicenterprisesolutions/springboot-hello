pipeline{
    agent any
    environment{
              BRANCHES = "${env.GIT_BRANCH}"
              COMMIT = "${env.GIT_COMMIT}"
    }
    stages{
      stage('Set variables'){
          steps{
            script{
                BRANCH = "${BRANCHES}".tokenize('/')[-1]
                def data = readJSON file:'metadata.json'
                def datas = readYaml file: 'metadata.yml'
                DOCKERHOST = """${data.hosting."${BRANCH}".dockerHost}"""
                DOCKERPORT = """${data.hosting."${BRANCH}".dockerPort}"""
                HOSTPORT = """${data.hosting."${BRANCH}".hostPort}"""
                CPU = """${data.hosting."${BRANCH}".cpu}"""
                MEMORY = """${data.hosting."${BRANCH}".memory}"""
                INSTANCECOUNT = """${data.hosting."${BRANCH}".instanceCount}"""
                TARGETGROUPARN = """${data.hosting."${BRANCH}".targetGroupArn}"""
                DOCKERREPO = "my.dreamflight.cloud"
                VALIDATIONURL = """${data.'application.properties'."${BRANCH}".validationURL}"""
                VALIDATIONSLEEP = """${data.'application.properties'."${BRANCH}".validationSleep}"""
                DB = """${data.'db-config.properties'."${BRANCH}".DB}"""
                DBSCHEMA = """${data."db-config.properties"."${BRANCH}".DBSCHEMA}"""
                DBUSR = """${data."db-config.properties"."${BRANCH}".DBUSR}"""
                DBPW = """${data."db-config.properties"."${BRANCH}".DBPW}"""
                DBCONNECTIONLIMIT = """${data."db-config.properties"."${BRANCH}".DBCONNECTIONLIMIT}"""
                PLAYGROUNDSERVICEURL = """${data."application.properties"."${BRANCH}".PLAYGROUNDSERVICEURL}"""
                PLATFORMSERVICEURL = """${data."application.properties"."${BRANCH}".PLATFORMSERVICEURL}"""
                USESWAGGER = """${data."application.properties"."${BRANCH}".USESWAGGER}"""
                SIGNUPAUTH = """${data."application.properties"."${BRANCH}".SIGNUPAUTH}"""
                def (NS,ENV2,JOB) = "${JOB_NAME}".tokenize( '/' )
                def (NET1,B1,B2) = "${NS}".tokenize( '.' )
                JOBENV = "${ENV2}"
                NET = "${NET1}"
                ORG = "${NET}-${JOBENV}"
                OLDBUILD = (BUILD_ID as int) - 1
                def pom = readMavenPom file: 'pom.xml'
                ARTIFACTID = "${pom.artifactId}"
                ARTIFACTVERSION = "${pom.version}"
                ARTIFACTPACKAGING = "${pom.packaging}"
                ARTIFACT = "${ARTIFACTID}-${ARTIFACTVERSION}.${ARTIFACTPACKAGING}"
                sh "sed -i s/#ARTIFACT#/${ARTIFACT}/g ./Dockerfile"
                sh "sed -i s/#DB#/${DB}/g ./src/main/resources/db-config.properties"
                sh "sed -i s/#DBSCHEMA#/${DBSCHEMA}/g ./src/main/resources/db-config.properties"
                sh "sed -i s/#DBUSR#/${DBUSR}/g ./src/main/resources/db-config.properties"
                sh "set +x && sed -i s/#DBPW#/${DBPW}/g ./src/main/resources/db-config.properties"
                sh "sed -i s/#USESWAGGER#/${USESWAGGER}/g ./src/main/resources/application.properties"
                sh "sed -i s/#SIGNUPAUTH#/${SIGNUPAUTH}/g ./src/main/resources/application.properties"
                withAWSParameterStore(credentialsId: 'awscreds', naming: 'relative', path: '/jenkins/fargate/', recursive: true, regionName: 'us-east-1') {
                    ACCOUNTID = "${ACCOUNTID}"
                    CLUSTER = "${CLUSTER}"
                    SUBNETS = "${SUBNETS}"
                    SECURITYGROUPS = "${SECURITYGROUPS}"
                }
            }
          }
    }
      
    stage('Maven build'){
          steps{
              script{
                    //sh '/maven/apache-maven-3.3.9/bin/mvn clean package -Dmaven.test.skip=true'
                    def server = Artifactory.server 'artifactory'
                    def rtMaven = Artifactory.newMavenBuild()
                    rtMaven.resolver server: server, releaseRepo: 'libs-release', snapshotRepo: 'libs-snapshot'
                    rtMaven.deployer server: server, releaseRepo: 'libs-release-local', snapshotRepo: 'libs-snapshot-local'
                    rtMaven.deployer.artifactDeploymentPatterns.addInclude("**/*.jar")
                    rtMaven.deployer.deployArtifacts = true
                    rtMaven.tool = 'maven-3.3.9'
                    rtMaven.opts = '-Xms1024m -Xmx2048m'
                    //env.JAVA_HOME = 'path to JDK'
                    def buildInfo = rtMaven.run pom: 'pom.xml', goals: 'clean package -Dmaven.test.skip=true'
                    server.publishBuildInfo buildInfo
                    def scanConfig = ['buildName': buildInfo.name, 'buildNumber': buildInfo.number, 'failBuild': false]
                    def scanResult = server.xrayScan scanConfig
                    echo scanResult as String
              }
          }
    }
        
    stage('Sonarqube code analysis'){
          steps{
          	script{
          			def scannerHome = tool 'sonarqube'
                	withSonarQubeEnv('sonarqube') {
                    	sh "${scannerHome}/bin/sonar-scanner -Dsonar.projectKey=${JOB_BASE_NAME} -Dsonar.sources='.' -Dsonar.java.binaries='.' -Dsonar.exclusions='target/**/*' -Dsonar.projectVersion=${JOBENV}.${BUILD_ID} -Dsonar.branch=${BRANCH} "
                	}
           }
         }
    }
        
    stage('Build docker image'){
          steps{
            script{
                    sh "sed -i s/#DOCKERPORT#/${DOCKERPORT}/g Dockerfile"
                    withDockerRegistry([credentialsId: 'dockerpwd', url: "http://${DOCKERREPO}/"]) {
                            TAG="${DOCKERREPO}/${BRANCH}/${JOB_BASE_NAME}:${BUILD_ID}"
                            def image = docker.build("${TAG}", "--no-cache -f Dockerfile .")
                            stage('Push docker image'){
                                image.push "${BUILD_ID}"
                            }
                    }
                sh "docker rmi ${TAG}"
            }
          }
    }
  
    stage('Construct ECS task definition'){
        steps{
            script{
                    println "ENV: ${JOBENV}"
                    wrap([$class: 'ConfigFileBuildWrapper', managedFiles: [[fileId: 'd38018d9-0e8b-440d-8f9d-478b2cf5d2e1', targetLocation: '', variable: 'TASK_DEFINITION']]]) {
                        sh "sed -i s/#JOB_BASE_NAME#/${JOB_BASE_NAME}/g ${env.TASK_DEFINITION}"
                        sh "sed -i s/#CPU#/${CPU}/g ${env.TASK_DEFINITION}"
                        sh "sed -i s/#MEMORY#/${MEMORY}/g ${env.TASK_DEFINITION}"
                        sh "sed -i s/#DOCKERPORT#/${DOCKERPORT}/g ${env.TASK_DEFINITION}"
                        sh "sed -i s/#HOSTPORT#/${DOCKERPORT}/g ${env.TASK_DEFINITION}"
                        sh "sed -i s_#DOCKERIMAGEURI#_${DOCKERREPO}/${BRANCH}/${JOB_BASE_NAME}:${BUILD_ID}_ ${env.TASK_DEFINITION}"
                        sh "sed -i s/#ACCOUNTID#/${ACCOUNTID}/g ${env.TASK_DEFINITION}"
                        sh "cp ${env.TASK_DEFINITION} fargate.json"
                    }
            }
        }
    } 

    stage ('Deploy to ECS'){
          steps{
              script{
                        sh "aws ecs register-task-definition --cli-input-json file://./fargate.json > registertask.json"
                        def registerTask = readJSON file:'registertask.json'
                        TASKREVISION = """${registerTask.taskDefinition.revision}"""
                        TASKNAME = """${registerTask.taskDefinition.family}"""
                        sh "aws ecs describe-services --cluster ${CLUSTER} --services ${TASKNAME}-service > servicestatus.json"
                        def serviceStatus = readJSON file:'servicestatus.json'
                        SERVICESTATUS = """${serviceStatus.services.status}"""
                        if ("${SERVICESTATUS}" == "ACTIVE") {
                            sh """aws ecs update-service --cluster ${CLUSTER} --service ${TASKNAME}-service --task-definition "${TASKNAME}:${TASKREVISION}" > servicedef.json"""
                        } else {  
                            sh """aws ecs create-service --cluster ${CLUSTER} --service-name ${TASKNAME}-service --task-definition "${TASKNAME}:${TASKREVISION}" --desired-count ${INSTANCECOUNT} --launch-type "FARGATE" --network-configuration "awsvpcConfiguration={subnets=[${SUBNETS}],securityGroups=[${SECURITYGROUPS}]}" --load-balancers targetGroupArn=${TARGETGROUPARN},containerName=${JOB_BASE_NAME},containerPort=${DOCKERPORT} > servicedef.json"""    
                        }
                        def serviceDef = readJSON file:'servicedef.json'
              }
          }
    }
                
    stage ('Validate endpoint'){
          steps{
            script{
              sh """sleep "${VALIDATIONSLEEP}" && curl -H "Content-Type: application/json" "${VALIDATIONURL}" """
              def connection = new URL("${VALIDATIONURL}").openConnection() as HttpURLConnection
              connection.setRequestProperty( 'User-Agent', 'groovy-2.4.4' )
              connection.setRequestProperty( 'Content-Type', 'application/json' )
              RESULT = connection.inputStream.text
                //if $RESULT
            }

          }
    }
  }
}
