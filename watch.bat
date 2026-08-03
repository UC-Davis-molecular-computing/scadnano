@echo off
REM Terminal 1 of 2. Watches the sub-packages and regenerates their .g.dart files on change.
REM Run serve.bat in a second terminal to serve the web app.
echo watch.bat: watching sub-packages, rebuilding their .g.dart files as you edit.
echo            This is terminal 1 of 2 -- run serve.bat in a second terminal to serve the app.
echo.
dart run melos run watch
