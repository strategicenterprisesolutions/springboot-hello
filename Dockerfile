FROM openjdk:8-jre-alpine
ADD target/#ARTIFACT# //
CMD ["java","-jar","/#ARTIFACT#"]