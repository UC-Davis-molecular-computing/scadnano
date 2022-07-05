import scadnano as sc


def create_design():
    design = precursor_scaffolds()
    add_scaffold_nicks(design)
    add_scaffold_crossovers(design)
    design.strands[0].set_scaffold()
    add_precursor_staples(design)
    add_staple_nicks(design)
    add_staple_crossovers(design)
    add_deletions(design)
    design.assign_m13_to_scaffold()
    export_idt_plate_file(design)
    return design


def export_idt_plate_file(design: sc.Design):
    for strand in design.strands:
        if strand != design.scaffold:
            strand.set_default_idt(use_default_idt=True)
    design.write_idt_plate_excel_file(use_default_plates=True)


def add_deletions(design: sc.Design):
    for helix in range(24):
        for offset in range(27, 294, 48):
            design.add_deletion(helix, offset)


def add_staple_crossovers(design: sc.Design):
    for helix in range(23):
        start_offset = 24 if helix % 2 == 0 else 40
        for offset in range(start_offset, 296, 32):
            if offset != 152:  # skip crossover near seam
                design.add_full_crossover(helix=helix, helix2=helix + 1, offset=offset,
                                          forward=helix % 2 == 1)


def add_staple_nicks(design: sc.Design):
    for helix in range(24):
        start_offset = 32 if helix % 2 == 0 else 48
        for offset in range(start_offset, 280, 32):
            design.add_nick(helix, offset, forward=helix % 2 == 1)


def add_precursor_staples(design: sc.Design):
    staples = [sc.Strand([sc.Domain(helix=helix, forward=helix % 2 == 1, start=8, end=296)])
               for helix in range(24)]
    for staple in staples:
        design.add_strand(staple)


def precursor_scaffolds() -> sc.Design:
    helices = [sc.Helix(max_offset=304) for _ in range(24)]
    scaffolds = [sc.Strand([sc.Domain(helix=helix, forward=helix % 2 == 0, start=8, end=296)])
                 for helix in range(24)]
    return sc.Design(helices=helices, strands=scaffolds, grid=sc.square)


def add_scaffold_nicks(design: sc.Design):
    for helix in range(1, 24):
        design.add_nick(helix=helix, offset=152, forward=helix % 2 == 0)


def add_scaffold_crossovers(design: sc.Design):
    crossovers = []

    # scaffold interior
    for helix in range(1, 23, 2):
        crossovers.append(sc.Crossover(helix=helix, helix2=helix + 1, offset=152, forward=False))

    # scaffold edges
    for helix in range(0, 23, 2):
        crossovers.append(sc.Crossover(helix=helix, helix2=helix + 1, offset=8, forward=True, half=True))
        crossovers.append(
            sc.Crossover(helix=helix, helix2=helix + 1, offset=295, forward=True, half=True))

    design.add_crossovers(crossovers)


if __name__ == '__main__':
    design = create_design()
    design.write_scadnano_file()
