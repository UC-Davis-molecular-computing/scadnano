import scadnano as sc


def create_design():
    length = 10
    helices = [
        sc.Helix(max_offset=length, position=sc.Position3D(x=2.5, y=0, z=0), pitch=0, roll=0, yaw=0),
        sc.Helix(max_offset=length, position=sc.Position3D(x=0, y=3, z=3), pitch=0, roll=0, yaw=0),
        sc.Helix(max_offset=length, position=sc.Position3D(x=0, y=-3, z=8), pitch=0, roll=0, yaw=0),
        sc.Helix(max_offset=length, position=sc.Position3D(x=0, y=1, z=11), pitch=0, roll=0, yaw=0),
    ]
    stap_ss = sc.Domain(0, True, 0, length)
    scaf_ss = sc.Domain(0, False, 0, length)
    stap = sc.Strand([stap_ss])
    scaf = sc.Strand([scaf_ss], color=sc.default_scaffold_color)
    strands = [stap, scaf]
    design = sc.Design(helices=helices, strands=strands, grid=sc.Grid.none)

    return design


if __name__ == '__main__':
    design = create_design()
    design.write_scadnano_file(directory='output_designs')
