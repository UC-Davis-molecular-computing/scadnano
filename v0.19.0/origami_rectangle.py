"""
Defines function :py:func:`origami_rectangle.create` for creating a DNA origami rectangle.
"""

from dataclasses import dataclass, field

import scadnano as sc
from enum import Enum, auto


class NickPattern(Enum):
    """Represents options for where to place nicks between staples."""

    staggered = auto()
    """A nick appears in a given helix and column 
    if the parity of the helix and column match (both even or both odd)."""

    staggered_opposite = auto()
    """A nick appears in a given helix and column 
    if the parity of the helix and column don't match (one is even and the other is odd)."""

    even = auto()
    """A nick appears in every column and only even-index helices."""

    odd = auto()
    """A nick appears in every column and only odd-index helices."""


staggered = NickPattern.staggered
"""Convenience reference defined so one can type :const:`origami_rectangle.staggered` 
instead of :const:`origami_rectangle.NickPattern.staggered`."""

staggered_opposite = NickPattern.staggered_opposite
"""Convenience reference defined so one can type :const:`origami_rectangle.staggered_opposite` 
instead of :const:`origami_rectangle.NickPattern.staggered_opposite`."""

even = NickPattern.even
"""Convenience reference defined so one can type :const:`origami_rectangle.even` 
instead of :const:`origami_rectangle.NickPattern.even`."""

odd = NickPattern.odd
"""Convenience reference defined so one can type :const:`origami_rectangle.odd` 
instead of :const:`origami_rectangle.NickPattern.odd`."""


# @dataclass
# class OrigamiDNADesign(sc.DNADesign):
#     scaffold: sc.Strand = None

# TODO: figure out how to make create return a subclass that has a scaffold field

