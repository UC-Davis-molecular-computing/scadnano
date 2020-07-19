import scadnano as sc


def create_design():
    length = 16
    helices = [sc.Helix(max_offset=length, grid_position=(h, v))
               for v in range(-4, 6) for h in range(-4, 6)]
    design = sc.Design(helices=helices, strands=[], grid=sc.honeycomb)

    return design


if not sc.in_browser() and __name__ == '__main__':
    design = create_design()
    design.write_scadnano_file(directory='output_designs')
