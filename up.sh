source ./define_root_dir.sh

UP_DIR="$ROOT_DIR/"

echo uploading to $UP_DIR

scp build/* "$UP_DIR"
scp build/examples/*.py $UP_DIR
scp build/examples/output_designs/*.dna $UP_DIR
scp build/external-libs/* $UP_DIR
scp build/images/* $UP_DIR

#scp build/README.html doty@set.cs.ucdavis.edu:public_html/scadnano/
