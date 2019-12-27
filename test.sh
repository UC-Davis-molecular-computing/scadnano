if [ "$1" == "--debug" ] || [ "$1" == "-d" ]; then
  pub run build_runner test -- -p chrome test/reducer_test.dart --pause-after-load
else
  pub run build_runner test -- -p chrome test/reducer_test.dart
fi