"""
Defines function :any:`origami_rectangle.create` for creating a DNA origami rectangle.
"""

import scadnano as sc
from enum import Enum, auto


class NickPattern(Enum):
    """Represents two options for where to place nicks between staples."""

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

even = NickPattern.even
"""Convenience reference defined so one can type :const:`origami_rectangle.even` 
instead of :const:`origami_rectangle.NickPattern.even`."""

odd = NickPattern.odd
"""Convenience reference defined so one can type :const:`origami_rectangle.odd` 
instead of :const:`origami_rectangle.NickPattern.odd`."""


def create(num_helices: int, num_cols: int, nick_pattern: NickPattern = NickPattern.staggered,
           twist_correction_deletion_spacing: int = 0, num_flanking_columns: int = 1,
           custom_scaffold: str = None) -> sc.DNADesign:
    """
    Creates a DNA origami rectangle with a given number of helices and
    "columns" (16-base-wide region in each helix). The columns include
    the 16-base regions on the end where potential "edge staples" go,
    as well as the two-column-wide "seam" region in the middle.

    Below is an example diagram of the staples created by this function.

    Consider for example the function call
    ``origami_rectangle.create(num_helices=8, num_cols=12, nick_pattern=origami_rectangle.staggered)``.
    The scaffold strand resulting from this call is shown below:

    .. code-block:: none

          #       C0       #       C1       #       C2       #       C3       #       C4       #       C5       #       C6       #       C7       #       C8       #       C9       #       C10      #      C11       #
        H0 +--------------- ---------------- ---------------- ---------------- ---------------- ---------------- ---------------- ---------------- ---------------- ---------------- ---------------- ---------------+
           |                                                                                                                                                                                                         |
        H1 +--------------- ---------------- ---------------- ---------------- ---------------- ---------------+ +--------------- ---------------- ---------------- ---------------- ---------------- ---------------+
                                                                                                               | |
        H2 +--------------- ---------------- ---------------- ---------------- ---------------- ---------------+ +--------------- ---------------- ---------------- ---------------- ---------------- ---------------+
           |                                                                                                                                                                                                         |
        H3 +--------------- ---------------- ---------------- ---------------- ---------------- ---------------+ +--------------- ---------------- ---------------- ---------------- ---------------- ---------------+
                                                                                                               | |
        H4 +--------------- ---------------- ---------------- ---------------- ---------------- ---------------+ +--------------- ---------------- ---------------- ---------------- ---------------- ---------------+
           |                                                                                                                                                                                                         |
        H5 +--------------- ---------------- ---------------- ---------------- ---------------- ---------------+ +--------------- ---------------- ---------------- ---------------- ---------------- ---------------+
                                                                                                               | |
        H6 +--------------- ---------------- ---------------- ---------------- ---------------- ---------------+ +--------------- ---------------- ---------------- ---------------- ---------------- ---------------+
           |                                                                                                                                                                                                         |
        H7 +--------------- ---------------- ---------------- ---------------- ---------------- ---------------] <--------------- ---------------- ---------------- ---------------- ---------------- ---------------+


    Helix indices are labelled ``H0``, ``H1``, x... and column indices are labeled ``C0``, ``C1``, ...
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

          #       C0       #       C1       #       C2       #       C3       #       C4       #       C5       #       C6       #       C7       #       C8       #       C9       #       C10      #       C11      #
        H0 <--------------+ +--------------- -------]<------+ +--------------- -------]<------+ +--------------- -------]<------+ +--------------- -------]<------+ +--------------- -------]<------+ +--------------]
                          | |                               | |                               | |                               | |                               | |                               | |
        H1 [--------------+ +------>[------+ +--------------+ +------>[------+ +--------------+ +------>[------- ---------------+ +------>[------+ +--------------+ +------>[------+ +--------------+ +-------------->
                                           | |                               | |                                                                 | |                               | |
        H2 <--------------+ +--------------+ +------]<------+ +--------------+ +------]<------+ +--------------- -------]<------+ +--------------+ +------]<------+ +--------------+ +------]<------+ +--------------]
                          | |                               | |                               | |                               | |                               | |                               | |
        H3 [--------------+ +------>[------+ +--------------+ +------>[------+ +--------------+ +------>[------- ---------------+ +------>[------+ +--------------+ +------>[------+ +--------------+ +-------------->
                                           | |                               | |                                                                 | |                               | |
        H4 <--------------+ +--------------+ +------]<------+ +--------------+ +------]<------+ +--------------- -------]<------+ +--------------+ +------]<------+ +--------------+ +------]<------+ +--------------]
                          | |                               | |                               | |                               | |                               | |                               | |
        H5 [--------------+ +------>[------+ +--------------+ +------>[------+ +--------------+ +------>[------- ---------------+ +------>[------+ +--------------+ +------>[------+ +--------------+ +-------------->
                                           | |                               | |                                                                 | |                               | |
        H6 <--------------+ +--------------+ +------]<------+ +--------------+ +------]<------+ +--------------- -------]<------+ +--------------+ +------]<------+ +--------------+ +------]<------+ +--------------]
                          | |                               | |                               | |                               | |                               | |                               | |
        H7 [--------------+ +------>[------- ---------------+ +------>[------- ---------------+ +------>[------- ---------------+ +------>[------- ---------------+ +------>[------- ---------------+ +-------------->

    The seam crosses columns ``C5`` and ``C6``.
    The left and right edge staples respectively are in columns ``C0`` and ``C11``.

    Prints warning if number of bases exceeds 7249 (length of standard M13 scaffold strand),
    but does not otherwise cause an error.

    `num_cols` must be even.

    If `twist_correction_deletion_spacing > 0`, adds deletions between crossovers in one out of
    every `twist_correction_deletion_spacing` columns. (TODO: cite Sungwook's paper)

    `num_flanking_columns` is the number of empty columns on the helix on each side of the origami.

    `nick_pattern` describes whether nicks between staples should be "staggered" or not.
    See :class:`origami_rectangle.NickPattern` for details.
    
    `custom_scaffold` is the scaffold sequence to use. 
    If set to ``None``, the standard 7249-base M13 is used.

    Here's an example of using :any:`origami_rectangle.create` to create a design for a
    16-helix rectangle and write it to a file ``16_helix_rectangle.dna``
    readable by scadnano.

    .. code-block:: Python

        import origami_rectangle as rect

        num_helices = 16
        num_cols = 24  # XXX: ensure num_cols is even since we divide it by 2
        design = rect.create(num_helices=num_helices, num_cols=num_cols, nick_pattern=rect.staggered)
        design.write_to_file("16_helix_rectangle.dna")

    However, we caution that :any:`origami_rectangle.create` is not intended to be very
    extensible for creating many different types of DNA origami. It is more intended as an
    example whose source code can be an efficient reference to learn the :mod:`scadnano` API.
    """  # noqa (This line is here to suppress a PEP warning about long lines in the source code)

    if num_cols % 2 != 0:
        raise ValueError(f'num_cols must be even but is {num_cols}')
    if num_helices % 2 != 0:
        raise ValueError(f'num_helices must be even but is {num_helices}')
    if num_cols * num_helices * BASES_PER_COLUMN > 7249:
        print(f'WARNING: you chose {num_cols} columns and {num_helices} helices, '
              f'which requires {num_cols * num_helices * BASES_PER_COLUMN} bases, '
              f'greater than the 7249 available in standard M13.')

    # allow an empty "flanking" column on each side
    num_bases_per_helix = BASES_PER_COLUMN * (num_cols + 2 * num_flanking_columns)
    # leftmost x offset
    offset_start = BASES_PER_COLUMN
    # rightmost x offset
    offset_end = offset_start + BASES_PER_COLUMN * num_cols
    # x offset just to left of seam
    offset_mid = offset_start + BASES_PER_COLUMN * (num_cols // 2)

    helices = _create_helices(num_helices, num_bases_per_helix)
    scaffold = _create_scaffold(offset_start, offset_end, offset_mid, num_helices)
    staples = _create_staples(offset_start, offset_end, offset_mid, num_helices, num_cols, nick_pattern)

    if twist_correction_deletion_spacing > 0:
        raise NotImplementedError()

    design = sc.DNADesign(helices=helices, strands=[scaffold] + staples, grid=sc.square)

    scaffold_seq = sc.m13_sequence if custom_scaffold is None else custom_scaffold
    design.assign_dna(scaffold, scaffold_seq)

    return design


BASES_PER_COLUMN = 16


def _create_helices(num_helices: int, num_bases_per_helix: int):
    return [sc.Helix(idx=idx, max_bases=num_bases_per_helix) for idx in range(num_helices)]


def _create_scaffold(offset_start: int, offset_end: int, offset_mid: int, num_helices: int):
    top_substrand = sc.Substrand(helix_idx=0, direction=sc.right,
                                 start=offset_start, end=offset_end)
    substrands_left = []
    substrands_right = []
    for helix_idx in range(1, num_helices):
        # otherwise there's a nick (bottom helix) or the seam crossover (all other than top and bottom)
        direction = sc.right if helix_idx % 2 == 0 else sc.left
        left_substrand = sc.Substrand(helix_idx=helix_idx, direction=direction,
                                      start=offset_start, end=offset_mid)
        right_substrand = sc.Substrand(helix_idx=helix_idx, direction=direction,
                                       start=offset_mid, end=offset_end)
        substrands_left.append(left_substrand)
        substrands_right.append(right_substrand)
    substrands_left.reverse()
    substrands = substrands_left + [top_substrand] + substrands_right
    return sc.Strand(substrands=substrands, color=sc.default_scaffold_color)


def _create_staples(offset_start, offset_end, offset_mid, num_helices, num_cols, nick_pattern):
    left_edge_staples = _create_left_edge_staples(offset_start, num_helices)
    right_edge_staples = _create_right_edge_staples(offset_end, num_helices)
    seam_staples = _create_seam_staples(offset_mid, num_helices)
    inner_staples = _create_inner_staples(offset_start, offset_end, offset_mid, num_helices, num_cols, nick_pattern)
    return left_edge_staples + right_edge_staples + seam_staples + inner_staples


def _create_seam_staples(offset_mid, num_helices):
    staples = []
    for helix_idx in range(0, num_helices, 2):
        crossover_left = offset_mid - BASES_PER_COLUMN
        crossover_right = offset_mid + BASES_PER_COLUMN
        nick_bot = crossover_left + 8
        nick_top = crossover_right - 8
        ss_5p_top = sc.Substrand(helix_idx=helix_idx, direction=sc.left,
                                 start=crossover_left, end=nick_top)
        ss_3p_bot = sc.Substrand(helix_idx=helix_idx + 1, direction=sc.right,
                                 start=crossover_left, end=nick_bot)
        ss_5p_bot = sc.Substrand(helix_idx=helix_idx + 1, direction=sc.right,
                                 start=nick_bot, end=crossover_right)
        ss_3p_top = sc.Substrand(helix_idx=helix_idx, direction=sc.left,
                                 start=nick_top, end=crossover_right)
        staple_5p_top = sc.Strand(substrands=[ss_5p_top, ss_3p_bot])
        staple_5p_bot = sc.Strand(substrands=[ss_5p_bot, ss_3p_top])
        staples.append(staple_5p_top)
        staples.append(staple_5p_bot)
    return staples


def _create_left_edge_staples(offset_start, num_helices):
    staples = []
    crossover_right = offset_start + BASES_PER_COLUMN
    for helix_idx in range(0, num_helices, 2):
        ss_5p_bot = sc.Substrand(helix_idx=helix_idx + 1, direction=sc.right,
                                 start=offset_start, end=crossover_right)
        ss_3p_top = sc.Substrand(helix_idx=helix_idx, direction=sc.left,
                                 start=offset_start, end=crossover_right)
        staple = sc.Strand(substrands=[ss_5p_bot, ss_3p_top])
        staples.append(staple)
    return staples


def _create_right_edge_staples(offset_end, num_helices):
    staples = []
    crossover_left = offset_end - BASES_PER_COLUMN
    for helix_idx in range(0, num_helices, 2):
        ss_5p_top = sc.Substrand(helix_idx=helix_idx, direction=sc.left,
                                 start=crossover_left, end=offset_end)
        ss_3p_bot = sc.Substrand(helix_idx=helix_idx + 1, direction=sc.right,
                                 start=crossover_left, end=offset_end)
        staple = sc.Strand(substrands=[ss_5p_top, ss_3p_bot])
        staples.append(staple)
    return staples


def _create_inner_staples(offset_start, offset_end, offset_mid, num_helices, num_cols, nick_pattern):
    if nick_pattern is not NickPattern.staggered:
        raise NotImplementedError("Currently can only handle staggered nick pattern")
    if ((num_cols - 4) // 2) % 2 != 0:
        raise NotImplementedError("Currently can only handle num_cols such that an even number of "
                                  "columns appear between each edge column and seam column, "
                                  "i.e., ((num_cols - 4) // 2) % 2 == 0")
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
            ss_top_5p_h0 = sc.Substrand(helix_idx=0, direction=sc.left,
                                        start=x_l, end=x_mid_col + BASES_PER_COLUMN)
            ss_top_3p_h1 = sc.Substrand(helix_idx=1, direction=sc.right,
                                        start=x_l, end=x_mid_col)
            staple_top = sc.Strand(substrands=[ss_top_5p_h0, ss_top_3p_h1])
            staples.append(staple_top)

            for helix_idx in range(1, num_helices - 2, 2):
                ss_helix_i = sc.Substrand(helix_idx=helix_idx, direction=sc.right,
                                          start=x_mid_col, end=x_r)
                ss_helix_ip1 = sc.Substrand(helix_idx=helix_idx + 1, direction=sc.left,
                                            start=x_l, end=x_r)
                ss_helix_ip2 = sc.Substrand(helix_idx=helix_idx + 2, direction=sc.right,
                                            start=x_l, end=x_mid_col)
                staple = sc.Strand(substrands=[ss_helix_i, ss_helix_ip1, ss_helix_ip2])
                staples.append(staple)

        else:
            # special staple in even column is 24-base staple along bottom helix
            ss_bot_5p_hm1 = sc.Substrand(helix_idx=num_helices - 1, direction=sc.right,
                                         start=x_mid_col - BASES_PER_COLUMN, end=x_r)
            ss_bot_3p_hm2 = sc.Substrand(helix_idx=num_helices - 2, direction=sc.left,
                                         start=x_mid_col, end=x_r)
            staple_bot = sc.Strand(substrands=[ss_bot_5p_hm1, ss_bot_3p_hm2])
            staples.append(staple_bot)

            for helix_idx in range(0, num_helices - 3, 2):
                ss_helix_i = sc.Substrand(helix_idx=helix_idx, direction=sc.left,
                                          start=x_mid_col, end=x_r)
                ss_helix_ip1 = sc.Substrand(helix_idx=helix_idx + 1, direction=sc.right,
                                            start=x_l, end=x_r)
                ss_helix_ip2 = sc.Substrand(helix_idx=helix_idx + 2, direction=sc.left,
                                            start=x_l, end=x_mid_col)
                staple = sc.Strand(substrands=[ss_helix_ip2, ss_helix_ip1, ss_helix_i])
                staples.append(staple)


    return staples


