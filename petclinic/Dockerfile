FROM 842675992953.dkr.ecr.us-east-1.amazonaws.com/openjdk-slim:latest
VOLUME /tmp
ADD target/spring-petclinic-2.3.0.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java","-Djava.security.egd=file:/dev/./urandom","-jar","/app.jar"]
