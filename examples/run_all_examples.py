import os
import sys
import subprocess
import importlib
import scadnano as sc


def main():
    for filename in os.listdir("."):
        if filename.endswith(".py") and not sys.argv[0].endswith(filename):
            print(f"running {filename}")
            run(filename)


def run(filename):
    if not filename.endswith('.py'):
        print(f"  filename {filename} does not end with '.py'; skipping")
        return
    modulename = filename[:-3]
    print(f'  importing module {modulename}')
    module = importlib.import_module(modulename)
    if hasattr(module, "main"):
        print(f"  found main function in module {modulename}; running it and writing its output")
        design: sc.DNADesign = module.main()
        design.write_scadnano_file(directory='output_designs', filename=modulename + '.dna')
    else:
        print(f"  found no main function in module {modulename}; running as subprocess instead")
        try:
            retcode = subprocess.call(f"python {filename}", shell=True)
            if retcode < 0:
                print("Child was terminated by signal", -retcode, file=sys.stderr)
        except OSError as e:
            print("Execution failed:", e, file=sys.stderr)


if __name__ == "__main__":
    main()