def create(*, num_helices: int, num_cols: int, assign_seq: bool = True, seam_left_column=-1,
           nick_pattern: NickPattern = NickPattern.staggered,
           twist_correction_deletion_spacing: int = 0, twist_correction_start_col: int = 1,
           twist_correction_deletion_offset=-1,
           num_flanking_columns: int = 1, num_flanking_helices=0,
           custom_scaffold: str = None, edge_staples: bool = True,
           scaffold_nick_offset: int = -1, idt: bool = False) -> sc.DNADesign:
    """
    Creates a DNA origami rectangle with a given number of helices and
    "columns" (16-base-wide region in each helix). The columns include
    the 16-base regions on the end where potential "edge staples" go,
    as well as the two-column-wide "seam" region in the middle.

    Below is an example diagram of the staples created by this function.

    Consider for example the function call
    ``origami_rectangle.create(num_helices=8, num_cols=10, nick_pattern=origami_rectangle.staggered)``.
    The scaffold strand resulting from this call is shown below:

    .. code-block:: none

          #       C0       #       C1       #       C2       #       C3       #       C4       #       C5       #       C6       #       C7       #       C8       #       C9       #
        H0 +--------------- ---------------- ---------------- ---------------- ---------------- ---------------- ---------------- ---------------- ---------------- ---------------+
           |                                                                                                                                                                       |
        H1 +--------------- ---------------- ---------------- ---------------- ---------------+ +--------------- ---------------- ---------------- ---------------- ---------------+
                                                                                              | |
        H2 +--------------- ---------------- ---------------- ---------------- ---------------+ +--------------- ---------------- ---------------- ---------------- ---------------+
           |                                                                                                                                                                       |
        H3 +--------------- ---------------- ---------------- ---------------- ---------------+ +--------------- ---------------- ---------------- ---------------- ---------------+
                                                                                              | |
        H4 +--------------- ---------------- ---------------- ---------------- ---------------+ +--------------- ---------------- ---------------- ---------------- ---------------+
           |                                                                                                                                                                       |
        H5 +--------------- ---------------- ---------------- ---------------- ---------------+ +--------------- ---------------- ---------------- ---------------- ---------------+
                                                                                              | |
        H6 +--------------- ---------------- ---------------- ---------------- ---------------+ +--------------- ---------------- ---------------- ---------------- ---------------+
           |                                                                                                                                                                       |
        H7 +--------------- ---------------- ---------------- ---------------- ---------------] <--------------- ---------------- ---------------- ---------------- ---------------+


    Helix indices are labelled ``H0``, ``H1``, ... and column indices are labeled ``C0``, ``C1``, ...
    Each single symbol ``-``, ``+``, ``<``, ``>``, ``[``, ``]``, ``+``
    represents one DNA base, so each column is 16 bases wide.
    The ``#`` is a visual delimiter between columns and does not represent any bases,
    nor do spaces between the base-representing symbols.
    The 5' end of a strand is indicated with ``[`` or ``]``
    and the 3' end is indicated with ``>`` or ``<``.
    A crossover is indicated with

    .. code-block:: none

        +
        |
        +

    Below are the staples resulting from this same call.

    .. code-block:: none

          #       C0       #       C1       #       C2       #       C3       #       C4       #       C5       #       C6       #       C7       #       C8       #       C9       #
        H0 <--------------+ +--------------- -------]<------+ +--------------- -------]<------+ +--------------- -------]<------+ +--------------- -------]<------+ +--------------]
                          | |                               | |                                                                 | |                               | |                               
        H1 [--------------+ +------>[------+ +--------------+ +------>[------+ +--------------+ +------>[------+ +--------------+ +------>[------+ +--------------+ +-------------->
                                           | |                               | |                               | |                               | |                               
        H2 <--------------+ +--------------+ +------]<------+ +--------------+ +------]<------+ +--------------+ +------]<------+ +--------------+ +------]<------+ +--------------]
                          | |                               | |                                                                 | |                               | |                               
        H3 [--------------+ +------>[------+ +--------------+ +------>[------+ +--------------+ +------>[------+ +--------------+ +------>[------+ +--------------+ +-------------->
                                           | |                               | |                               | |                               | |                               
        H4 <--------------+ +--------------+ +------]<------+ +--------------+ +------]<------+ +--------------+ +------]<------+ +--------------+ +------]<------+ +--------------]
                          | |                               | |                                                                 | |                               | |                               
        H5 [--------------+ +------>[------+ +--------------+ +------>[------+ +--------------+ +------>[------+ +--------------+ +------>[------+ +--------------+ +-------------->
                                           | |                               | |                               | |                               | |                               
        H6 <--------------+ +--------------+ +------]<------+ +--------------+ +------]<------+ +--------------+ +------]<------+ +--------------+ +------]<------+ +--------------]
                          | |                               | |                                                                 | |                               | |                               
        H7 [--------------+ +------>[------- ---------------+ +------>[------- ---------------+ +------>[------- ---------------+ +------>[------- ---------------+ +-------------->

    The seam crosses columns ``C4`` and ``C5``.
    The left and right edge staples respectively are in columns ``C0`` and ``C9``.

    Prints warning if number of bases exceeds 7249 (length of standard M13 scaffold strand),
    but does not otherwise cause an error.

    `num_cols` must be 6 plus a nonnegative multiple of 4: 6, 10, 14, 18, 22, 26, ...
    
    `seam_left_column` specifies the location of the seam. (i.e., scaffold crossovers in the middle of the
    origami.) 
    If positive, the seam occupies two columns, and `seam_left_column` specifies the column on the left.
    To make the crossover geometry work out, a nonnegative `seam_left_column` must be even,
    greater than 0, and less than `num_helices` - 2. 
    If negative, it is calculated automatically to be roughly in the middle.  

    If `twist_correction_deletion_spacing` > 0, adds deletions between crossovers in one out of
    every `twist_correction_deletion_spacing` columns. (TODO: cite Sungwook's paper)
    
    `twist_correction_start_col` is ignored if `twist_correction_deletion_spacing` <= 0, otherwise
    it indicates the column at which to put the first deletions. Default = 1.

    `num_flanking_columns` is the number of empty columns on the helix on each side of the origami.

    `num_flanking_helices` is the number of empty helices above and below the origami.

    `nick_pattern` describes whether nicks between staples should be "staggered" or not.
    See :class:`origami_rectangle.NickPattern` for details.
    
    `custom_scaffold` is the scaffold sequence to use. 
    If set to ``None``, the standard 7249-base M13 is used.
    
    `edge_staples` indicates whether to include the edge staples. (Leaving them out prevents multiple
    origami rectangles from polymerizing in solution due to base stacking interactions on the left and
    right edges of the origami rectangle.)
    
    `scaffold_nick_offset` is the position of the "nick" on the scaffold (the M13 scaffold is circular,
    so for such a scaffold this really represents where any unused and undepicted bases of the scaffold will
    form a loop-out). If negative (default value) then it will be chosen to be along the origami seam.
    
    `idt`, if ``True``, creates an :any:`VendorFields` in each staple strand suitable for
    calling :py:meth:`DNADesign.write_idt_file` or :py:meth:`DNADesign.write_idt_plate_excel_file` 

    Here's an example of using :any:`origami_rectangle.create` to create a design for a
    16-helix rectangle and write it to a file readable by scadnano.
    (By default the output file name is the same as the script calling :any:`DNADesign.write_scadnano_file`
    but with the extension ``.py`` changed to ``.dna``.)

    .. code-block:: Python

        import origami_rectangle as rect
        
        # XXX: ensure num_cols is even since we divide it by 2
        design = rect.create(num_helices=16, num_cols=24, nick_pattern=rect.staggered)
        design.write_scadnano_file()

    However, we caution that :any:`origami_rectangle.create` is not intended to be very
    extensible for creating many different types of DNA origami. It is more intended as an
    example whose source code can be an efficient reference to learn the :mod:`scadnano` API.
    """  # noqa (This line is here to suppress a PEP warning about long lines in the source code)

    if num_cols < 4:
        raise ValueError(f'num_cols must be at least 4 but is {num_cols}')
    # if num_cols % 4 != 2:
    #     raise ValueError(f'num_cols must be congruent to 2 mod 4 (6, 10, 14, 18, 22, ...) but is {num_cols}')
    if num_cols % 2 != 0:
        raise ValueError(f'num_cols must be even, but is {num_cols}')
    if num_helices % 2 != 0:
        raise ValueError(f'num_helices must be even but is {num_helices}')
    if num_cols * num_helices * BASES_PER_COLUMN > 7249:
        print(f'WARNING: you chose {num_cols} columns and {num_helices} helices, '
              f'which requires {num_cols * num_helices * BASES_PER_COLUMN} bases, '
              f'greater than the 7249 available in standard M13.')
    if seam_left_column < 0:
        seam_left_column = num_cols // 2 - 1
    if seam_left_column % 2 == 1:
        raise ValueError(f'seam_left_column must be even but is {seam_left_column}')

    # allow empty "flanking" columns on each side
    num_bases_per_helix = BASES_PER_COLUMN * (num_cols + 2 * num_flanking_columns)
    # leftmost x offset
    offset_start = BASES_PER_COLUMN * num_flanking_columns
    # rightmost x offset
    offset_end = offset_start + BASES_PER_COLUMN * num_cols
    # x offset just to left of seam
    offset_mid = offset_start + BASES_PER_COLUMN * (seam_left_column + 1)

    helices = _create_helices(num_helices + 2 * num_flanking_helices, num_bases_per_helix)
    scaffold = _create_scaffold(offset_start, offset_end, offset_mid, num_helices, num_flanking_helices,
                                scaffold_nick_offset)
    staples = _create_staples(offset_start, offset_end, offset_mid, num_helices, num_flanking_helices,
                              num_cols, nick_pattern, edge_staples, idt)

    design = sc.DNADesign(helices=helices, strands=[scaffold] + staples, grid=sc.square)

    if twist_correction_deletion_spacing > 0:
        add_twist_correction_deletions(design=design,
                                       offset_start=offset_start,
                                       deletion_spacing=twist_correction_deletion_spacing,
                                       deletion_start_col=twist_correction_start_col,
                                       deletion_offset=twist_correction_deletion_offset,
                                       num_helices=num_helices,
                                       num_cols=num_cols,
                                       num_flanking_helices=num_flanking_helices)

    if assign_seq:
        scaffold_seq = sc.m13_sequence if custom_scaffold is None else custom_scaffold
        design.assign_dna(scaffold, scaffold_seq)

    design.scaffold = scaffold

    if idt:
        design.set_default_idt(True)
        scaffold.set_default_idt(False)

    return design


