import scadnano as sc

def main():
    helices = []
    num_helices,max_bases = 30,2000
    # num_helices, max_bases = 20, 1000
    # num_helices, max_bases = 2, 24
    # num_helices, max_bases = 2, 11
    # num_helices, max_bases = 1, 3
    for i in range(num_helices):
        helices.append(sc.Helix(i, max_bases))
    design = sc.DNADesign(helices=helices, strands=[], grid=sc.square)
    design.write_to_file("output_designs/many-big-helices.dna")
    # design.write_to_file("output_designs/few-small-helices.dna")
    # design.write_to_file("output_designs/few-small-helices-11-bases.dna")
    # design.write_to_file("output_designs/1-helix-3-bases.dna")

if __name__ == "__main__":
    main()