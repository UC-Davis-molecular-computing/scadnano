source ./define_root_dir.sh

UP_DIR="$ROOT_DIR/"

echo uploading to $UP_DIR

scp build/* "$UP_DIR"
scp build/examples/*.py $UP_DIR/examples/
scp build/examples/*.sc $UP_DIR/examples/
scp build/examples/output_designs/*.sc $UP_DIR/examples/output_designs/
scp build/example_designs/*.sc $UP_DIR/example_designs/
scp build/external-libs/* $UP_DIR/external-libs/
scp build/images/* $UP_DIR/images/

#scp build/README.html doty@set.cs.ucdavis.edu:public_html/scadnano/
