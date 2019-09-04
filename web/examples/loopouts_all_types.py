import scadnano as sc


def main():
    helices = [sc.Helix(idx=0), sc.Helix(idx=1), sc.Helix(idx=2)]

    ss_f0 = sc.Substrand(helix=0, forward=True, start=0, end=8)
    hairpin0 = sc.Loopout(loopout=5)
    ss_r0 = sc.Substrand(helix=0, forward=False, start=0, end=8)

    crossover_like_loopout = sc.Loopout(loopout=5)
    ss_f1 = sc.Substrand(helix=1, forward=True, start=0, end=8)

    long_range_loopout = sc.Loopout(loopout=10)
    ss_r2 = sc.Substrand(helix=2, forward=False, start=16, end=24)
    hairpin2 = sc.Loopout(loopout=20)
    ss_f2 = sc.Substrand(helix=2, forward=True, start=16, end=32)
    hairpin2_2 = sc.Loopout(loopout=1)
    ss_r2_2 = sc.Substrand(helix=2, forward=False, start=24, end=32)

    strand = sc.Strand(
        [ss_f0, hairpin0, ss_r0, crossover_like_loopout, ss_f1, long_range_loopout, ss_r2, hairpin2, ss_f2,
         hairpin2_2, ss_r2_2])

    design = sc.DNADesign(helices=helices, strands=[strand], grid=sc.square)
    t5 = 'T'*5
    t10 = 'T'*10
    t20 = 'T'*20
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
                      f'ACGACGAC')

    return design


if not sc.in_browser() and __name__ == '__main__':
    design = main()
    design.write_scadnano_file(directory='output_designs')
