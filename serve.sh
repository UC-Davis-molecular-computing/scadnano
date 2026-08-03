#!/usr/bin/env bash
# Terminal 2 of 2. Serves the web app; run ./watch.sh in the other terminal first.
# `dart run webdev` rather than a globally activated `webdev`, so that webdev and the
# build_daemon it talks to both come from this project's pubspec.lock -- see issue #1104.
echo "serve.sh: serving the web app with webdev; watch below for the URL to open."
echo "          This is terminal 2 of 2 -- run ./watch.sh in the other terminal first."
echo
dart run webdev serve
