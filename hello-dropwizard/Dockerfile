FROM openjdk:8-jdk
RUN mkdir -p /usr/src/app
COPY example.yaml /usr/src/app/example.yaml
COPY /target/hello-dropwizard-1.0-SNAPSHOT.jar /usr/src/app/hello-dropwizard-1.0-SNAPSHOT.jar
WORKDIR /usr/src/app
RUN java -version
CMD ["java","-jar","hello-dropwizard-1.0-SNAPSHOT.jar","server","example.yaml"]
EXPOSE 8080-8081