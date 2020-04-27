rem from master branch, do this

git pull --all                 rem Fetch changes before committing
pub.bat get                    rem might not be needed
pub global activate peanut     rem might not be needed
peanut.bat
git push origin --set-upstream gh-pages
