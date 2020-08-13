import scadnano as sc


def create_design():
    num_helices = 16
    bases = 48
    helices = [sc.Helix() for _ in range(num_helices)]
    strands = []
    for bot in range(num_helices // 2):
        top = num_helices - bot - 1
        helix_top = helices[bot]
        helix_bot = helices[top]

        stap_left_ss_top = sc.Domain(top, True, 0, bases // 3)
        stap_left_ss_bot = sc.Domain(bot, False, 0, bases // 3)
        stap_mid_ss_bot = sc.Domain(bot, False, bases // 3, bases * 2 // 3)
        stap_mid_ss_top = sc.Domain(top, True, bases // 3, bases * 2 // 3)
        stap_right_ss_top = sc.Domain(top, True, bases * 2 // 3, bases)
        stap_right_ss_bot = sc.Domain(bot, False, bases * 2 // 3, bases)
        stap_left = sc.Strand([stap_left_ss_bot, stap_left_ss_top])
        stap_mid = sc.Strand([stap_mid_ss_top, stap_mid_ss_bot])
        stap_right = sc.Strand([stap_right_ss_bot, stap_right_ss_top])
        strands.append(stap_left)
        strands.append(stap_mid)
        strands.append(stap_right)

    design = sc.Design(helices=helices, strands=strands, grid=sc.square)

    return design


if __name__ == '__main__':
    design = create_design()
    design.write_scadnano_file(directory='output_designs')
