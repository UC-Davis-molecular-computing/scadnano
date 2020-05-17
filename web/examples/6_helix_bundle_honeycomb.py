import scadnano as sc


def main():
    m13_rotation = 6702
    m13_variant = sc.M13Variant.p7560
    print(sc.m13(m13_rotation, m13_variant))

    design = initial_design()
    add_nicks(design)
    add_crossovers(design)
    scaffold = next(s for s in design.strands if
                    s.first_substrand().helix == 5 and not s.first_substrand().forward)
    scaffold.set_scaffold()
    design.assign_m13_to_scaffold(rotation=m13_rotation, variant=m13_variant)
    return design


def initial_design():
    max_offset = 1295
    helices = [

        # below uses cadnano honeycomb coordinates
        # https://github.com/UC-Davis-molecular-computing/scadnano-python-package/blob/master/misc/cadnano-format-specs/v2.txt
        sc.Helix(grid_position=(1, 0, 0), max_offset=max_offset),
        sc.Helix(grid_position=(0, 0, 0), max_offset=max_offset),
        sc.Helix(grid_position=(0, 1, 0), max_offset=max_offset),
        sc.Helix(grid_position=(1, 1, 0), max_offset=max_offset),
        sc.Helix(grid_position=(2, 1, 0), max_offset=max_offset),
        sc.Helix(grid_position=(2, 0, 0), max_offset=max_offset),

        # # below uses odd-q coordinates:
        # sc.Helix(grid_position=(1, -1, 0), max_offset=max_offset),
        # sc.Helix(grid_position=(0, 0, 0), max_offset=max_offset),
        # sc.Helix(grid_position=(0, 1, 0), max_offset=max_offset),
        # sc.Helix(grid_position=(1, 1, 0), max_offset=max_offset),
        # sc.Helix(grid_position=(2, 1, 0), max_offset=max_offset),
        # sc.Helix(grid_position=(2, 0, 0), max_offset=max_offset),

        # below uses even-q coordinates:
        # sc.Helix(grid_position=(1, 0, 0), max_offset=max_offset),
        # sc.Helix(grid_position=(0, 0, 0), max_offset=max_offset),
        # sc.Helix(grid_position=(0, 1, 0), max_offset=max_offset),
        # sc.Helix(grid_position=(1, 2, 0), max_offset=max_offset),
        # sc.Helix(grid_position=(2, 1, 0), max_offset=max_offset),
        # sc.Helix(grid_position=(2, 0, 0), max_offset=max_offset),

        # below uses odd-r coordinates:
        # sc.Helix(grid_position=(1, 0, 0), max_offset=max_offset),
        # sc.Helix(grid_position=(0, 1, 0), max_offset=max_offset),
        # sc.Helix(grid_position=(1, 2, 0), max_offset=max_offset),
        # sc.Helix(grid_position=(2, 2, 0), max_offset=max_offset),
        # sc.Helix(grid_position=(2, 1, 0), max_offset=max_offset),
        # sc.Helix(grid_position=(2, 0, 0), max_offset=max_offset),
    ]
    scafs = [
        sc.Strand([sc.Substrand(helix=0, forward=True, start=16, end=1276)]),
        sc.Strand([sc.Substrand(helix=1, forward=False, start=16, end=1276)]),
        sc.Strand([sc.Substrand(helix=2, forward=True, start=12, end=1272)]),
        sc.Strand([sc.Substrand(helix=3, forward=False, start=12, end=1272)]),
        sc.Strand([sc.Substrand(helix=4, forward=True, start=19, end=1279)]),
        sc.Strand([sc.Substrand(helix=5, forward=False, start=19, end=1279)]),
    ]
    staps = [
        sc.Strand([sc.Substrand(helix=0, forward=False, start=42, end=1246)]),
        sc.Strand([sc.Substrand(helix=1, forward=True, start=42, end=1246)]),
        sc.Strand([sc.Substrand(helix=2, forward=False, start=42, end=1246)]),
        sc.Strand([sc.Substrand(helix=3, forward=True, start=42, end=1246)]),
        sc.Strand([sc.Substrand(helix=4, forward=False, start=42, end=1246)]),
        sc.Strand([sc.Substrand(helix=5, forward=True, start=42, end=1246)]),
    ]
    strands = scafs + staps
    return sc.DNADesign(helices=helices, strands=strands, grid=sc.honeycomb)


