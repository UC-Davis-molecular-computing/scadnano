import scadnano as sc
import modifications as mod
import dataclasses

def main():
    NUM_HELICES = 8
    WIDTH = 16
    doms = [sc.Domain(h, h%2==0, 0,WIDTH) for h in range(NUM_HELICES)]
    strand = sc.Strand(doms)
    design = sc.DNADesign(strands=[strand], grid=sc.square)
    design.add_deletion(helix=0, offset=11)
    design.add_deletion(helix=0, offset=12)
    design.add_deletion(helix=1, offset=12)
    design.add_insertion(helix=1, offset=4, length=1)
    design.assign_dna(strand, 'T'*(NUM_HELICES*WIDTH))

    strand.set_modification_5p(mod.biotin_5p)
    strand.set_modification_3p(mod.cy3_3p)
    for h in range(NUM_HELICES):
        strand.set_modification_internal(WIDTH*h + 5, mod.cy3_int)
        strand.set_modification_internal(WIDTH*h + 10, mod.biotin_int)

    return design


if not sc.in_browser() and __name__ == '__main__':
    design = main()
    design.write_scadnano_file(directory='output_designs')