BASES_PER_COLUMN = 16


def _create_helices(num_helices: int, num_bases_per_helix: int):
    return [sc.Helix(max_bases=num_bases_per_helix) for _ in range(num_helices)]


def _create_scaffold(offset_start: int, offset_end: int, offset_mid: int, num_helices: int,
                     num_flanking_helices: int, scaffold_nick_offset: int):
    # top substrand is continguous
    top_substrand = sc.Substrand(helix=0 + num_flanking_helices, forward=True,
                                 start=offset_start, end=offset_end)
    substrands_left = []
    substrands_right = []
    if scaffold_nick_offset < 0:
        scaffold_nick_offset = offset_mid
    for helix in range(1 + num_flanking_helices, num_helices + num_flanking_helices):
        # otherwise there's a nick (bottom helix) or the seam crossover (all other than top and bottom)
        # possibly nick on bottom helix is not along seam
        center_offset = offset_mid if helix < num_helices + num_flanking_helices - 1 else scaffold_nick_offset
        forward = (helix % 2 == num_flanking_helices % 2)
        left_substrand = sc.Substrand(helix=helix, forward=forward,
                                      start=offset_start, end=center_offset)
        right_substrand = sc.Substrand(helix=helix, forward=forward,
                                       start=center_offset, end=offset_end)
        substrands_left.append(left_substrand)
        substrands_right.append(right_substrand)
    substrands_left.reverse()
    substrands = substrands_left + [top_substrand] + substrands_right
    return sc.Strand(substrands=substrands, color=sc.default_scaffold_color)


