import scadnano as sc


def create_design():
    include_rot = False
    include_rot = True
    n = 'north'
    e = 'east'
    s = 'south'
    w = 'west'
    helices = [
        sc.Helix(max_offset=20, group=n, grid_position=(0, 0)),  # 0
        sc.Helix(max_offset=21, group=n, grid_position=(1, 0)),  # 1
        sc.Helix(max_offset=19, group=n, grid_position=(1, 1)),  # 2
        sc.Helix(max_offset=18, group=n, grid_position=(0, 1)),  # 3
        sc.Helix(max_offset=17, group=n, grid_position=(-1, 1)),  # 4
        sc.Helix(max_offset=16, group=n, grid_position=(-1, 0)),  # 5
        sc.Helix(max_offset=24, group=s),  # 6
        sc.Helix(max_offset=25, group=s),  # 7
        sc.Helix(max_offset=26, group=w, position=sc.Position3D(x=0, y=0, z=0)),  # 8
        sc.Helix(max_offset=27, group=w, position=sc.Position3D(x=0, y=3, z=0)),  # 9
    ]
    if include_rot:
        helices.extend([
            sc.Helix(max_offset=26, group='r', grid_position=(0, 0)),  # 10
            sc.Helix(max_offset=27, group='r', grid_position=(0, 1)),  # 11
        ])
    helices.extend([
        sc.Helix(idx=13, max_offset=22, group=e),  # 13
        sc.Helix(idx=15, max_offset=23, group=e),  # 15
    ])

    group_north = sc.HelixGroup(position=sc.Position3D(x=0, y=-10, z=0), grid=sc.honeycomb)
    group_south = sc.HelixGroup(position=sc.Position3D(x=0, y=10, z=0), helices_view_order=[7, 6],
                                grid=sc.square)
    group_east = sc.HelixGroup(position=sc.Position3D(x=10, y=0, z=0), grid=sc.square)
    group_west = sc.HelixGroup(position=sc.Position3D(x=-10, y=0, z=0), grid=sc.Grid.none)
    groups = {
        n: group_north,
        e: group_east,
        s: group_south,
        w: group_west,
    }

    if include_rot:
        group_rot = sc.HelixGroup(position=sc.Position3D(x=10, y=10, z=0), pitch=45, grid=sc.square)
        groups['r'] = group_rot

    design = sc.Design(helices=helices, groups=groups, strands=[])

    design.strand(0, 0).to(8) \
        .cross(1).to(0) \
        .cross(2).to(8) \
        .cross(3).to(0) \
        .cross(4).to(8) \
        .cross(5).to(0)

    design.strand(4, 10).to(13)

    design.strand(6, 0).to(8).cross(7).to(0)
    design.strand(8, 0).to(8).cross(9).to(0)
    design.strand(13, 0).to(8).cross(15).to(0)

    design.strand(8, 8).to(11)
    design.strand(13, 8).to(11)


    if include_rot:
        design.strand(10, 0).to(8).cross(11).to(0)

    return design


if __name__ == '__main__':
    design = create_design()
    design.write_scadnano_file(directory='output_designs')
