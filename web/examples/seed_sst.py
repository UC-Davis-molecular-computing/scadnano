import scadnano as sc
from pprint import pprint
from typing import List, Dict
from collections import defaultdict

DEBUG = False

BASES_PER_COLUMN = 21
BASES_PER_EDGE_COLUMN = 16
BASES_PER_FLANK_COLUMN = 21


def create(num_helices: int, num_cols: int, assign_seq: bool = True) -> sc.DNADesign:
    if num_cols % 2 != 1:
        raise ValueError(f'num_cols must be odd but is {num_cols}')
    if num_cols < 3:
        raise ValueError(f'num_cols must be at least 3 but is {num_cols}')
    if num_helices % 2 != 0:
        raise ValueError(f'num_helices must be even but is {num_helices}')
    if num_cols * num_helices * BASES_PER_COLUMN + 2 * BASES_PER_EDGE_COLUMN > 7249:
        print(f'WARNING: you chose {num_cols} columns and {num_helices} helices, '
              f'which requires {num_cols * num_helices * BASES_PER_COLUMN} bases, '
              f'greater than the 7249 available in standard M13.')

    # allow empty "flanking" columns on each side
    num_bases_per_helix = BASES_PER_COLUMN * num_cols + 2 * BASES_PER_EDGE_COLUMN + 2 * BASES_PER_FLANK_COLUMN
    # leftmost x offset
    offset_start = BASES_PER_FLANK_COLUMN
    # rightmost x offset
    offset_end = offset_start + BASES_PER_COLUMN * num_cols + 2 * BASES_PER_EDGE_COLUMN
    offset_5p_scaffold = (offset_end - offset_start) // 2

    helices = create_helices(num_helices, num_bases_per_helix)

    scaffold = create_scaffold(offset_start=offset_start, offset_end=offset_end, offset_5p=offset_5p_scaffold,
                               num_helices=num_helices, num_cols=num_cols)

    staples = create_staples(offset_start=offset_start, offset_end=offset_end, num_helices=num_helices,
                             num_cols=num_cols)

    tiles = create_tiles(offset_start, num_cols) if not DEBUG else []

    design = sc.DNADesign(helices=helices, strands=[scaffold] + staples + tiles, grid=sc.square)

    if assign_seq:
        design.assign_dna(scaffold, sc.m13_sequence)

    return design


def create_helices(num_helices: int, num_bases_per_helix: int):
    major_ticks = [0, 11, BASES_PER_FLANK_COLUMN, BASES_PER_FLANK_COLUMN + BASES_PER_EDGE_COLUMN]
    for offset in range(major_ticks[-1] + 7,
                        num_bases_per_helix - (BASES_PER_FLANK_COLUMN + BASES_PER_EDGE_COLUMN), 7):
        major_ticks.append(offset)
    major_ticks.append(num_bases_per_helix - (BASES_PER_FLANK_COLUMN + BASES_PER_EDGE_COLUMN))
    major_ticks.append(num_bases_per_helix - BASES_PER_FLANK_COLUMN)
    major_ticks.append(num_bases_per_helix - 11)
    major_ticks.append(num_bases_per_helix)

    tile_major_ticks = multiples_of(21, 5, num_bases_per_helix) + multiples_of(21, 16, num_bases_per_helix)
    tile_helices = [sc.Helix(idx=idx, max_bases=num_bases_per_helix, major_ticks=tile_major_ticks)
                    for idx in [0, 1, num_helices + 2, num_helices + 3]]

    return [tile_helices[0], tile_helices[1]] + \
           [sc.Helix(idx=idx, max_bases=num_bases_per_helix, major_ticks=major_ticks)
            for idx in range(2, num_helices + 2)] + \
           [tile_helices[2], tile_helices[3]]


def multiples_of(mul, start, num_bases_per_helix):
    return [tick for tick in range(start, num_bases_per_helix, mul)]


