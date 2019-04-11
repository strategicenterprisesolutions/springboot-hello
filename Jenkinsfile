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
              	DOCKERHOST = """${data.hosting."${BRANCH}".dockerHost}"""
            	  DOCKERPORT = """${data.hosting."${BRANCH}".dockerPort}"""
            	  HOSTPORT = """${data.hosting."${BRANCH}".hostPort}"""
            	  DOCKERREPO = "docker.olb.cloud"
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
            }
          }
    }
      
		stage('Maven build'){
          steps{
                         sh '/maven/apache-maven-3.3.9/bin/mvn clean package -Dmaven.test.skip=true'
          }
    }
      
    stage('Build docker image'){
          steps{
            script{
          			sh "sed -i s/#DOCKERPORT#/${DOCKERPORT}/g Dockerfile"
                    withDockerRegistry([credentialsId: 'dockerpwd', url: "https://docker.olb.cloud/"]) {
                      TAG="docker.artifactory/${ORG}/${JOB_BASE_NAME}:${BUILD_ID}"
                      def image = docker.build("${TAG}", "--no-cache -f Dockerfile .")
                        stage('Push docker image'){
                            image.push "${BUILD_ID}"
                        }
                    }
            }
          }
    }
  
  	stage('Deploy docker image'){          
          steps{
            script{
              println "ENV: ${JOBENV}"
        			withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'dockerpwd', usernameVariable: '_DOCKERUSER', passwordVariable: '_DOCKERPWD']]) {
						sh """
                        		ssh centos@${DOCKERHOST} "docker login -u $_DOCKERUSER -p $_DOCKERPWD ${DOCKERREPO} && docker pull ${DOCKERREPO}/${ORG}/${JOB_BASE_NAME}:${BUILD_ID}"
                                ssh centos@${DOCKERHOST} "docker stop ${JOB_BASE_NAME} || true && docker rm ${JOB_BASE_NAME} || true"                               
                                ssh centos@${DOCKERHOST} "docker run -d --name ${JOB_BASE_NAME} --restart always --network=${NET} -p ${HOSTPORT}:${DOCKERPORT} ${DOCKERREPO}/${ORG}/${JOB_BASE_NAME}:${BUILD_ID}"
                                ssh centos@${DOCKERHOST} "docker rmi ${DOCKERREPO}/${ORG}/${JOB_BASE_NAME}:${OLDBUILD} || true"
 						"""
                    }
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
