# This script copies examples from the scadnano Python package to this directory.
# It deletes existing examples first, so the Python package is the "source of truth" for examples.

PYTHON_PACKAGE_ROOT=../../../scadnano-python-package/

# rm *.py
# rm output_designs/*.sc
cp $PYTHON_PACKAGE_ROOT/examples/*.py .
cp $PYTHON_PACKAGE_ROOT/examples/output_designs/*.sc output_designs/
