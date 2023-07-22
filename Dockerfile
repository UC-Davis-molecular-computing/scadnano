FROM dart:2.13.4
WORKDIR /scadnano
EXPOSE 8080
COPY pubspec.* ./
RUN dart pub get
RUN dart pub global activate webdev 2.5.9
CMD dart pub get && $HOME/.pub-cache/bin/webdev serve --hostname=0.0.0.0
