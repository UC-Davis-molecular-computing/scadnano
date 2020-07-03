import scadnano as sc

def main():
    return sc.DNADesign(strands=[], grid=sc.square)

if not sc.in_browser() and __name__ == '__main__':
    design = main()
    design.write_scadnano_file(directory='output_designs')
