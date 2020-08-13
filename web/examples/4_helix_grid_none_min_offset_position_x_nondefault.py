import scadnano as sc


def create_design():
    length = 16
    helices = [
        sc.Helix(major_tick_distance=4, max_offset=length, position=sc.Position3D(x=0, y=0, z=0),
                 min_offset=0),
        sc.Helix(major_tick_distance=4, max_offset=length, position=sc.Position3D(x=0, y=3, z=3),
                 min_offset=8),
        sc.Helix(major_tick_distance=4, max_offset=length, position=sc.Position3D(x=2.5, y=-3, z=8),
                 min_offset=0),
        sc.Helix(major_tick_distance=4, max_offset=length, position=sc.Position3D(x=2.5, y=1, z=11),
                 min_offset=8),
    ]
    design = sc.Design(helices=helices, strands=[
        sc.Strand([sc.Domain(0, True, 0, length)]),
        sc.Strand([sc.Domain(1, True, 8, length)]),
        sc.Strand([sc.Domain(2, True, 0, length)]),
        sc.Strand([sc.Domain(3, True, 8, length)]),
    ], grid=sc.Grid.none)

    return design


if __name__ == '__main__':
    design = create_design()
    design.write_scadnano_file(directory='output_designs')
