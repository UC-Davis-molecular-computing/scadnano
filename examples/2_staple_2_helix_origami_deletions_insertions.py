import scadnano as sc


def main():
    # helices
    helices = [sc.Helix(max_offset=48), sc.Helix(max_offset=48)]

    # left staple
    stap_left_ss1 = sc.Substrand(helix=1, forward=True, start=8, end=24)
    stap_left_ss0 = sc.Substrand(helix=0, forward=False, start=8, end=24)
    stap_left = sc.Strand(substrands=[stap_left_ss1, stap_left_ss0])

    # right staple
    stap_right_ss0 = sc.Substrand(helix=0, forward=False, start=24, end=40)
    stap_right_ss1 = sc.Substrand(helix=1, forward=True, start=24, end=40)
    stap_right = sc.Strand(substrands=[stap_right_ss0, stap_right_ss1])

    # scaffold
    scaf_ss1_left = sc.Substrand(helix=1, forward=False, start=8, end=24)
    scaf_ss0 = sc.Substrand(helix=0, forward=True, start=8, end=40)
    loopout = sc.Loopout(length=3)
    scaf_ss1_right = sc.Substrand(helix=1, forward=False, start=24, end=40)
    scaf = sc.Strand(substrands=[scaf_ss1_left, scaf_ss0, loopout, scaf_ss1_right])

    # whole design
    design = sc.DNAOrigamiDesign(helices=helices, strands=[scaf, stap_left, stap_right], grid=sc.square,
                                 scaffold=scaf)

    # deletions and insertions added to design are added to both strands on a helix
    design.add_deletion(helix=1, offset=20)
    design.add_insertion(helix=0, offset=14, length=1)
    design.add_insertion(helix=0, offset=26, length=2)

    # also assigns complement to strands other than scaf bound to it
    design.assign_dna(scaf, 'AACGT' * 18)

    return design


if __name__ == '__main__':
    design = main()
    design.write_scadnano_file(directory='output_designs')
