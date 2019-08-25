import scadnano as sc


def main():
    helices = []
    num_helices, max_bases = 30, 2000
    for i in range(num_helices):
        helices.append(sc.Helix(i, max_bases))
    design = sc.DNADesign(helices=helices, strands=[], grid=sc.square)

    return design


if not sc.in_browser() and __name__ == '__main__':
    design = main()
    design.write_file(directory='output_designs')
