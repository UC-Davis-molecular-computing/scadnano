import scadnano as sc


# If running in scadnano, define a function called main() that returns design.
# It will be displayed in the browser by scadnano.
def main():
    helices = [sc.Helix(max_offset=64), sc.Helix(max_offset=64), sc.Helix(max_offset=64)]

    # left staple
    stap_left_ss1 = sc.Domain(helix=1, forward=True, start=0, end=16)
    stap_left_ss0 = sc.Domain(helix=0, forward=False, start=0, end=16)
    stap_left = sc.Strand(domains=[stap_left_ss1, stap_left_ss0])

    # right staple
    stap_right_ss0 = sc.Domain(helix=0, forward=False, start=16, end=32)
    stap_right_ss1 = sc.Domain(helix=1, forward=True, start=16, end=32)
    stap_right = sc.Strand(domains=[stap_right_ss0, stap_right_ss1])

    # scaffold
    scaf_ss1_left = sc.Domain(helix=1, forward=False, start=0, end=16)
    scaf_ss0 = sc.Domain(helix=0, forward=True, start=0, end=32)
    loopout = sc.Loopout(length=3)
    scaf_ss1_right = sc.Domain(helix=1, forward=False, start=16, end=32)
    scaf = sc.Strand(domains=[scaf_ss1_left, scaf_ss0, loopout, scaf_ss1_right], is_scaffold=True)

    ss_extra1 = sc.Domain(helix=1, forward=True, start=32, end=48)
    ss_extra2 = sc.Domain(helix=1, forward=True, start=48, end=64)
    ss_extra3 = sc.Domain(helix=2, forward=False, start=32, end=48)
    ss_extra1b = sc.Domain(helix=1, forward=False, start=32, end=48)
    ss_extra2b = sc.Domain(helix=1, forward=False, start=48, end=64)
    ss_extra3b = sc.Domain(helix=2, forward=True, start=32, end=48)
    ss_extra4 = sc.Domain(helix=2, forward=True, start=16, end=32)
    ss_extra5 = sc.Domain(helix=2, forward=True, start=0, end=16)
    s_extra1 = sc.Strand(domains=[ss_extra1])
    s_extra2 = sc.Strand(domains=[ss_extra2])
    s_extra3 = sc.Strand(domains=[ss_extra3])
    s_extra4 = sc.Strand(domains=[ss_extra4])
    s_extra5 = sc.Strand(domains=[ss_extra5])
    s_extra1b = sc.Strand(domains=[ss_extra1b])
    s_extra2b = sc.Strand(domains=[ss_extra2b])
    s_extra3b = sc.Strand(domains=[ss_extra3b])

    # whole design
    design = sc.DNADesign(helices=helices,
                          strands=[scaf, stap_left, stap_right, s_extra1, s_extra2, s_extra3, s_extra4,
                                   s_extra1b, s_extra2b, s_extra3b, s_extra5],
                          grid=sc.square)

    # deletions and insertions added to design so they can be added to both strands on a helix
    design.add_deletion(helix=0, offset=11)
    design.add_deletion(helix=0, offset=12)
    design.add_deletion(helix=0, offset=24)
    design.add_deletion(helix=1, offset=12)
    design.add_deletion(helix=1, offset=24)

    design.add_insertion(helix=0, offset=6, length=1)
    design.add_insertion(helix=0, offset=18, length=2)
    design.add_insertion(helix=1, offset=6, length=3)
    design.add_insertion(helix=1, offset=18, length=4)

    # DNA assigned to whole design so complement can be assigned to strands other than scaf
    design.assign_dna(scaf, 'AACT' * 18)
    design.assign_dna(s_extra1, 'AACT' * 4)
    design.assign_dna(s_extra2, 'GGTA' * 4)

    return design


# If running from the command line, call main() manually and write design to .dna file.
if not sc.in_browser() and __name__ == '__main__':
    design = main()
    design.write_scadnano_file(directory='output_designs')
