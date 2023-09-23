## This Dockerfile is only used to build the web project and serve it using nginx

# Operating system and dependencies
FROM ubuntu:20.04 as build

RUN apt-get update && \
    apt-get install -y bash curl file git unzip xz-utils zip libglu1-mesa
RUN apt-get clean

RUN useradd -ms /bin/bash builder
USER builder

# download Flutter SDK from Flutter Github repo
WORKDIR /flutter
RUN git clone https://github.com/flutter/flutter.git /flutter

# Set flutter environment path
ENV PATH="/flutter/bin:/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Run flutter doctor
RUN flutter channel stable && flutter upgrade
RUN flutter precache --web
RUN flutter config --no-analytics

# Copy files to container and build
WORKDIR /app

COPY --chown=builder pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY assets/ assets/
COPY web/ web/
COPY lib/ lib/

RUN flutter pub get
RUN flutter build web --release

# Stage 2: Serve the built files using nginx
FROM nginx:alpine

COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
