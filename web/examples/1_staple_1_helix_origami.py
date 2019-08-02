import scadnano as sc

if __name__ == "__main__":
    length = 9
    helices = [sc.Helix(0, length)]
    stap_ss = sc.Substrand(0, sc.right, 0, length)
    scaf_ss = sc.Substrand(0, sc.left, 0, length)
    stap = sc.Strand([stap_ss])
    scaf = sc.Strand([scaf_ss], color=sc.default_scaffold_color)
    strands = [stap, scaf]
    design = sc.DNADesign(helices=helices, strands=strands, grid=sc.square)
    design.add_deletion(helix_idx=0, offset=2)
    design.assign_dna(scaf, 'AACT' * (length // 4))
    design.write_to_file("output_designs/1_staple_1_helix_origami.dna")

