FROM ubuntu:latest
WORKDIR /scadnano
EXPOSE 8080
RUN apt-get update
RUN apt-get install -y apt-transport-https
RUN apt-get install -y wget gpg
RUN wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/dart.gpg
RUN echo 'deb [signed-by=/usr/share/keyrings/dart.gpg arch=amd64] https://storage.googleapis.com/download.dartlang.org/linux/debian stable main' | tee /etc/apt/sources.list.d/dart_stable.list
RUN apt-get update
RUN apt-get install -y dart=2.13.4-1
RUN apt-mark hold dart=2.13.4-1
COPY pubspec.yaml pubspec.yaml
COPY pubspec.lock pubspec.lock
RUN dart pub get
RUN dart pub global activate webdev 2.5.9
CMD dart pub get && $HOME/.pub-cache/bin/webdev serve --hostname=0.0.0.0
