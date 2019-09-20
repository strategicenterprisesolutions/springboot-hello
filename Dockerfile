FROM openjdk:8-jre-alpine
ADD target/	gs-rest-service-0.1.0.jar //
CMD ["java","-jar","/	gs-rest-service-0.1.0.jar"]