def add_nicks(design: sc.DNADesign):
    design.add_nick(helix=5, offset=399, forward=False)  # scaffold
    for offset in range(56, 1246, 42):
        design.add_nick(helix=0, offset=offset, forward=False)
        design.add_nick(helix=3, offset=offset, forward=True)
    for offset in range(70, 1246, 42):
        design.add_nick(helix=1, offset=offset, forward=True)
        design.add_nick(helix=4, offset=offset, forward=False)
    for offset in range(84, 1246, 42):
        design.add_nick(helix=2, offset=offset, forward=False)
        design.add_nick(helix=5, offset=offset, forward=True)


def add_crossovers(design: sc.DNADesign):
    # staples interior
    for offset in range(84, 1246, 42):
        design.add_full_crossover(helix1=0, helix2=1, offset1=offset, forward1=False)
        design.add_full_crossover(helix1=3, helix2=4, offset1=offset, forward1=True)
    for offset in range(56, 1246, 42):
        design.add_full_crossover(helix1=1, helix2=2, offset1=offset, forward1=True)
        design.add_full_crossover(helix1=4, helix2=5, offset1=offset, forward1=False)
    for offset in range(70, 1246, 42):
        design.add_full_crossover(helix1=2, helix2=3, offset1=offset, forward1=False)
        design.add_full_crossover(helix1=5, helix2=0, offset1=offset, forward1=True)
    for offset in range(49, 1245, 42):  # extra crossovers 5 - 0 for some reason
        design.add_full_crossover(helix1=5, helix2=0, offset1=offset, forward1=True)

    # staples edges
    design.add_half_crossover(helix1=0, helix2=1, offset1=42, forward1=False)
    design.add_half_crossover(helix1=3, helix2=4, offset1=42, forward1=True)
    design.add_half_crossover(helix1=0, helix2=5, offset1=1245, forward1=False)
    design.add_half_crossover(helix1=2, helix2=3, offset1=1245, forward1=False)

    # scaffold interior
    crossovers = []
    for offset in range(58, 1250, 42):
        crossovers.append(sc.Crossover(helix1=0, helix2=1, offset1=offset, forward1=True))
    for offset in range(30, 1250, 42):
        crossovers.append(sc.Crossover(helix1=1, helix2=2, offset1=offset, forward1=False))
    for offset in range(54, 1250, 42):
        crossovers.append(sc.Crossover(helix1=2, helix2=3, offset1=offset, forward1=True))
    for offset in range(26, 1250, 42):
        crossovers.append(sc.Crossover(helix1=3, helix2=4, offset1=offset, forward1=False))

    # scaffold edges
    crossovers.append(sc.Crossover(helix1=0, helix2=1, offset1=16, forward1=True, half=True))
    crossovers.append(sc.Crossover(helix1=2, helix2=3, offset1=12, forward1=True, half=True))
    crossovers.append(sc.Crossover(helix1=4, helix2=5, offset1=19, forward1=True, half=True))
    crossovers.append(sc.Crossover(helix1=0, helix2=1, offset1=1275, forward1=True, half=True))
    crossovers.append(sc.Crossover(helix1=2, helix2=3, offset1=1271, forward1=True, half=True))
    crossovers.append(sc.Crossover(helix1=4, helix2=5, offset1=1278, forward1=True, half=True))

    design.add_crossovers(crossovers)


if not sc.in_browser() and __name__ == '__main__':
    design = main()
    design.write_scadnano_file(directory='output_designs')
