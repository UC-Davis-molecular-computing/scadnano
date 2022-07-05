echo "type"
echo "  ./test.sh -h"
echo "to display options"

#TODO: don't know how to prevent this check from printing error message to the screen in case pub isn't found
if type pub > /dev/null; then
  PUB=pub
  echo "Using pub as dart pub command"
else 
  # on Windows the pub command is called pub.bat
  PUB=pub.bat
  echo "Using pub.bat as dart pub command"
fi

if [ "$1" == "--debug" ] || [ "$1" == "-d" ]; then
  if [ "$2" == "-n" ]; then
    echo "running"
    echo "    $PUB run build_runner test -- -n $3 -P debug"
    $PUB run build_runner test -- -n $3 -P debug
  else
    echo "running"
    echo "    $PUB run build_runner test -- -P debug"
    $PUB run build_runner test -- -P debug
  fi
elif [ "$1" == "--test" ] || [ "$1" == "-t" ]; then
  echo "running"
  echo "    $PUB run build_runner test -- $2"
  $PUB run build_runner test -- $2
elif [ "$1" == "-n" ]; then
  if [ "$3" == "-d" ]; then
    echo "running"
    echo "    $PUB run build_runner test -- -n $2 -P debug"
    $PUB run build_runner test -- -n $2 -P debug
  else
    echo "running"
    echo "    $PUB run build_runner test -- -n $2"
    $PUB run build_runner test -- -n $2
  fi
elif [ "$1" == "-td" ] || [ "$1" == "-dt" ]; then
  echo "running"
  echo "    $PUB run build_runner test -- $2 -P debug"
  $PUB run build_runner test -- $2 -P debug
elif [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
  echo
  echo "Usage: bash test.sh [OPTION]"
  echo "Runs build_runner tests with configurations specified in dart_test.yaml."
  echo
  echo "Note: behavior of this script is heavily reliant on the configurations"
  echo "set by dart_test.yaml. If dart_test.yaml is updated, this script may not"
  echo "run as specified."
  echo
  echo "Options:"
  echo "  -h              Displays this help message."
  echo "  -n <test_name>  Runs test with specified name only."
  echo "                  **Name must not have any spaces."
  echo "                  Currently doesn't work to combine with -d."
  echo "  -d, --debug     Runs tests on Chrome browser, so Chrome DevTools are"
  echo "                  available. Currently doesn't work to combine with -n."
  echo "  -t <filename>, --test <filename>    Runs build_runner test on <filename>."
  echo "  -td <filename>, -dt <filename>    Runs <filename> tests on Chrome browser,"
  echo "                  so Chrome DevTools are available."
else
  echo "running"
  echo "    $PUB run build_runner test"
  $PUB run build_runner test
fi
