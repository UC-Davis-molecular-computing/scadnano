#!/usr/bin/env bash
# Terminal 1 of 2. Watches the sub-packages and regenerates their .g.dart files on change.
# Run ./serve.sh in a second terminal to serve the web app.
echo "watch.sh: watching sub-packages, rebuilding their .g.dart files as you edit."
echo "          This is terminal 1 of 2 -- run ./serve.sh in a second terminal to serve the app."
echo
dart run melos run watch
