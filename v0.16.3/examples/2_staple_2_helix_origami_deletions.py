import scadnano as sc


def create_design():
    stap_left_ss1 = sc.Domain(1, True, 0, 16)
    stap_left_ss0 = sc.Domain(0, False, 0, 16)
    stap_right_ss0 = sc.Domain(0, False, 16, 32)
    stap_right_ss1 = sc.Domain(1, True, 16, 32)
    scaf_ss1_left = sc.Domain(1, False, 0, 16)
    scaf_ss0 = sc.Domain(0, True, 0, 32)
    scaf_ss1_right = sc.Domain(1, False, 16, 32)
    stap_left = sc.Strand([stap_left_ss1, stap_left_ss0])
    stap_right = sc.Strand([stap_right_ss0, stap_right_ss1])
    scaf = sc.Strand([scaf_ss1_left, scaf_ss0, scaf_ss1_right], color=sc.default_scaffold_color)
    strands = [stap_left, stap_right, scaf]
    design = sc.Design(strands=strands, grid=sc.square)
    design.add_deletion(helix=0, offset=11)
    design.add_deletion(helix=0, offset=12)
    design.add_deletion(helix=0, offset=24)
    design.add_deletion(helix=1, offset=12)
    design.add_deletion(helix=1, offset=24)
    design.assign_dna(scaf, 'AACT' * 16)

    return design


if __name__ == '__main__':
    design = create_design()
    design.write_scadnano_file(directory='output_designs')