def create_scaffold(offset_start: int, offset_end: int, offset_5p: int, num_helices: int,
                    num_cols: int):
    bot_substrand_left = sc.Substrand(helix=num_helices + 1, forward=False, start=offset_start,
                                      end=offset_5p)
    bot_substrand_right = sc.Substrand(helix=num_helices + 1, forward=False, start=offset_5p,
                                       end=offset_end)

    # maps helix idx to list of substrands in order from left to right on that helix
    # substrands_on_helix: Dict[int,List[sc.Substrand]] = defaultdict(list)

    substrands = [bot_substrand_left]
    substrands_on_helix = defaultdict(list)
    mid_dist_from_end = 16
    mid_dist_from_start = 26

    # first arrange substrands by helix
    # top helix
    col_start = offset_start
    last_col = num_cols // 2
    for col in range(last_col + 1):
        if col == 0:
            col_width = BASES_PER_EDGE_COLUMN + BASES_PER_COLUMN + 7
        elif col == last_col:
            col_width = BASES_PER_EDGE_COLUMN + BASES_PER_COLUMN + 14
        else:
            col_width = 2 * BASES_PER_COLUMN
        col_end = col_start + col_width
        substrands_on_helix[2].append(sc.Substrand(2, True, col_start, col_end))
        col_start = col_end

    # helix second from bottom
    col_start = offset_start
    last_col = num_cols // 2 + 1
    for col in range(last_col + 1):
        if col == 0:
            col_width = BASES_PER_EDGE_COLUMN + BASES_PER_COLUMN + 7 - mid_dist_from_end
        elif col == last_col:
            col_width = BASES_PER_EDGE_COLUMN + 9
        else:
            col_width = 2 * BASES_PER_COLUMN
        col_end = col_start + col_width
        substrands_on_helix[num_helices].append(sc.Substrand(num_helices, True, col_start, col_end))
        col_start = col_end

    # other helices
    for helix in range(3, num_helices):
        col_start = offset_start
        for col in range(num_cols // 2 + 1):

            if col == 0:
                col_end = col_start + BASES_PER_COLUMN + BASES_PER_EDGE_COLUMN + 7
                col_mid = col_end - mid_dist_from_end
            elif col == num_cols // 2:
                col_end = col_start + BASES_PER_COLUMN + BASES_PER_EDGE_COLUMN + 14
                col_mid = col_start + mid_dist_from_start
            else:
                col_end = col_start + 2 * BASES_PER_COLUMN
                col_mid = col_end - mid_dist_from_end

            substrand_left = sc.Substrand(helix, helix % 2 == 0, col_start, col_mid)
            substrands_on_helix[helix].append(substrand_left)
            substrand_right = sc.Substrand(helix, helix % 2 == 0, col_mid, col_end)
            substrands_on_helix[helix].append(substrand_right)
            col_start = col_end

    # put in reverse order for efficient popping from stack
    for helix in range(2, num_helices + 1):
        substrands_on_helix[helix].reverse()

    # now go in order of columns, within column by helix,
    # and pop substrands from stack associated to each helix
    for dual_col in range(num_cols // 2 + 1):

        # zig-zag up from bottom
        for helix in range(num_helices, 1, -1):
            substrand = substrands_on_helix[helix].pop()
            substrands.append(substrand)

        # zig-zag down from top
        for helix in range(3, num_helices):
            substrand = substrands_on_helix[helix].pop()
            substrands.append(substrand)

    substrands.append(substrands_on_helix[num_helices].pop())

    substrands.append(bot_substrand_right)
    return sc.Strand(substrands=substrands, color=sc.default_scaffold_color)


def create_staples(offset_start, offset_end, num_helices, num_cols):
    left_edge_staples = create_left_edge_staples(offset_start, num_helices)
    right_edge_staples = create_right_edge_staples(offset_end, num_helices)
    top_staples = create_top_staples(offset_start, num_cols)
    bot_staples = create_bottom_staples(offset_start, num_cols, num_helices)
    inner_staples = create_inner_staples(offset_start, num_helices, num_cols)
    # return left_edge_staples + right_edge_staples + top_staples + bot_staples + inner_staples
    if DEBUG:
        return top_staples + bot_staples + inner_staples
        # return left_edge_staples + right_edge_staples + top_staples + bot_staples + inner_staples
    else:
        return top_staples + \
           left_edge_staples + \
           right_edge_staples + \
           bot_staples + \
           inner_staples


def create_left_edge_staples(offset_start, num_helices):
    staples = []
    crossover_right = offset_start + BASES_PER_EDGE_COLUMN
    for helix in range(2, num_helices + 1, 2):
        ss_5p_bot = sc.Substrand(helix + 1, True, offset_start - 10, crossover_right)
        ss_3p_top = sc.Substrand(helix, False, offset_start - 10, crossover_right)
        staple = sc.Strand(substrands=[ss_5p_bot, ss_3p_top])
        staples.append(staple)
    return staples


def create_right_edge_staples(offset_end, num_helices):
    staples = []
    crossover_left = offset_end - BASES_PER_EDGE_COLUMN
    for helix in range(2, num_helices + 1, 2):
        ss_5p_bot = sc.Substrand(helix + 1, True, crossover_left, offset_end + 10)
        ss_3p_top = sc.Substrand(helix, False, crossover_left, offset_end + 10)
        staple = sc.Strand(substrands=[ss_3p_top, ss_5p_bot])
        staples.append(staple)
    return staples


def create_inner_staples(offset_start, num_helices, num_cols):
    staples = []
    for col in range(num_cols):
        x_l = offset_start + BASES_PER_EDGE_COLUMN + BASES_PER_COLUMN * col
        x_r = offset_start + BASES_PER_EDGE_COLUMN + BASES_PER_COLUMN * (col + 1)
        for helix in range(4, num_helices - 1, 2):
            nick_delta = 10 if helix == 2 else 15
            x_nick = x_l + nick_delta

            ss_helix_i_left = sc.Substrand(helix, False, x_l, x_nick)
            ss_helix_i_right = sc.Substrand(helix, False, x_nick, x_r)
            ss_helix_ip1 = sc.Substrand(helix + 1, True, x_l, x_r)
            staple = sc.Strand(substrands=[ss_helix_i_left, ss_helix_ip1, ss_helix_i_right])
            staples.append(staple)

    return staples


def create_top_staples(offset_start, num_cols):
    staples = []
    for col in range(num_cols):
        x_l = offset_start + BASES_PER_EDGE_COLUMN + BASES_PER_COLUMN * col
        x_r = offset_start + BASES_PER_EDGE_COLUMN + BASES_PER_COLUMN * (col + 1)
        nick_delta = 10
        x_nick = x_l + nick_delta

        # ss_helix_1_left = sc.Substrand(1, True, x_l, x_nick)
        ss_helix_2_left = sc.Substrand(2, False, x_l, x_nick)
        ss_helix_2_right = sc.Substrand(2, False, x_nick, x_r)
        ss_helix_3 = sc.Substrand(3, True, x_l, x_r)
        ss_helix_1_right = sc.Substrand(1, True, x_nick, x_nick + BASES_PER_COLUMN)
        staple = sc.Strand(substrands=[  # ss_helix_1_left,
            ss_helix_2_left, ss_helix_3, ss_helix_2_right,
            ss_helix_1_right])
        staples.append(staple)
    return staples


def create_top_tiles(offset_start, num_cols):
    tiles = []
    for col in range(num_cols):
        x_l = offset_start + BASES_PER_EDGE_COLUMN + BASES_PER_COLUMN * col
        x_r = offset_start + BASES_PER_EDGE_COLUMN + BASES_PER_COLUMN * (col + 1)
        nick_delta = 10
        x_nick = x_l + nick_delta

        # ss_helix_1_left = sc.Substrand(1, True, x_l, x_nick)
        ss_helix_0_left = sc.Substrand(0, True, x_l, x_nick)
        ss_helix_0_right = sc.Substrand(0, True, x_nick, x_r)
        ss_helix_1 = sc.Substrand(1, False, x_l, x_r)
        tile = sc.Strand(substrands=[ss_helix_0_right, ss_helix_1, ss_helix_0_left],
                         color=sc.Color(0, 0, 0))
        tiles.append(tile)
    return tiles


def create_bottom_staples(offset_start, num_cols, num_helices):
    return []


def create_bottom_tiles(offset_start, num_cols):
    return []


def create_tiles(offset_start, num_cols):
    top_tiles = create_top_tiles(offset_start, num_cols)
    bottom_tiles = create_bottom_tiles(offset_start, num_cols)
    return top_tiles + bottom_tiles



def main():
    design = create(num_helices=24, num_cols=13) if not DEBUG else create(num_helices=4, num_cols=3)

    return design


if not sc.in_browser() and __name__ == '__main__':
    design = main()
    design.write_scadnano_file(directory='output_designs')
