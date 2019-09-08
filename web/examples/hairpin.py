import scadnano as sc


def main():
    ss_f = sc.Substrand(helix=0, forward=True, start=0, end=10)
    loop = sc.Loopout(loopout=5)
    ss_r = sc.Substrand(helix=0, forward=False, start=0, end=10)
    strand_forward = sc.Strand([ss_f, loop, ss_r])
    design = sc.DNADesign(strands=[strand_forward], grid=sc.square)
    design.assign_dna(strand_forward, 'AAAAACCCCCTGCAT')

    return design


if not sc.in_browser() and __name__ == '__main__':
    design = main()
    design.write_scadnano_file(directory='output_designs')
