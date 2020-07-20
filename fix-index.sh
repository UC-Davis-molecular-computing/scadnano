# GitHub Desktop sometimes cannot write the .git/index file.
# Copying it, deleting the original, and moving the copy back fixes it.
cp .git/index .git/index-copy
rm .git/index
mv .git/index-copy .git/index
# go to sleep for 2 seconds to let Dropbox sync, which seems to help
sleep 2
