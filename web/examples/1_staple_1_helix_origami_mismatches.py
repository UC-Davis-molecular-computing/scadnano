import scadnano as sc


def main():
    length = 10
    stap_ss = sc.Substrand(0, sc.forward, 0, length)
    scaf_ss = sc.Substrand(0, sc.reverse, 0, length)
    stap = sc.Strand([stap_ss])
    scaf = sc.Strand([scaf_ss], color=sc.default_scaffold_color)
    strands = [stap, scaf]
    design = sc.DNADesign(strands=strands, grid=sc.square)
    insertion_length = 4
    design.add_insertion(helix=0, offset=2, length=insertion_length)
    design.add_insertion(helix=0, offset=8, length=insertion_length)
    scaf.set_dna_sequence('AG' + 'A' * (length + 2*insertion_length - 2))
    stap.set_dna_sequence('ATTCTCTTGCTTTTTTCA')

    return design


if not sc.in_browser() and __name__ == '__main__':
    design = main()
    design.write_scadnano_file(directory='output_designs')
