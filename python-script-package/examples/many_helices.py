import scadnano as sc

if __name__ == "__main__":
    # make 30 helices with 5000 bases each
    helices = []
    for i in range(30):
        helices.append(sc.Helix(i, 5000))
    design = sc.DNADesign(helices=helices, strands=[], grid=sc.square)
    design.write_to_file("output_designs/large-helices.dna")