import scadnano as sc

def create_design():
    width = 6
    width_h = width // 2
    stap_left_ss1 = sc.Domain(1, True, 0, width_h)
    stap_left_ss0 = sc.Domain(0, False, 0, width_h)
    stap_right_ss0 = sc.Domain(0, False, width_h, width)
    stap_right_ss1 = sc.Domain(1, True, width_h, width)
    scaf_ss1_left = sc.Domain(1, False, 0, width_h)
    scaf_ss0 = sc.Domain(0, True, 0, width)
    scaf_ss1_right = sc.Domain(1, False, width_h, width)
    stap_left = sc.Strand([stap_left_ss1, stap_left_ss0])
    stap_right = sc.Strand([stap_right_ss0, stap_right_ss1])
    scaf = sc.Strand([scaf_ss1_left, scaf_ss0, scaf_ss1_right], color=sc.default_scaffold_color)
    strands = [stap_left, stap_right, scaf]
    design = sc.Design(strands=strands, grid=sc.square)
    design.add_deletion(helix=0, offset=1)
    design.add_deletion(helix=0, offset=4)
    design.add_deletion(helix=1, offset=1)
    design.add_deletion(helix=1, offset=4)
    design.assign_dna(scaf, 'AACATCGT')

    return design


if __name__ == '__main__':
    design = create_design()
    design.write_scadnano_file(directory='output_designs')
