import scadnano as sc


def main():
    length = 16
    helices = [sc.Helix(max_offset=length, grid_position=(h, v, 0))
               for v in range(-4, 6) for h in range(-4, 6)]
    design = sc.DNADesign(helices=helices, strands=[], grid=sc.honeycomb)

    return design


if not sc.in_browser() and __name__ == '__main__':
    design = main()
    design.write_scadnano_file(directory='output_designs')
