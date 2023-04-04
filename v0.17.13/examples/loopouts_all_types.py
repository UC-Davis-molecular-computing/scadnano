import scadnano as sc


def create_design():
    ss_f0 = sc.Domain(helix=0, forward=True, start=0, end=8)
    hairpin0 = sc.Loopout(length=5)
    ss_r0 = sc.Domain(helix=0, forward=False, start=0, end=8)

    crossover_like_loopout = sc.Loopout(length=5)
    ss_f1 = sc.Domain(helix=1, forward=True, start=0, end=8)

    long_range_loopout = sc.Loopout(length=10)
    ss_r2 = sc.Domain(helix=2, forward=False, start=16, end=24)
    hairpin2 = sc.Loopout(length=20)
    ss_f2 = sc.Domain(helix=2, forward=True, start=16, end=32)
    hairpin2_2 = sc.Loopout(length=1)
    ss_r2_2 = sc.Domain(helix=2, forward=False, start=24, end=32)

    strand = sc.Strand(
        [ss_f0, hairpin0, ss_r0, crossover_like_loopout, ss_f1, long_range_loopout, ss_r2, hairpin2, ss_f2,
         hairpin2_2, ss_r2_2])

    design = sc.Design(strands=[strand], grid=sc.square)
    t5 = 'TTTAC'
    t10 = 'TTTACTTACG'
    t20 = 'TTTTTTTTTTACGTTGCAGG'
    design.assign_dna(strand,
                      f'ACGACGAC '
                      f'{t5} '
                      f'???????? '
                      f'{t5} '
                      f'GACGACGA '
                      f'{t10} '
                      f'CACGACGA '
                      f'{t20} '
                      f'???????? '
                      f'ACGACGAC '
                      f'T')

    return design


if __name__ == '__main__':
    design = create_design()
    design.write_scadnano_file(directory='output_designs')