def _create_staples(offset_start: int, offset_end: int, offset_mid: int, num_helices: int,
                    num_flanking_helices: int, num_cols: int,
                    nick_pattern: NickPattern, edge_staples, idt: bool):
    if edge_staples:
        left_edge_staples = _create_left_edge_staples(offset_start, num_helices, num_flanking_helices, idt)
        right_edge_staples = _create_right_edge_staples(offset_end, num_helices, num_flanking_helices, idt)
    else:
        left_edge_staples = []
        right_edge_staples = []
    seam_staples = _create_seam_staples(offset_mid, num_helices, num_flanking_helices, idt)
    inner_staples = _create_inner_staples(offset_start, offset_end, offset_mid, num_helices,
                                          num_flanking_helices, num_cols, nick_pattern, idt)
    return left_edge_staples + right_edge_staples + seam_staples + inner_staples


def _create_seam_staples(offset_mid: int, num_helices: int, num_flanking_helices: int, idt: bool):
    staples = []
    crossover_left = offset_mid - BASES_PER_COLUMN
    crossover_right = offset_mid + BASES_PER_COLUMN
    nick_bot = crossover_left + 8
    nick_top = crossover_right - 8
    for helix in range(1 + num_flanking_helices, num_helices + num_flanking_helices - 1, 2):
        bot_helix_forward = False
        ss_left_top = sc.Substrand(helix=helix, forward=not bot_helix_forward,
                                   start=crossover_left, end=nick_top)
        ss_left_bot = sc.Substrand(helix=helix + 1, forward=bot_helix_forward,
                                   start=crossover_left, end=nick_bot)
        ss_right_bot = sc.Substrand(helix=helix + 1, forward=bot_helix_forward,
                                    start=nick_bot, end=crossover_right)
        ss_right_top = sc.Substrand(helix=helix, forward=not bot_helix_forward,
                                    start=nick_top, end=crossover_right)
        staple_left = sc.Strand(substrands=[ss_left_bot, ss_left_top])
        staple_right = sc.Strand(substrands=[ss_right_top, ss_right_bot])
        staples.append(staple_left)
        staples.append(staple_right)

    first_helix = num_flanking_helices
    last_helix = num_flanking_helices + num_helices - 1
    first_staple_ss = sc.Substrand(helix=first_helix, forward=False,
                                   start=nick_bot, end=nick_bot + BASES_PER_COLUMN * 2)
    last_staple_ss = sc.Substrand(helix=last_helix, forward=True,
                                  start=nick_top - BASES_PER_COLUMN * 2, end=nick_top)
    first_staple = sc.Strand(substrands=[first_staple_ss])
    last_staple = sc.Strand(substrands=[last_staple_ss])

    return [first_staple] + staples + [last_staple]


