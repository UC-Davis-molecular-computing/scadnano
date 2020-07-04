# GitHub Desktop sometimes cannot write the .git/index file.
# Copying it, deleting the original, and moving the copy back fixes it.
cp .git/index index-copy
rm .git/index
mv index-copy .git/index

