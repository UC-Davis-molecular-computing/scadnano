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
# pandoc -c pandoc.css -s README.md -o web/README.html # Compile README.md to README.html
$PUB get # might not be needed
$PEANUT # use -m flag to add descriptive commit message
git push origin --set-upstream gh-pages

# Possible Issues:
#
# Error Message:
#
# Username for 'https://github.com': unhumbleben
# Password for 'https://unhumbleben@github.com':
# To https://github.com/UC-Davis-molecular-computing/scadnano.git
#  ! [rejected]        gh-pages -> gh-pages (non-fast-forward)
# error: failed to push some refs to 'https://github.com/UC-Davis-molecular-computing/scadnano.git'
# hint: Updates were rejected because a pushed branch tip is behind its remote
# hint: counterpart. Check out this branch and integrate the remote changes
# hint: (e.g. 'git pull ...') before pushing again.
# hint: See the 'Note about fast-forwards' in 'git push --help' for details.
#
#
# Fix:
# git branch -D gh-pages
# git checkout gh-pages
# -----now proceed as normal------
# git checkout master
# peanut -m 'message'
# git push origin --set-upstream gh-pages
