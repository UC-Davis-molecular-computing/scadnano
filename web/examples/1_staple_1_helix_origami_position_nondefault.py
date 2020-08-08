import scadnano as sc


def create_design():
    length = 9
    helices = [
        sc.Helix(max_offset=length, major_ticks=[2, 5], position=sc.Position3D(x=1, y=2, z=3), pitch=90)]
    stap_ss = sc.Domain(0, True, 0, length)
    scaf_ss = sc.Domain(0, False, 0, length)
    stap = sc.Strand([stap_ss])
    scaf = sc.Strand([scaf_ss], color=sc.default_scaffold_color)
    strands = [stap, scaf]
    design = sc.Design(helices=helices, strands=strands, grid=sc.Grid.none)
    design.assign_dna(scaf, 'AACT' * (length // 4))

    return design


if __name__ == '__main__':
    design = create_design()
    design.write_scadnano_file(directory='output_designs')
