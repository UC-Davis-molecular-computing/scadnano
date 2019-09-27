import scadnano as sc


def main():
    helices = [sc.Helix(max_bases=9, major_ticks=[2, 5])]
    potential_helices = [sc.PotentialHelix(grid_position=(x, y, 0))
                         for x in range(-1, 2)
                         for y in range(-1, 2)
                         if not (x == 0 and y == 0)]

    stap_ss = sc.Substrand(0, sc.forward, 0, 9)
    scaf_ss = sc.Substrand(0, sc.reverse, 0, 9)
    stap = sc.Strand([stap_ss])
    scaf = sc.Strand([scaf_ss], color=sc.default_scaffold_color)

    design = sc.DNADesign(helices=helices, potential_helices=potential_helices, strands=[stap, scaf],
                          grid=sc.square)

    design.assign_dna(scaf, 'AACTAACTG')

    return design


if not sc.in_browser() and __name__ == '__main__':
    design = main()
    design.write_scadnano_file(directory='output_designs')
