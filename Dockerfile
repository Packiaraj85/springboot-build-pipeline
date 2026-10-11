FROM openjdk:14-ea-8-jdk-alpine
WORKDIR /opt/app
COPY target/MessageUtil-1.0.jar app.jar
ENTRYPOINT ["java","-jar","app.jar"]