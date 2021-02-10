import scadnano as sc


def create_design():
    length = 10
    stap_ss = sc.Domain(0, True, 0, length)
    scaf_ss = sc.Domain(0, False, 0, length)
    stap = sc.Strand([stap_ss])
    scaf = sc.Strand([scaf_ss], color=sc.default_scaffold_color)
    strands = [stap, scaf]
    design = sc.Design(strands=strands, grid=sc.square)
    insertion_length = 4
    design.add_insertion(helix=0, offset=2, length=insertion_length)
    design.add_insertion(helix=0, offset=8, length=insertion_length)
    scaf.set_dna_sequence('AG' + 'A' * (length + 2*insertion_length - 2))
    stap.set_dna_sequence('ATTCTCTTGCTTTTTTCA')

    return design


if __name__ == '__main__':
    design = create_design()
    design.write_scadnano_file(directory='output_designs')
