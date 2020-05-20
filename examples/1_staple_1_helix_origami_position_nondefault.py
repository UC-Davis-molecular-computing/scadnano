import scadnano as sc

def main():
    length = 9
    helices = [
        sc.Helix(max_offset=length, major_ticks=[2, 5], position3d=sc.Position3D(x=3, y=2, z=1, pitch=90))]
    stap_ss = sc.Domain(0, sc.forward, 0, length)
    scaf_ss = sc.Domain(0, sc.reverse, 0, length)
    stap = sc.Strand([stap_ss])
    scaf = sc.Strand([scaf_ss], color=sc.default_scaffold_color)
    strands = [stap, scaf]
    design = sc.DNADesign(helices=helices, strands=strands, grid=sc.square)
    design.assign_dna(scaf, 'AACT' * (length // 4))

    return design

if not sc.in_browser() and __name__ == '__main__':
    design = main()
    design.write_scadnano_file(directory='output_designs')
