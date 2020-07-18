import scadnano as sc


def main():
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
    design = sc.DNADesign(helices=helices, strands=[
        sc.Strand([sc.Domain(0, True, 0, length)]),
        sc.Strand([sc.Domain(1, True, 8, length)]),
        sc.Strand([sc.Domain(2, True, 0, length)]),
        sc.Strand([sc.Domain(3, True, 8, length)]),
    ], grid=sc.Grid.none)

    return design


if not sc.in_browser() and __name__ == '__main__':
    design = main()
    design.write_scadnano_file(directory='output_designs')
