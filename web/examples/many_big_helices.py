import scadnano as sc


def create_design():
    helices = []
    num_helices, max_bases = 30, 2000
    for _ in range(num_helices):
        helices.append(sc.Helix(max_bases))
    design = sc.Design(helices=helices, strands=[], grid=sc.square)

    return design


if not sc.in_browser() and __name__ == '__main__':
    design = create_design()
    design.write_scadnano_file(directory='output_designs')
