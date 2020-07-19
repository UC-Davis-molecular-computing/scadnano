import scadnano as sc


def create_design():
    blue = sc.Color(r=0, g=0, b=255)
    black = sc.Color(r=0, g=0, b=0)
    red = sc.Color(r=255, g=0, b=0)
    green = sc.Color(r=0, g=150, b=0)
    cols = 8
    rows = 8
    # helices = [sc.Helix(major_tick_distance=10) for _ in range(rows+1)]
    strands = []
    for col in range(cols):
        for row in range(rows):
            helix = row
            forward = row % 2 == 0
            if forward:
                offset = col * 20
                ss1 = sc.Domain(helix, forward, offset, offset + 20)
                ss2 = sc.Domain(helix + 1, forward, offset + 20, offset + 40)
            else:
                offset = col * 20
                ss2 = sc.Domain(helix, forward, offset + 10, offset + 30)
                ss1 = sc.Domain(helix + 1, forward, offset + 30, offset + 50)
            if forward:
                color = blue if col % 2 == 0 else black
            else:
                color = red if col % 2 == 0 else green
            strand = sc.Strand([ss1, ss2], color=color)
            strands.append(strand)

    # design = sc.Design(helices=helices, strands=strands, grid=sc.square)
    design = sc.Design(major_tick_distance=10, strands=strands, grid=sc.square)

    return design


if not sc.in_browser() and __name__ == '__main__':
    design = create_design()
    design.write_scadnano_file(directory='output_designs')
