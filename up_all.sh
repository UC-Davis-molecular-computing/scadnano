source ./define_root_dir.sh

UP_DIR="$ROOT_DIR/"

echo uploading ALL to $UP_DIR
echo This can take a long time.

scp -r build/* $UP_DIR
