echo "type"
echo "  ./test.sh -h"
echo "to display options"

if [ "$1" == "--debug" ] || [ "$1" == "-d" ]; then
  if [ "$2" == "-n" ]; then
    echo "running"
    echo "    dart run build_runner test -- -n $3 -P debug"
    dart run build_runner test -- -n $3 -P debug
  else
    echo "running"
    echo "    dart run build_runner test -- -P debug"
    dart run build_runner test -- -P debug
  fi
elif [ "$1" == "--test" ] || [ "$1" == "-t" ]; then
  echo "running"
  echo "    dart run build_runner test -- $2"
  dart run build_runner test -- $2
elif [ "$1" == "-n" ]; then
  if [ "$3" == "-d" ]; then
    echo "running"
    echo "    dart run build_runner test -- -n $2 -P debug"
    dart run build_runner test -- -n $2 -P debug
  else
    echo "running"
    echo "    dart run build_runner test -- -n $2"
    dart run build_runner test -- -n $2
  fi
elif [ "$1" == "-td" ] || [ "$1" == "-dt" ]; then
  echo "running"
  echo "    dart run build_runner test -- $2 -P debug"
  dart run build_runner test -- $2 -P debug
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
  echo "    dart run build_runner test"
  dart run build_runner test
fi