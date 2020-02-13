# from master branch, do this

#TODO: don't know how to prevent this check from printing error message to the screen in case pub isn't found
if type pub > /dev/null; then
  PUB=pub
  echo "Using pub as dart pub command"
else 
  # on Windows the pub command is called pub.bat
  PUB=pub.bat
  echo "Using pub.bat as dart pub command"
fi

if type peanut > /dev/null; then
  PEANUT=peanut
  echo "Using peanut as dart peanut command"
else 
  # on Windows the pub command is called pub.bat
  PEANUT=peanut.bat
  echo "Using peanut.bat as dart peanut command"
fi

git pull --all # Fetch changes before committing
$PUB get # might not be needed
$PEANUT
git push origin --set-upstream gh-pages
