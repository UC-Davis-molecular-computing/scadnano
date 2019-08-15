import scadnano as sc

def main():
    # make 30 helices with 5000 bases each
    helices = []
    for i in range(30):
        helices.append(sc.Helix(i, 5000))
    design = sc.DNADesign(helices=helices, strands=[], grid=sc.square)
    design.write_to_file("output_designs/many-helices.dna")

if __name__ == "__main__":
    main()