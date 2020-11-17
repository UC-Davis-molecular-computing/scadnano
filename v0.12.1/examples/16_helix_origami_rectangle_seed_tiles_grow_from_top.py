import origami_rectangle as rect
import scadnano as sc


def create_design():
    design = rect.create(num_helices=16, num_cols=28, seam_left_column=12, assign_seq=False,
                         num_flanking_columns=2, num_flanking_helices=2, edge_staples=False,
                         scaffold_nick_offset=102, use_idt_defaults=True)

    # # need this to match original design, but doesn't leave room for left-side adapters
    # design.move_strand_offsets(8)

    set_helix_major_ticks(design)
    # move_top_and_bottom_staples_within_column_boundaries(design)
    # add_adapters(design)
    # add_twist_correct_deletions(design)
    # add_tiles_and_assign_dna(design)

    design.assign_m13_to_scaffold()

    return design


def set_helix_major_ticks(design):
    major_ticks = [11, 22, 32]
    for tick in range(40, 481, 8):
        major_ticks.append(tick)
    major_ticks.extend([490, 501])

    for helix in design.helices.values():
        helix.major_ticks = list(major_ticks)

    for _,helix in zip([0,1,2], design.helices.values()):
        ticks = [11, 22, 32, 40, 48]
        tick = 58
        offset = 11
        while tick < 481:
            ticks.append(tick)
            tick += offset
            offset = 10 if offset == 11 else 11
        helix.major_ticks = ticks


def add_twist_correct_deletions(design: sc.Design):
    # I choose between 3 and 4 offset arbitrarily for twist-correction deletions for some reason,
    # so they have to be hard-coded.
    for col, offset in zip(range(4, 29, 3), [4, 3, 3, 4, 3, 3, 3, 3, 3]):
        for helix in range(2, 18):
            design.add_deletion(helix, 16 * col + offset)


def move_top_and_bottom_staples_within_column_boundaries(design: sc.Design):
    top_staples = design.strands_starting_on_helix(2)
    bot_staples = design.strands_starting_on_helix(17)
    bot_staples.remove(design.scaffold)

    for top_staple in top_staples:
        current_end = top_staple.domains[0].end
        design.set_end(top_staple.domains[0], current_end - 8)

    for bot_staple in bot_staples:
        current_start = bot_staple.domains[0].start
        design.set_start(bot_staple.domains[0], current_start + 8)


def add_adapters(design):
    # left adapters
    left_inside_seed = 48
    left_outside_seed = left_inside_seed - 26
    for bot_helix in range(2, 18, 2):
        top_helix = bot_helix - 1 if bot_helix != 2 else 17
        ss_top = sc.Domain(helix=top_helix, forward=True,
                           start=left_outside_seed, end=left_inside_seed)
        ss_bot = sc.Domain(helix=bot_helix, forward=False,
                           start=left_outside_seed, end=left_inside_seed)
        idt = sc.IDTFields(name=f'adap-left-{top_helix}-{bot_helix}',
                           scale='25nm', purification='STD')
        adapter = sc.Strand(domains=[ss_bot, ss_top], idt=idt)
        design.add_strand(adapter)

    # right adapters
    right_inside_seed = 464
    right_outside_seed = right_inside_seed + 26
    for bot_helix in range(2, 18, 2):
        top_helix = bot_helix - 1 if bot_helix != 2 else 17
        ss_top = sc.Domain(helix=top_helix, forward=True,
                           start=right_inside_seed, end=right_outside_seed)
        ss_bot = sc.Domain(helix=bot_helix, forward=False,
                           start=right_inside_seed, end=right_outside_seed)
        idt = sc.IDTFields(name=f'adap-right-{top_helix}-{bot_helix}',
                           scale='25nm', purification='STD')
        adapter = sc.Strand(domains=[ss_top, ss_bot], idt=idt)
        design.add_strand(adapter)


seq_lines = """tile1rot0,ACCAAGAACT TTGTCAACAAT AAACAAATCCA ATCTTTCCGT,25nm,STD
tile2rot0,TTGTCTAGAGT TTGGGATGTT AGTTCTTGGT ATTGTTGACAA,25nm,STD
tile3rot0,TTATCCACGT TTCCTCCTATT ACTCTAGACAA AACATCCCAA,25nm,STD
tile4rot0,AAGGAAGTAGA TTCGAAAGGT ACGTGGATAA AATAGGAGGAA,25nm,STD
tile5rot0,AACCTCGAAT TACCAGATTCT TCTACTTCCTT ACCTTTCGAA,25nm,STD
tile6rot0,AGAATAGTCGT TTGTCAGTGT ATTCGAGGTT AGAATCTGGTA,25nm,STD
tile7rot0,ATCTGCTCAT TCTGATCTCTT ACGACTATTCT ACACTGACAA,25nm,STD
tile8rot0,AATGGATAGGT AGGTGTCTTT ATGAGCAGAT AAGAGATCAGA,25nm,STD
tile9rot0,TCAAGTTCCA TATCCTTAGCA ACCTATCCATT AAAGACACCT,25nm,STD
tile10rot0,AGTGATGATCT TTTAGGCTGT TGGAACTTGA TGCTAAGGATA,25nm,STD
tile11rot0,ACCCATTCAT TTCCTGATACT AGATCATCACT ACAGCCTAAA,25nm,STD
tile12rot0,TGCGTTAAAAT AGATGCGTAT ATGAATGGGT AGTATCAGGAA,25nm,STD
tile13rot0,AACCTTCACA ATCGTCTCATA ATTTTAACGCA ATACGCATCT,25nm,STD
tile14rot0,ATTCAGAGAGT TGGCATGATA TGTGAAGGTT TATGAGACGAT,25nm,STD
tile15rot0,TACCATGCTT TTGACCAATTT ACTCTCTGAAT TATCATGCCA,25nm,STD
tile16rot0,TGGATTTGTTT ACGGAAAGAT AAGCATGGTA AAATTGGTCAA,25nm,STD""".split('\n')

tile_dna_seqs = [''.join(line.split(',')[1]) for line_no, line in enumerate(seq_lines) if line_no % 2 == 1]


# print(tile_dna_seqs)


# def add_tiles_and_assign_dna(design):
#     # left tiles
#     left_left = 11
#     left_right = 32
#     for col, seq in zip(range(2, 18, 2), tile_dna_seqs):
#         bot_helix = top_helix + 1
#         ss_top = sc.Domain(helix=top_helix, forward=True,
#                            start=left_left, end=left_right)
#         ss_bot = sc.Domain(helix=bot_helix, forward=False,
#                            start=left_left, end=left_right)
#         tile = sc.Strand(domains=[ss_bot, ss_top], color=sc.Color(0, 0, 0))
#         design.add_strand(tile)
#         design.assign_dna(tile, seq)
#
#     # right tiles
#     right_left = 480
#     right_right = 501
#     for top_helix, seq in zip(range(2, 18, 2), tile_dna_seqs):
#         bot_helix = top_helix + 1
#         ss_top = sc.Domain(helix=top_helix, forward=True,
#                            start=right_left, end=right_right)
#         ss_bot = sc.Domain(helix=bot_helix, forward=False,
#                            start=right_left, end=right_right)
#         tile = sc.Strand(domains=[ss_bot, ss_top], color=sc.Color(0, 0, 0))
#         design.add_strand(tile)
#         design.assign_dna(tile, seq)


if __name__ == '__main__':
    design = create_design()
    design.write_scadnano_file(directory='output_designs')
    design.write_idt_bulk_input_file(directory='idt')
    design.write_idt_plate_excel_file(directory='idt', use_default_plates=True)
