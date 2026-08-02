@echo off
REM Terminal 2 of 2. Serves the web app; run watch.bat in the other terminal first.
REM `dart run webdev` rather than a globally activated `webdev`, so that webdev and the
REM build_daemon it talks to both come from this project's pubspec.lock -- see issue #1104.
echo serve.bat: serving the web app with webdev; watch below for the URL to open.
echo            This is terminal 2 of 2 -- run watch.bat in the other terminal first.
echo.
dart run webdev serve
