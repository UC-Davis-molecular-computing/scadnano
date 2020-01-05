import scadnano as sc


# If running in scadnano, define a function called main() that returns design.
# It will be displayed in the browser by scadnano.
def main():
    helices = [sc.Helix(max_offset=64), sc.Helix(max_offset=64), sc.Helix(max_offset=64)]

    # scaffold
    scaf_ss1_left = sc.Substrand(helix=1, forward=False, start=0, end=16)
    scaf_ss0 = sc.Substrand(helix=0, forward=True, start=0, end=32)
    loopout = sc.Loopout(length=3)
    scaf_ss1_right = sc.Substrand(helix=1, forward=False, start=16, end=32)
    scaf = sc.Strand(substrands=[scaf_ss1_left, scaf_ss0, loopout, scaf_ss1_right])

    # whole design
    design = sc.DNAOrigamiDesign(helices=helices,
                                 strands=[scaf],
                                 grid=sc.square,
                                 scaffold=scaf)

    # DNA assigned to whole design so complement can be assigned to strands other than scaf
    design.assign_dna(scaf, 'AACT' * 18)

    return design


# If running from the command line, call main() manually and write design to .dna file.
if not sc.in_browser() and __name__ == '__main__':
    design = main()
    design.write_scadnano_file(directory='output_designs')
