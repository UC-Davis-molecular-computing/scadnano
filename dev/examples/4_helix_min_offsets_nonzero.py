import scadnano as sc


def create_design():
    length = 30
    helices = [
        sc.Helix(min_offset=0, max_offset=length, grid_position=(0, 0)),
        sc.Helix(min_offset=1, max_offset=length, grid_position=(0, 1)),
        sc.Helix(min_offset=2, max_offset=length, grid_position=(0, 2)),
        sc.Helix(min_offset=3, max_offset=length, grid_position=(0, 3)),
    ]
    stap_ss = sc.Domain(0, True, 0, length - 1)
    scaf_ss = sc.Domain(0, False, 0, length - 1)
    stap = sc.Strand([stap_ss])
    scaf = sc.Strand([scaf_ss], color=sc.default_scaffold_color)
    strands = [stap, scaf]
    design = sc.Design(helices=helices, strands=strands, grid=sc.Grid.square)

    return design


if not sc.in_browser() and __name__ == '__main__':
    design = create_design()
    design.write_scadnano_file(directory='output_designs')