def _create_left_edge_staples(offset_start: int, num_helices: int, num_flanking_helices: int, idt: bool):
    staples = []
    crossover_right = offset_start + BASES_PER_COLUMN
    for helix in range(0 + num_flanking_helices, num_helices + num_flanking_helices, 2):
        bot_helix_forward = True
        ss_5p_bot = sc.Substrand(helix=helix + 1, forward=bot_helix_forward,
                                 start=offset_start, end=crossover_right)
        ss_3p_top = sc.Substrand(helix=helix, forward=not bot_helix_forward,
                                 start=offset_start, end=crossover_right)
        staple = sc.Strand(substrands=[ss_5p_bot, ss_3p_top])
        staples.append(staple)
    return staples


def _create_right_edge_staples(offset_end: int, num_helices: int, num_flanking_helices: int, idt: bool):
    staples = []
    crossover_left = offset_end - BASES_PER_COLUMN
    for helix in range(0 + num_flanking_helices, num_helices + num_flanking_helices, 2):
        bot_helix_forward = True
        ss_5p_top = sc.Substrand(helix=helix, forward=not bot_helix_forward,
                                 start=crossover_left, end=offset_end)
        ss_3p_bot = sc.Substrand(helix=helix + 1, forward=bot_helix_forward,
                                 start=crossover_left, end=offset_end)
        staple = sc.Strand(substrands=[ss_5p_top, ss_3p_bot])
        staples.append(staple)
    return staples


def _create_inner_staples(offset_start: int, offset_end: int, offset_mid: int, num_helices: int,
                          num_flanking_helices: int, num_cols: int,
                          nick_pattern: NickPattern, idt: bool):
    if nick_pattern is not NickPattern.staggered:
        raise NotImplementedError("Currently can only handle staggered nick pattern")
    # if ((num_cols - 4) // 2) % 2 != 0:
    #     raise NotImplementedError("Currently can only handle num_cols such that an even number of "
    #                               "columns appear between each edge column and seam column, "
    #                               "i.e., ((num_cols - 4) // 2) % 2 == 0")
    len_half_col = BASES_PER_COLUMN // 2

    staples = []
    for col in range(num_cols):
        x_l = offset_start + BASES_PER_COLUMN * col
        x_r = offset_start + BASES_PER_COLUMN * (col + 1)
        x_mid_col = x_l + len_half_col
        if (x_l == offset_start  # skip left edge column
                or x_r == offset_mid  # skip left seam column
                or x_l == offset_mid  # skip right seam column
                or x_r == offset_end):  # skip right edge column
            continue
        if col % 2 == 1:
            # special staple in odd column is 24-base staple along top helix
            h1_forward = True
            ss_top_5p_h0 = sc.Substrand(helix=0 + num_flanking_helices, forward=not h1_forward,
                                        start=x_l, end=x_mid_col + BASES_PER_COLUMN)
            ss_top_3p_h1 = sc.Substrand(helix=1 + num_flanking_helices, forward=h1_forward,
                                        start=x_l, end=x_mid_col)
            staple_top = sc.Strand(substrands=[ss_top_5p_h0, ss_top_3p_h1])
            staples.append(staple_top)

            for helix in range(1 + num_flanking_helices, num_helices + num_flanking_helices - 2, 2):
                helix_i_forward = True
                ss_helix_i = sc.Substrand(helix=helix, forward=helix_i_forward,
                                          start=x_mid_col, end=x_r)
                ss_helix_ip1 = sc.Substrand(helix=helix + 1, forward=not helix_i_forward,
                                            start=x_l, end=x_r)
                ss_helix_ip2 = sc.Substrand(helix=helix + 2, forward=helix_i_forward,
                                            start=x_l, end=x_mid_col)
                staple = sc.Strand(substrands=[ss_helix_i, ss_helix_ip1, ss_helix_ip2])
                staples.append(staple)

        else:
            # special staple in even column is 24-base staple along bottom helix (hm1="helix minus 1")
            hm1_forward = True
            ss_bot_5p_hm1 = sc.Substrand(helix=num_helices + num_flanking_helices - 1, forward=hm1_forward,
                                         start=x_mid_col - BASES_PER_COLUMN, end=x_r)
            ss_bot_3p_hm2 = sc.Substrand(helix=num_helices + num_flanking_helices - 2,
                                         forward=not hm1_forward,
                                         start=x_mid_col, end=x_r)
            staple_bot = sc.Strand(substrands=[ss_bot_5p_hm1, ss_bot_3p_hm2])
            staples.append(staple_bot)

            for helix in range(0 + num_flanking_helices, num_helices + num_flanking_helices - 3, 2):
                helix_i_forward = False
                ss_helix_i = sc.Substrand(helix=helix, forward=helix_i_forward,
                                          start=x_mid_col, end=x_r)
                ss_helix_ip1 = sc.Substrand(helix=helix + 1, forward=not helix_i_forward,
                                            start=x_l, end=x_r)
                ss_helix_ip2 = sc.Substrand(helix=helix + 2, forward=helix_i_forward,
                                            start=x_l, end=x_mid_col)
                staple = sc.Strand(substrands=[ss_helix_ip2, ss_helix_ip1, ss_helix_i])
                staples.append(staple)

    return staples


