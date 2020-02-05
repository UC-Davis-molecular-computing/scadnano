import scadnano as sc

def main():
    design = sc.DNADesign.from_file('24_helix_rectangle.dna')
    for helix in range(24):
        for offset in range(27, 294, 48):
            design.add_deletion(helix, offset)
    return design

if __name__ == '__main__':
    design = main()
    design.write_scadnano_file(filename='24_helix_rectangle_twist_corrected.dna')
