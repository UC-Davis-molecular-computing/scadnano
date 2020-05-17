rem Possible Issues:
rem Error Message:
rem Username for 'https://github.com': unhumbleben
rem Password for 'https://unhumbleben@github.com':
rem To https://github.com/UC-Davis-molecular-computing/scadnano.git
rem  ! [rejected]        gh-pages -> gh-pages (non-fast-forward)
rem error: failed to push some refs to 'https://github.com/UC-Davis-molecular-computing/scadnano.git'
rem hint: Updates were rejected because a pushed branch tip is behind its remote
rem hint: counterpart. Check out this branch and integrate the remote changes
rem hint: (e.g. 'git pull ...') before pushing again.
rem hint: See the 'Note about fast-forwards' in 'git push --help' for details.

rem Fix:
rem git branch -D gh-pages
rem git checkout gh-pages
rem -----now proceed as normal------
rem git checkout master
rem peanut -m 'message'
rem git push origin --set-upstream gh-pages


rem WARNING!! from master branch, do this

git pull --all                 rem Fetch changes before committing
pub.bat get                    rem might not be needed
pub global activate peanut     rem might not be needed
peanut.bat -m "commit message"
git push origin --set-upstream gh-pages