def add_deletion_in_range(design: sc.DNADesign, helix: int, start: int, end: int, deletion_offset: int):
    """Inserts deletion somewhere in given range.

    `offset` is the relative offset within a column at which to put the deletions.
    If negative, chooses first available offset."""
    candidate_offsets = []
    for candidate_deletion_offset in range(start, end):
        if valid_deletion_offset(design, helix, candidate_deletion_offset):
            candidate_offsets.append(candidate_deletion_offset)
    if len(candidate_offsets) == 0:
        raise ValueError(f"no pair of Substrands found on Helix {helix} "
                         f"overlapping interval [{start},{end})")
    if deletion_offset < 0:
        # pick offset furthest from edges of interval
        candidate_offsets.sort(key=lambda offset: min(offset - start, end - offset))
        deletion_absolute_offset = candidate_offsets[0]
    else:
        deletion_absolute_offset = start + deletion_offset
    design.add_deletion(helix, deletion_absolute_offset)


def valid_deletion_offset(design: sc.DNADesign, helix: int, offset: int):
    substrands_at_offset = design.substrands_at(helix, offset)
    if len(substrands_at_offset) > 2:
        raise ValueError(f'Invalid DNADesign; more than two Substrands found at '
                         f'helix {helix} and offset {offset}: '
                         f'{substrands_at_offset}')
    elif len(substrands_at_offset) != 2:
        return False
    for ss in substrands_at_offset:
        if offset in ss.deletions:
            return False  # already a deletion there
        if offset in (insertion[0] for insertion in ss.insertions):
            return False  # already an insertion there
        if offset == ss.start:
            return False  # no 5' end
        if offset == ss.end - 1:
            return False  # no 3' end
    return True


def add_twist_correction_deletions(design: sc.DNADesign,
                                   offset_start: int,
                                   deletion_spacing: int,
                                   deletion_start_col: int,
                                   deletion_offset: int,
                                   num_helices: int,
                                   num_cols: int,
                                   num_flanking_helices: int):
    for col in range(deletion_start_col, num_cols):
        col_start = offset_start + col * BASES_PER_COLUMN
        col_end = offset_start + (col + 1) * BASES_PER_COLUMN
        if (col - deletion_start_col) % deletion_spacing == 0:
            for helix in range(num_flanking_helices, num_flanking_helices + num_helices):
                add_deletion_in_range(design=design, helix=helix, start=col_start + 1,
                                      end=col_end - 1, deletion_offset=deletion_offset)
