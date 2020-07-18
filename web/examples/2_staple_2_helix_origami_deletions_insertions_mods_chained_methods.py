import scadnano as sc
import modifications as mod


def main():
    # helices
    helices = [sc.Helix(max_offset=48), sc.Helix(max_offset=48)]

    # whole design
    design = sc.DNADesign(helices=helices, strands=[], grid=sc.square)

    design.strand(1, 8).to(24).cross(0).to(8) # left staple
    design.strand(0, 40).to(24).cross(1).to(40).with_modification_5p(mod.biotin_5p) # right staple
    design.strand(1, 24).to(8).cross(0).to(40).loopout(1, 3).to(24).as_scaffold()

    # deletions and insertions added to design are added to both strands on a helix
    design.add_deletion(helix=1, offset=20)
    design.add_insertion(helix=0, offset=14, length=1)
    design.add_insertion(helix=0, offset=26, length=2)

    # also assigns complement to strands other than scaf bound to it
    design.assign_dna(design.scaffold, 'AACGT' * 18)

    return design


if __name__ == '__main__':
    design = main()
    design.write_scadnano_file(directory='output_designs')
