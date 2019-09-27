import scadnano as sc

# If running in scadnano, define a function called main() that returns design.
# It will be displayed in the browser by scadnano.
def main():

    # left staple
    stap_left_ss1 = sc.Substrand(helix=1, forward=True,  start=0, end=16)
    stap_left_ss0 = sc.Substrand(helix=0, forward=False, start=0, end=16)
    stap_left = sc.Strand(substrands=[stap_left_ss1, stap_left_ss0])
    
    # right staple
    stap_right_ss0 = sc.Substrand(helix=0, forward=False, start=16, end=32)
    stap_right_ss1 = sc.Substrand(helix=1, forward=True,  start=16, end=32)
    stap_right = sc.Strand(substrands=[stap_right_ss0, stap_right_ss1])
    
    # scaffold
    scaf_ss1_left  = sc.Substrand(helix=1, forward=False, start=0, end=16)
    scaf_ss0       = sc.Substrand(helix=0, forward=True,  start=0, end=32)
    scaf_ss1_right = sc.Substrand(helix=1, forward=False, start=16, end=32)
    scaf = sc.Strand(substrands=[scaf_ss1_left, scaf_ss0, scaf_ss1_right], color=sc.default_scaffold_color)
    
    # whole design
    design = sc.DNADesign(strands=[scaf, stap_left, stap_right], grid=sc.square)

    # deletions and insertions added to design so they can be added to both strands on a helix
    design.add_deletion(helix=0, offset=11)
    design.add_deletion(helix=0, offset=12)
    design.add_deletion(helix=0, offset=24)
    design.add_deletion(helix=1, offset=12)
    design.add_deletion(helix=1, offset=24)
    
    design.add_insertion(helix=0, offset=6,  length=1)
    design.add_insertion(helix=0, offset=18, length=2)
    design.add_insertion(helix=1, offset=6,  length=3)
    design.add_insertion(helix=1, offset=18, length=4)

    # DNA assigned to whole design so complement can be assigned to strands other than scaf
    design.assign_dna(scaf, 'AACT' * 30)

    return design

# If running from the command line, call main() manually and write design to .dna file.
if not sc.in_browser() and __name__ == '__main__':
    design = main()
    design.write_scadnano_file(directory='output_designs')
