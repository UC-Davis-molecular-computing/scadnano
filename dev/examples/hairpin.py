import scadnano as sc


def main():
    ss_f = sc.Domain(helix=0, forward=True, start=0, end=10)
    loop = sc.Loopout(length=5)
    ss_r = sc.Domain(helix=0, forward=False, start=0, end=10)
    hairpin = sc.Strand([ss_f, loop, ss_r])
    design = sc.DNADesign(strands=[hairpin], grid=sc.square)

    design.assign_dna(hairpin, 'AAAAACCCCCTGCAT')

    return design


if not sc.in_browser() and __name__ == '__main__':
    the_design = main()
    the_design.write_scadnano_file(directory='output_designs')
