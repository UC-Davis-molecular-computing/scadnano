import scadnano as sc

def main():
    helices = [sc.Helix(0, 32), sc.Helix(1, 32)]
    stap_left_ss1 = sc.Substrand(1, sc.right, 0, 16)
    stap_left_ss0 = sc.Substrand(0, sc.left, 0, 16)
    stap_right_ss0 = sc.Substrand(0, sc.left, 16, 32)
    stap_right_ss1 = sc.Substrand(1, sc.right, 16, 32)
    scaf_ss1_left = sc.Substrand(1, sc.left, 0, 16)
    scaf_ss0 = sc.Substrand(0, sc.right, 0, 32)
    scaf_ss1_right = sc.Substrand(1, sc.left, 16, 32)
    stap_left = sc.Strand([stap_left_ss1, stap_left_ss0])
    stap_right = sc.Strand([stap_right_ss0, stap_right_ss1])
    scaf = sc.Strand([scaf_ss1_left, scaf_ss0, scaf_ss1_right], color=sc.default_scaffold_color)
    strands = [stap_left, stap_right, scaf]
    design = sc.DNADesign(helices=helices, strands=strands, grid=sc.square)
    design.add_deletion(helix_idx=0, offset=12)
    design.add_deletion(helix_idx=0, offset=24)
    design.add_deletion(helix_idx=1, offset=12)
    design.add_deletion(helix_idx=1, offset=24)
    design.assign_dna(scaf, 'AACT'*16)
    design.write_to_file("output_designs/2_staple_2_helix_origami_deletions.dna")

if __name__ == "__main__":
    main()