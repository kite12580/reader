FROM node:lts-alpine3.14 AS build-web
ADD . /app
WORKDIR /app/web
# Build web
RUN yarn && yarn build

# Build jar
FROM gradle:6.1.1-jdk8 AS build-env
ADD --chown=gradle:gradle . /app
WORKDIR /app
COPY --from=build-web /app/web/dist /app/src/main/resources/web
RUN \
    rm src/main/java/com/htmake/reader/ReaderUIApplication.kt; \
    gradle -b cli.gradle assemble --info; \
    mv ./build/libs/*.jar ./build/libs/reader.jar

FROM amazoncorretto:8u332-alpine3.14-jre
# Install base packages
RUN \
    # apk update; \
    # apk upgrade; \
    # Add CA certs tini tzdata
    apk add --no-cache ca-certificates tini tzdata; \
    update-ca-certificates; \
    # Clean APK cache
    rm -rf /var/cache/apk/*;

# FROM ibm-semeru-runtimes:open-8u332-b09-jre
# # Install base packages
# RUN \
#     apt-get update; \
#     apt-get install -y ca-certificates tini tzdata; \
#     update-ca-certificates; \
#     # Clean apt cache
#     rm -rf /var/lib/apt/lists/*

# 时区
ARG MONGO SECUREKEY
ENV TZ=Asia/Shanghai READER_APP_CACHECHAPTERCONTENT=true READER_APP_SECURE=true SPRING_PROFILES_ACTIVE=prod READER_APP_MONGOURI=$MONGO READER_APP_SECUREKEY=$SECUREKEY

#RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
#  && echo Asia/Shanghai > /etc/timdezone \
#  && dpkg-reconfigure -f noninteractive tzdata

EXPOSE 8080
ENTRYPOINT ["/sbin/tini", "--"]
# ENTRYPOINT ["/usr/bin/tini", "--"]  # open-8u332-b09-jre
# COPY --from=hengyunabc/arthas:latest /opt/arthas /opt/arthas
COPY --from=build-env /app/build/libs/reader.jar /app/bin/reader.jar
CMD ["java", "-jar", "/app/bin/reader.jar" ]
