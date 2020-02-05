# from master branch, do this

pub get # might not be needed
peanut
git checkout gh-pages
echo "scadnano.org" > CNAME
git commit -m "create CNAME"
git push
git checkout master
