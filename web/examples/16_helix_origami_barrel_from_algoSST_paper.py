import origami_rectangle as rect
import scadnano as sc



def main():
    design = rect.create(num_helices=16, num_cols=28, seam_left_column=12, assign_seq=False,
                         num_flanking_columns=2,
                         num_flanking_helices=2, edge_staples=False,
                         scaffold_nick_offset=102)

    # # need this to match original design, but doesn't leave room for left-side adapters
    # design.move_strand_offsets(8)

    set_helix_major_tickets(design)
    move_top_and_bottom_staples_within_column_boundaries(design)
    add_substrands_for_barrel_seam(design)
    add_toeholds_for_seam_displacement(design)
    add_adapters(design)
    add_twist_correct_deletions(design)
    add_angle_inducing_insertions_deletions(design)
    add_tiles_and_assign_dna(design)
    assign_dna_to_unzipper_toeholds(design)

    design.assign_m13_to_scaffold()

    return design


def set_helix_major_tickets(design):
    major_ticks = [11, 22, 32]
    for tick in range(40, 481, 8):
        major_ticks.append(tick)
    major_ticks.extend([490, 501])

    for helix in design.helices.values():
        helix.major_ticks = list(major_ticks)


def add_twist_correct_deletions(design: sc.DNADesign):
    # I choose between 3 and 4 offset arbitrarily for twist-correction deletions for some reason,
    # so they have to be hard-coded.
    for col, offset in zip(range(4, 29, 3), [4, 3, 3, 4, 3, 3, 3, 3, 3]):
        for helix in range(2, 18):
            design.add_deletion(helix, 16 * col + offset)


def move_top_and_bottom_staples_within_column_boundaries(design: sc.DNADesign):
    top_staples = design.strands_starting_on_helix(2)
    bot_staples = design.strands_starting_on_helix(17)
    bot_staples.remove(design.scaffold)

    for top_staple in top_staples:
        current_end = top_staple.substrands[0].end
        design.set_end(top_staple.substrands[0], current_end - 8)

    for bot_staple in bot_staples:
        current_start = bot_staple.substrands[0].start
        design.set_start(bot_staple.substrands[0], current_start + 8)


def add_substrands_for_barrel_seam(design):
    top_staples_5p = design.strands_starting_on_helix(2)
    top_staples_3p = design.strands_ending_on_helix(2)
    bot_staples_5p = design.strands_starting_on_helix(17)
    bot_staples_3p = design.strands_ending_on_helix(17)

    # remove scaffold
    top_staples_5p = [st for st in top_staples_5p if len(st.substrands) <= 3]
    top_staples_3p = [st for st in top_staples_3p if len(st.substrands) <= 3]
    bot_staples_5p = [st for st in bot_staples_5p if len(st.substrands) <= 3]
    bot_staples_3p = [st for st in bot_staples_3p if len(st.substrands) <= 3]

    top_staples_5p.sort(key=lambda stap: stap.offset_5p())
    top_staples_3p.sort(key=lambda stap: stap.offset_3p())
    bot_staples_5p.sort(key=lambda stap: stap.offset_5p())
    bot_staples_3p.sort(key=lambda stap: stap.offset_3p())

    for top_5p, top_3p, bot_5p, bot_3p in zip(top_staples_5p, top_staples_3p, bot_staples_5p, bot_staples_3p):
        ss_top = sc.Substrand(helix=2, forward=False,
                              start=top_5p.first_substrand().end, end=top_3p.last_substrand().start)
        ss_bot = sc.Substrand(helix=17, forward=True,
                              start=bot_3p.last_substrand().end, end=bot_5p.first_substrand().start)
        design.insert_substrand(bot_5p, 0, ss_top)
        design.insert_substrand(top_5p, 0, ss_bot)


def add_toeholds_for_seam_displacement(design: sc.DNADesign):
    for helix in [2, 17]:
        staples_5p = design.strands_starting_on_helix(helix)

        # remove scaffold
        staples_5p = [st for st in staples_5p if len(st.substrands) <= 3]

        staples_5p.sort(key=lambda stap: stap.offset_5p())

        for stap_5p in staples_5p:
            toe_ss = sc.Substrand(helix=1 if helix == 2 else 18, forward=helix == 2,
                                  start=stap_5p.first_substrand().start, end=stap_5p.first_substrand().end)
            design.insert_substrand(stap_5p, 0, toe_ss)


