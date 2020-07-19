import scadnano as sc


# If running in scadnano, define a function called main() that returns design.
# It will be displayed in the browser by scadnano.
def create_design():
    # multiple-domain
    ss0_1 = sc.Domain(helix=0, forward=False, start=0, end=4)
    ss1 = sc.Domain(helix=1, forward=True, start=0, end=8)
    ss0_2 = sc.Domain(helix=0, forward=False, start=4, end=8)
    strand_multi = sc.Strand(domains=[ss0_1, ss1, ss0_2])

    # single domain
    ss0_single = sc.Domain(helix=0, forward=True, start=0, end=8)
    strand_single = sc.Strand(domains=[ss0_single])

    # whole design
    design = sc.Design(strands=[strand_multi, strand_single], grid=sc.square)

    return design


# If running from the command line, call main() manually and write design to scadnano file.
if not sc.in_browser() and __name__ == '__main__':
    design = create_design()
    design.write_scadnano_file(directory='output_designs')
