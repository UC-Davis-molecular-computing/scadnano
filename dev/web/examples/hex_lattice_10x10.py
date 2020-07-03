import scadnano as sc


def main():
    length = 16
    helices = [sc.Helix(max_offset=length, grid_position=(h, v, 0)) for v in range(10) for h in range(10)]
    design = sc.DNADesign(helices=helices, strands=[], grid=sc.hexagonal)

    return design


if not sc.in_browser() and __name__ == '__main__':
    design = main()
    design.write_scadnano_file(directory='output_designs')