def add_adapters(design):
    # left adapters
    left_inside_seed = 48
    left_outside_seed = left_inside_seed - 26
    for bot_helix in range(2, 18, 2):
        top_helix = bot_helix - 1 if bot_helix != 2 else 17
        ss_top = sc.Substrand(helix=top_helix, forward=True,
                              start=left_outside_seed, end=left_inside_seed)
        ss_bot = sc.Substrand(helix=bot_helix, forward=False,
                              start=left_outside_seed, end=left_inside_seed)
        idt = sc.IDTFields(name=f'adap-left-{top_helix}-{bot_helix}',
                           scale='25nm', purification='STD')
        adapter = sc.Strand(substrands=[ss_bot, ss_top], idt=idt)
        design.add_strand(adapter)

    # right adapters
    right_inside_seed = 464
    right_outside_seed = right_inside_seed + 26
    for bot_helix in range(2, 18, 2):
        top_helix = bot_helix - 1 if bot_helix != 2 else 17
        ss_top = sc.Substrand(helix=top_helix, forward=True,
                              start=right_inside_seed, end=right_outside_seed)
        ss_bot = sc.Substrand(helix=bot_helix, forward=False,
                              start=right_inside_seed, end=right_outside_seed)
        idt = sc.IDTFields(name=f'adap-right-{top_helix}-{bot_helix}',
                           scale='25nm', purification='STD')
        adapter = sc.Strand(substrands=[ss_top, ss_bot], idt=idt)
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


def add_tiles_and_assign_dna(design):
    # left tiles
    left_left = 11
    left_right = 32
    for top_helix, seq in zip(range(2, 18, 2), tile_dna_seqs):
        bot_helix = top_helix + 1
        ss_top = sc.Substrand(helix=top_helix, forward=True,
                              start=left_left, end=left_right)
        ss_bot = sc.Substrand(helix=bot_helix, forward=False,
                              start=left_left, end=left_right)
        tile = sc.Strand(substrands=[ss_bot, ss_top], color=sc.Color(0, 0, 0))
        design.add_strand(tile)
        design.assign_dna(tile, seq)

    # right tiles
    right_left = 480
    right_right = 501
    for top_helix, seq in zip(range(2, 18, 2), tile_dna_seqs):
        bot_helix = top_helix + 1
        ss_top = sc.Substrand(helix=top_helix, forward=True,
                              start=right_left, end=right_right)
        ss_bot = sc.Substrand(helix=bot_helix, forward=False,
                              start=right_left, end=right_right)
        tile = sc.Strand(substrands=[ss_bot, ss_top], color=sc.Color(0, 0, 0))
        design.add_strand(tile)
        design.assign_dna(tile, seq)


def add_angle_inducing_insertions_deletions(design):
    # insertion followed by deletion
    start = 59
    end = start + (32 * 12)
    for helix in [3, 7, 9, 13, 15]:
        for offset in range(start, end, 32):
            design.add_insertion(helix, offset, 1)
            design.add_deletion(helix, offset + 16)

    # deletion followed by insertion
    for helix in [4, 6, 10, 12, 16]:
        for offset in range(start, end, 32):
            design.add_deletion(helix, offset)
            design.add_insertion(helix, offset + 16, 1)


uz_toes_wc = """ 
CACCCCAC
CTTTCCTT
TTCACTAA
ACCAACCC
TCTCTTAA
CTTTCATA
ATAATAAA
AACTCACC
ACTTAATA
CAAATCAC
ACCATCCA
TACTCTAT
ATACCTTC
TTATTCAT
ATCCACAA
ATATTTTT
CCACCTAA
CTAAATTA
ATTACCCC
CACTAACA
ACACACTT
TTTTAATC
ACATTTAA
TCCACATC
CCTACCTT
TCCCTATA
""".split()


# above is in order from right to left on helix 1, followed by left to right on helix 18

def assign_dna_to_unzipper_toeholds(design):
    uz_toes = [sc.wc(seq) for seq in uz_toes_wc]

    strands_h1 = design.strands_starting_on_helix(1)
    strands_h1.sort(key=lambda _strand: _strand.first_substrand().offset_5p())
    strands_h1.reverse()

    strands_h18 = design.strands_starting_on_helix(18)
    strands_h18.sort(key=lambda _strand: _strand.first_substrand().offset_5p())

    for strand, toe in zip(strands_h1 + strands_h18, uz_toes):
        seq = toe + sc.DNA_base_wildcard * (strand.dna_length() - 8)
        design.assign_dna(strand, seq)




if not sc.in_browser() and __name__ == '__main__':
    the_design = main()
    the_design.write_scadnano_file(directory='output_designs')
    the_design.write_idt_bulk_input_file(directory='idt')
    # the_design.write_idt_plate_excel_file(directory='idt', export_non_modified_strand_version=True)
