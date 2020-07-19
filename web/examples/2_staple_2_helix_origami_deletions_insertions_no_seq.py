import scadnano as sc


# If running in scadnano, define a function called main() that returns design.
# It will be displayed in the browser by scadnano.
def create_design():
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

    # whole design
    design = sc.Design(strands=[scaf, stap_left, stap_right], grid=sc.square)

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
    
    return design


# If running from the command line, call main() manually and write design to .dna file.
if not sc.in_browser() and __name__ == '__main__':
    design = create_design()
    design.write_scadnano_file(directory='output_designs')
