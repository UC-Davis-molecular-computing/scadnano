import origami_rectangle as rect
import scadnano as sc


def main():
    design = rect.create(num_helices=16, num_cols=28, seam_left_column=12, assign_seq=False,
                         num_flanking_columns=2,
                         num_flanking_helices=2, edge_staples=False)

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

    design.assign_dna(design.scaffold, sc.m13_sequence)

    return design


def set_helix_major_tickets(design):
    major_ticks = [11, 22, 32]
    for tick in range(40, 481, 8):
        major_ticks.append(tick)
    major_ticks.extend([490, 501])

    for helix in design.helices:
        helix.major_ticks = list(major_ticks)


def add_twist_correct_deletions(design: sc.DNADesign):
    # I choose between 3 and 4 offset arbitrarily for twist-correction deletions for some reason,
    # so they have to be hard-coded.
    for col, offset in zip(range(2, 28, 3), [4, 3, 3, 4, 3, 3, 3, 3, 3]):
        for helix_idx in range(2, 18):
            design.add_deletion(helix_idx, 8 + 16 * col + offset)


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
        ss_top = sc.Substrand(helix_idx=2, right=False,
                              start=top_5p.first_substrand().end, end=top_3p.last_substrand().start)
        ss_bot = sc.Substrand(helix_idx=17, right=True,
                              start=bot_3p.last_substrand().end, end=bot_5p.first_substrand().start)
        design.insert_substrand(bot_5p, 0, ss_top)
        design.insert_substrand(top_5p, 0, ss_bot)


def add_toeholds_for_seam_displacement(design: sc.DNADesign):
    for helix_idx in [2, 17]:
        staples_5p = design.strands_starting_on_helix(helix_idx)

        # remove scaffold
        staples_5p = [st for st in staples_5p if len(st.substrands) <= 3]

        staples_5p.sort(key=lambda stap: stap.offset_5p())

        for stap_5p in staples_5p:
            toe_ss = sc.Substrand(helix_idx=1 if helix_idx == 2 else 18, right=helix_idx == 2,
                                  start=stap_5p.first_substrand().start, end=stap_5p.first_substrand().end)
            design.insert_substrand(stap_5p, 0, toe_ss)


def add_adapters(design):
    # left adapters
    left_inside_seed = 48
    left_outside_seed = left_inside_seed - 26
    for bot_helix_idx in range(2, 18, 2):
        top_helix_idx = bot_helix_idx - 1 if bot_helix_idx != 2 else 17
        ss_top = sc.Substrand(helix_idx=top_helix_idx, right=True,
                              start=left_outside_seed, end=left_inside_seed)
        ss_bot = sc.Substrand(helix_idx=bot_helix_idx, right=False,
                              start=left_outside_seed, end=left_inside_seed)
        adapter = sc.Strand(substrands=[ss_bot, ss_top])
        design.add_strand(adapter)

    # right adapters
    right_inside_seed = 464
    right_outside_seed = right_inside_seed + 26
    for bot_helix_idx in range(2, 18, 2):
        top_helix_idx = bot_helix_idx - 1 if bot_helix_idx != 2 else 17
        ss_top = sc.Substrand(helix_idx=top_helix_idx, right=True,
                              start=right_inside_seed, end=right_outside_seed)
        ss_bot = sc.Substrand(helix_idx=bot_helix_idx, right=False,
                              start=right_inside_seed, end=right_outside_seed)
        adapter = sc.Strand(substrands=[ss_top, ss_bot])
        design.add_strand(adapter)


seq_lines = """T00;_;_  ACCAAGAACT TTGTCAACAAT AAACAAATCCA ATCTTTCCGT
T01;_;_  TTGTCTAGAGT TTGGGATGTT AGTTCTTGGT ATTGTTGACAA
T02;_;_  TTATCCACGT TTCCTCCTATT ACTCTAGACAA AACATCCCAA
T03;_;_  AAGGAAGTAGA TTCGAAAGGT ACGTGGATAA AATAGGAGGAA
T04;_;_  AACCTCGAAT TACCAGATTCT TCTACTTCCTT ACCTTTCGAA
T05;_;_  AGAATAGTCGT TTGTCAGTGT ATTCGAGGTT AGAATCTGGTA
T06;_;_  ATCTGCTCAT TCTGATCTCTT ACGACTATTCT ACACTGACAA
T07;_;_  AATGGATAGGT AGGTGTCTTT ATGAGCAGAT AAGAGATCAGA
T08;_;_  TCAAGTTCCA TATCCTTAGCA ACCTATCCATT AAAGACACCT
T09;_;_  AGTGATGATCT TTTAGGCTGT TGGAACTTGA TGCTAAGGATA
T10;_;_  ACCCATTCAT TTCCTGATACT AGATCATCACT ACAGCCTAAA
T11;_;_  TGCGTTAAAAT AGATGCGTAT ATGAATGGGT AGTATCAGGAA
T12;_;_  AACCTTCACA ATCGTCTCATA ATTTTAACGCA ATACGCATCT
T13;_;_  ATTCAGAGAGT TGGCATGATA TGTGAAGGTT TATGAGACGAT
T14;_;_  TACCATGCTT TTGACCAATTT ACTCTCTGAAT TATCATGCCA
T15;_;_  TGGATTTGTTT ACGGAAAGAT AAGCATGGTA AAATTGGTCAA""".split('\n')

tile_dna_seqs = [''.join(line.split()[1:]) for line in seq_lines]

def add_tiles_and_assign_dna(design):
    # left tiles
    left_left = 11
    left_right = 32
    for top_helix_idx, seq in zip(range(2, 18, 2), tile_dna_seqs):
        bot_helix_idx = top_helix_idx + 1
        ss_top = sc.Substrand(helix_idx=top_helix_idx, right=True,
                              start=left_left, end=left_right)
        ss_bot = sc.Substrand(helix_idx=bot_helix_idx, right=False,
                              start=left_left, end=left_right)
        tile = sc.Strand(substrands=[ss_bot, ss_top], color=sc.Color(0, 0, 0))
        design.add_strand(tile)
        design.assign_dna(tile, seq)

    # right tiles
    right_left = 480
    right_right = 501
    for top_helix_idx, seq in zip(range(2, 18, 2), tile_dna_seqs):
        bot_helix_idx = top_helix_idx + 1
        ss_top = sc.Substrand(helix_idx=top_helix_idx, right=True,
                              start=right_left, end=right_right)
        ss_bot = sc.Substrand(helix_idx=bot_helix_idx, right=False,
                              start=right_left, end=right_right)
        tile = sc.Strand(substrands=[ss_bot, ss_top], color=sc.Color(0, 0, 0))
        design.add_strand(tile)
        design.assign_dna(tile, seq)


def add_angle_inducing_insertions_deletions(design):
    # insertion followed by deletion
    for helix_idx in [3, 7, 9, 13, 15]:
        for offset in range(57, 434, 32):
            design.add_insertion(helix_idx, offset, 1)
            design.add_deletion(helix_idx, offset + 16)

    # deletion followed by insertion
    for helix_idx in [4, 6, 10, 12, 16]:
        for offset in range(57, 434, 32):
            design.add_deletion(helix_idx, offset)
            design.add_insertion(helix_idx, offset + 16, 1)


if not sc.in_browser() and __name__ == '__main__':
    design = main()
    design.write_file(directory='output_designs')
