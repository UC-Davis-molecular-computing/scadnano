import scadnano as sc


# If running in scadnano, define a function called main() that returns design.
# It will be displayed in the browser by scadnano.
def main():
    # multiple-substrand
    ss0_1 = sc.Substrand(helix=0, forward=False, start=0, end=4)
    ss1 = sc.Substrand(helix=1, forward=True, start=0, end=8)
    ss0_2 = sc.Substrand(helix=0, forward=False, start=4, end=8)
    strand_multi = sc.Strand(substrands=[ss0_1, ss1, ss0_2])

    # single substrand
    ss0_single = sc.Substrand(helix=0, forward=True, start=0, end=8)
    strand_single = sc.Strand(substrands=[ss0_single])

    # whole design
    design = sc.DNADesign(strands=[strand_multi, strand_single], grid=sc.square)

    return design


# If running from the command line, call main() manually and write design to .dna file.
if not sc.in_browser() and __name__ == '__main__':
    design = main()
    design.write_scadnano_file(directory='output_designs')
