FROM openjdk:8-jdk-alpine
COPY ./spring-music-1.0.jar spring-music-1.0.jar
CMD java -jar -Dspring.profiles.active=postgres  spring-music-1.0.jar
