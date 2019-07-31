"""
Scripting library for scadnano. Used to write python scripts outputting ``*.dna`` files readable
by `scadnano <https://web.cs.ucdavis.edu/~doty/scadnano/>`_.
"""

import enum
from dataclasses import dataclass, field
from typing import Tuple, List, Dict
import m13
from collections import defaultdict, OrderedDict

from json_utils import JSONSerializable, json_encode, NoIndent

Y_GRID_COORDINATE_SCALE = 30
"""The default main view SVG y-coordinate of a :any:`Helix` with index `idx` is 
`idx * Y_GRID_COORDINATE_SCALE`."""

m13_sequence = m13.sequence
"""
The M13mp18 DNA sequence, starting from cyclic rotation 5588, as defined in
`GenBank <https://www.neb.com/~/media/NebUs/Page%20Images/Tools%20and%20Resources/Interactive%20Tools/DNA%20Sequences%20and%20Maps/Text%20Documents/m13mp18gbk.txt>`_.
"""  # noqa (suppress PEP warning)


##############################################################################
# Colors
# As with JSON serialization, there are external libraries to handle colors
# in Python, but I want this to be a simple, single-file library, so we just
# implement what we need below.

@dataclass
class Color(JSONSerializable):
    r: int = 0
    """Red component: 0-255"""

    g: int = 0
    """Green component: 0-255"""

    b: int = 0
    """Blue component: 0-255"""

    def to_json_serializable(self):
        # Return object representing this Color that is JSON serializable.
        return NoIndent(self.__dict__)


class ColorCycler:
    """
    Calling ``next(color_cycler)`` on a ColorCycler named ``color_cycler``
    returns a the next :any:`Color` from a fixed size list,
    cycling after reaching the end of the list.

    To choose new colors, set ``color_cycler.colors`` to a new list of :any:`Color`'s.
    """

    # These are copied from cadnano:
    # https://github.com/sdouglas/cadnano2/blob/master/views/styles.py#L97
    _colors = [Color(204, 0, 0),
               Color(247, 67, 8),
               Color(247, 147, 30),
               Color(170, 170, 0),
               Color(87, 187, 0),
               Color(0, 114, 0),
               Color(3, 182, 162),
               # Color(23, 0, 222), # don't like this because it looks too much like scaffold
               Color(50, 0, 150),  # this one is better contrast with scaffold
               Color(184, 5, 108),
               Color(51, 51, 51),
               Color(115, 0, 222),
               Color(136, 136, 136)]
    """List of colors to cycle through."""

    def __init__(self):
        self._current_color_idx = 0
        # random order
        order = [3, 11, 0, 8, 1, 10, 6, 5, 9, 4, 7, 2]
        colors_shuffled = [None] * len(self._colors)
        for i, color in zip(order, self._colors):
            colors_shuffled[i] = color
        self._colors = colors_shuffled

    def __next__(self):
        color = self._colors[self._current_color_idx]
        self._current_color_idx = (self._current_color_idx + 1) % len(self._colors)
        return color

    @property
    def colors(self):
        """The colors that are cycled through when calling ``next()`` on some :any:`ColorCycler`."""
        return list(self._colors)

    @colors.setter
    def colors(self, newcolors):
        self._colors = newcolors
        self._current_color_idx = 0


default_scaffold_color = Color(0, 102, 204)
"""Default color for scaffold strand(s)."""

color_cycler = ColorCycler()


#
# END Colors
##############################################################################


@enum.unique
class Grid(str, enum.Enum):
    """Represents default patterns for laying out helices in the side view."""

    square = "square"
    """Square lattice."""

    hex = "hex"
    """Hexagonal lattice."""


@enum.unique
class Direction(str, enum.Enum):
    """Two directions one can move on a :any:`Helix`.
    Corresponds to left and right in the main view."""

    left = "left"
    """ Direction of smaller base offset values on a :any:`Helix`.
    The leftmost offset of a :any:`Substrand` is :any:`Substrand.start`. """

    right = "right"
    """ Direction of larger base offset values on a :any:`Helix`.
    The rightmost offset of a :any:`Substrand` is :any:`Substrand.end`-1. """


# convenience names for users
left = Direction.left
right = Direction.right
square = Grid.square
hexagonal = Grid.hex  # should not use identifier "hex" because that's a Python built-in function


def opposite(d: Direction) -> Direction:
    return Direction.right if d is Direction.left else Direction.left


@dataclass
class Helix(JSONSerializable):
    idx: int
    """ idx: Index of helix (used helices must be given indices 0..num_helices-1). """

    max_bases: int
    """Maximum length of :any:`Substrand` that can be drawn on this :any:`Helix`."""

    major_tick_distance: int = -1
    """If positive, overrides :any:`DNADesign.major_tick_distance`."""

    grid_position: Tuple[int, int] = None
    """`(x,y)` position of this helix in the side view grid, 
    if :const:`Grid.square` or :const:`Grid.hex` is used
    in the :any:`DNADesign` containing this helix.
    
    Default is `x` = 0, `y` = :any:`Helix.idx` ."""

    position: Tuple[float, float] = None
    """`(x,y)` SVG coordinates of base offset 0 of this Helix in the main view. 
    
    Default is `x` = 0, `y` = :any:`Helix.idx` * :any:`Y_GRID_COORDINATE_SCALE`."""

    used: bool = True
    """If ``False``, this helix has :any:`Helix.idx` = ``None`` and appears only in the side view, 
    not the main view. If ``True``, it appears in the main view and has a positive integer value
    for :any:`Helix.idx`, though it may not actually have any :any:`Substrand`'s on it."""

    def to_json_serializable(self):
        dct = self.__dict__
        if self.major_tick_distance <= 0:
            del dct['major_tick_distance']
        return NoIndent(dct)

    def __post_init__(self):
        if self.grid_position is None:
            # default to same x-coordinate 0, and y-coordinate = idx
            self.grid_position = (0, self.idx)
        if self.position is None:
            # default to same x- and z-coordinates 0, and y-coordinate scales with idx
            self.position = (0, self.idx * Y_GRID_COORDINATE_SCALE)


@dataclass
class Substrand(JSONSerializable):
    """
    A maximal portion of a :any:`Strand` that is continguous on a single :any:`Helix`.
    A :any:`Strand` contains a list of :any:`Substrand`'s.
    """

    helix_idx: int
    """:any:`Helix.idx` of the :any:`Helix` where this Substrand resides."""

    direction: Direction
    """The direction that the 3' end of this Substrand points along its :any:`Helix`."""

    start: int
    """
    The smallest offset position of any base on this Substrand
    (3' end if :any:`Substrand.direction` = :any:`Direction.left`,
    5' end if :any:`Substrand.direction` = :any:`Direction.right`).
    """

    end: int
    """
    1 plus the largest offset position of any base on this Substrand
    (5' end if :any:`Substrand.direction` = :any:`Direction.left`,
    3' end if :any:`Substrand.direction` = :any:`Direction.right`).
    Note that the set of base offsets occupied by this Substrand is {start, start+1, ..., end-1},
    the same convention used in Python for slices of lists and strings.
    (e.g., :samp:`"abcdef"[1:3] == "bc"`)
    """

    deletions: List[int] = field(default_factory=list)
    """List of positions of deletions on this Substrand."""

    insertions: List[Tuple[int, int]] = field(default_factory=list)
    """List of (position,num_insertions) pairs on this Substrand."""

    _parent_strand: 'Strand' = field(init=False, repr=False, compare=False, default=None)

    # not serialized; for efficiency

    def to_json_serializable(self):
        dct = OrderedDict()
        dct['helix_idx'] = self.helix_idx
        dct['direction'] = self.direction
        dct['start'] = self.start
        dct['end'] = self.end
        if len(self.deletions) > 0:
            dct['deletions'] = self.deletions
        if len(self.insertions) > 0:
            dct['insertions'] = self.insertions
        return NoIndent(dct)

    def __len__(self):
        """Number of bases in this Substrand."""
        return self.end - self.start - len(self.deletions) + self._num_insertions()

    def _num_insertions(self):
        # total number of insertions in this Substrand
        return sum(insertion[1] for insertion in self.insertions)

    def contains_offset(self, offset: int):
        """Indicates if `offset` is the offset of a base on this substrand.

        Note that offsets refer to visual portions of the displayed grid for the Helix.
        If for example, this Substrand starts at position 0 and ends at 10, and it has 5 deletions,
        then it contains the offset 7 even though there is no base 7 positions from the start."""
        return self.start <= offset < self.end

    def dna_sequence(self):
        return self.dna_sequence_in(0, len(self))

    def dna_sequence_in(self, interval_left: int, interval_right: int):
        """Return DNA sequence of this Substrand in the interval of offsets given by
        (`interval_left`, `interval_right`)."""
        strand_seq = self._parent_strand.dna_sequence
        if strand_seq is None:
            return None
        str_idx_left, str_idx_right = self.interval_to_strand_dna_idxs(interval_left, interval_right)
        return strand_seq[str_idx_left:str_idx_right]

    def get_seq_start_idx(self):
        """Starting DNA subsequence index for first base of this :any:`Substrand` on its
        Parent :any:`Strand`'s DNA sequence."""
        substrands = self._parent_strand.substrands
        # index of self in parent strand's list of substrands
        self_substrand_idx = substrands.index(self)
        # index of self's position within the DNA sequence of parent strand
        self_seq_idx_start = sum(len(prev_substrand)
                                 for prev_substrand in substrands[:self_substrand_idx])
        return self_seq_idx_start

    def interval_to_strand_dna_idxs(self, interval_start, interval_end):
        """Convert from offset interval (inclusive,exclusive) on :any:`Substrand`'s :any:`Helix`
        to string indices (inclusive,exclusive) on the parent :any:`Strand`'s DNA sequence."""
        self_seq_idx_start = self.get_seq_start_idx()
        str_idx_start = (interval_start - self.start) + self_seq_idx_start
        str_idx_end = (interval_end - self.start) + self_seq_idx_start
        return str_idx_start, str_idx_end

    def strand_dna_idxs_to_interval(self, str_idx_start, str_idx_end):
        """Convert from string index (inclusive,exclusive) on parent :any:`Strand`
        to offset interval (inclusive,exclusive) on :any:`Substrand`'s :any:`Helix`."""
        self_seq_idx_start = self.get_seq_start_idx()
        interval_start = (str_idx_start - self_seq_idx_start) + self.start
        interval_end = (str_idx_end - self_seq_idx_start) + self.start
        return interval_start, interval_end

    # The type hint 'Substrand' must be in quotes since Substrand is not yet defined.
    # This is a "forward reference": https://www.python.org/dev/peps/pep-0484/#forward-references
    def completely_bound(self, other: 'Substrand'):
        """Indicates if this substrand's set of offsets (the set
        :math:`\{x \in \mathbb{N} \mid`
        ``self.start``
        :math:`\leq x \leq`
        ``self.end``
        :math:`\}`)
        is a subset of the set of offsets of `other`."""  # noqa (suppress PEP warning)
        return (self.helix_idx == other.helix_idx and (
                self.start >= other.start and
                self.end <= other.end))

    def overlaps(self, other: 'Substrand'):
        """Indicates if this substrands set of offsets (the set
        :math:`\{x \in \mathbb{N} \mid`
        ``self.start``
        :math:`\leq x \leq`
        ``self.end``
        :math:`\}`)
        has nonempty intersection with those of `other`."""  # noqa (suppress PEP warning)
        return (self.helix_idx == other.helix_idx and
                self.direction == opposite(other.direction) and
                self.compute_overlap(other) is not None)

    def compute_overlap(self, other: 'Substrand'):
        """Return (left,right) offset indicating overlap between this Substrand and `other`.

        Return ``None`` if they do not overlap (different helices, or non-overlapping regions
        of the same helix)."""
        overlap_start = max(self.start, other.start)
        overlap_end = min(self.end, other.end)
        # have_overlap = (self.helix_idx == other.helix_idx and (
        #         self.start <= other.end and
        #         other.start <= self.end))
        if overlap_start > overlap_end:  # overlap is empty
            return None
        return overlap_start, overlap_end


_wctable = str.maketrans('ACGTacgt', 'TGCAtgca')


def wc(seq: str) -> str:
    """Return reverse Watson-Crick complement of seq"""
    return seq.translate(_wctable)[::-1]


@dataclass
class Strand(JSONSerializable):
    """
    Represents a single strand of DNA.

    Each maximal portion that is continguous on a single :any:`Helix` is a :any:`Substrand`.
    Crossovers from one :any:`Helix` to another are implicitly from the 3' end of one of this
    Strand's :any:`Substrand`'s to the 5' end of the next :any:`Substrand`.

    Although scadnano can be used to design DNA origami, there is no special representation
    of a scaffold strand. To give a strand the same color that
    `cadnano <https://cadnano.org/>`_
    uses for the scaffold,
    use :any:`scadnano.default_scaffold_color` in the :any:`Strand` constructor:

    .. code-block:: Python

        import scadnano as sc

        scaffold_substrands = ...
        scaffold_strand = sc.Strand(substrands=scaffold_substrands, color=sc.default_scaffold_color)
    """

    substrands: List[Substrand]
    """:any:`Substrand`'s composing this Strand. Each is contiguous on a single helix."""

    # is_scaffold: bool = False
    # """For DNA origami designs, designating one (or more) strands as "scaffold" enables
    # some custom behavior (e.g., scaffold color is always the same)."""

    dna_sequence: str = None
    """Do not assign directly to this field. Always use :any:`DNADesign.assign_dna`."""

    color: Color = None
    """Color to show this strand in the main view. If not specified in the constructor,
    a color is assigned by cycling through a list of defaults given by 
    :meth:`ColorCycler.colors`"""

    # not serialized; efficient way to see a list of all substrands on a given helix
    _helix_idx_substrand_map: Dict[int, List[Substrand]] = field(
        init=False, repr=False, compare=False, default=None)

    def to_json_serializable(self):
        dct = OrderedDict()
        dct['color'] = self.color.to_json_serializable()
        # dct['is_scaffold'] = self.is_scaffold
        if self.dna_sequence is not None:
            dct['dna_sequence'] = self.dna_sequence
        dct['substrands'] = [substrand.to_json_serializable() for substrand in self.substrands]
        return dct

    def __post_init__(self):
        # if color not specified, pick one by cycling through list of staple colors, or assign default scaffold color
        global color_cycler
        if self.color is None:
            self.color = next(color_cycler)
            # self.color = color_cycler.scaffold_color if self.is_scaffold else next(color_cycler)
        self._helix_idx_substrand_map = defaultdict(list)
        for substrand in self.substrands:
            self._helix_idx_substrand_map[substrand.helix_idx].append(substrand)
        for substrand in self.substrands:
            substrand._parent_strand = self

    def __len__(self):
        """Return sum of length of Substrands of this Strand."""
        acc = 0
        for substrand in self.substrands:
            acc += len(substrand)
        return acc
        # return sum(len(substrand) for substrand in self.substrands)

    def completely_bound(self, other: 'Strand'):
        """Indicates whether `self` is completely bound to `other_strand`, meaning that
        the set of offsets occupied by `self` are a subset of those occupied by `other_strand`."""
        for helix_idx, substrands_on_helix in self._helix_idx_substrand_map.items():
            other_substrands_on_helix = other._helix_idx_substrand_map[helix_idx]
            for substrand in substrands_on_helix:
                for other_substrand in other_substrands_on_helix:
                    if substrand.completely_bound(other_substrand):
                        return True
        return False

    def overlaps(self, other: 'Strand'):
        """Indicates whether `self` overlaps `other_strand`, meaning that
        the set of offsets occupied by `self` has nonempty intersection with those occupied by `other_strand`."""
        for substrand_self in self.substrands:
            for substrand_other in other.substrands:
                if substrand_self.overlaps(substrand_other):
                    return True
        return False

    def assign_dna_complement_from(self, other: 'Strand'):
        """Assuming a DNA sequence has been assigned to `other`, assign its Watson-Crick
        complement to the portions of this Strand that are bound to `other`.

        Generally this is not called directly; use :any:`DNADesign.assign_dna` to assign
        a DNA sequence to a strand. It will figure out which other Strands need
        to be assigned via this method."""

        # if not self.overlaps(other):
        #     raise ValueError(f"{self} and {other} do not overlap, "
        #                      f"so DNA cannot be assigned to the former from the latter")
        # TODO: this has a bug and is not assigning properly; add some unit tests and get it working
        strand_complement_builder = []
        for helix_idx, substrands_on_helix_self in self._helix_idx_substrand_map.items():
            substrands_on_helix_other = other._helix_idx_substrand_map[helix_idx]
            for substrand_self in substrands_on_helix_self:
                overlaps = []
                for substrand_other in substrands_on_helix_other:
                    if substrand_self.overlaps(substrand_other):
                        overlap = substrand_self.compute_overlap(substrand_other)
                        overlaps.append((overlap, substrand_other))
                if len(overlaps) == 0:
                    continue

                overlaps.sort()

                substrand_complement_builder = []
                start_idx = substrand_self.start
                # repeatedly insert wildcards into gaps, then reverse WC complement
                for ((overlap_left, overlap_right),
                     substrand_other) in overlaps:
                    wildcards = '?' * (overlap_left - start_idx)
                    other_seq = substrand_other.dna_sequence_in(overlap_left, overlap_right)
                    overlap_complement = wc(other_seq)
                    substrand_complement_builder.append(wildcards)
                    substrand_complement_builder.append(overlap_complement)
                    start_idx = overlap_right + 1

                # last wildcard for gap between last overlap and end
                last_wildcards = '?' * (substrand_self.end + 1 - start_idx)
                substrand_complement_builder.append(last_wildcards)
                strand_complement_builder.extend(substrand_complement_builder)

        strand_complement = ''.join(strand_complement_builder)
        # TODO: combine new sequence with possible existing (replace '?'s with bases where appropriate)
        self.dna_sequence = strand_complement


# called "Model" in the scadnano source code.
@dataclass
class DNADesign(JSONSerializable):
    helices: List[Helix]
    """All of the helices in this DNADesign."""

    strands: List[Strand]
    """All of the strands in this DNADesign."""

    grid: Grid = None
    """TODO explain this."""

    major_tick_distance: int = -1
    """Distance between major ticks (bold) delimiting boundaries between bases.
    
    If negative then no major ticks are drawn.
    If :any:`DNADesign.grid` = :any:`Grid.square` then `major_tick_distance` is set to 8.
    If :any:`DNADesign.grid` = :any:`Grid.hex` then `major_tick_distance` is set to 7."""

    helix_substrand_map: Dict[int, List[Substrand]] = None

    # for optimization; maps helix index to list of substrands on that Helix

    def to_json_serializable(self):
        dct = OrderedDict()
        dct['grid'] = self.grid
        dct['major_tick_distance'] = self.major_tick_distance
        dct['helices'] = [helix.to_json_serializable() for helix in self.helices]
        dct['strands'] = [strand.to_json_serializable() for strand in self.strands]
        return dct

    def __post_init__(self):
        if self.major_tick_distance < 0:
            if self.grid == Grid.square:
                self.major_tick_distance = 8
            elif self.grid == Grid.hexagonal:
                self.major_tick_distance = 7
        self._build_helix_substrand_map()

    def _build_helix_substrand_map(self):
        self.helix_substrand_map = defaultdict(list)
        for strand in self.strands:
            for substrand in strand.substrands:
                helix_substrand_map[substrand.helix_idx].append(substrand)

    def write_to_file(self, filename):
        with open(filename, 'w') as out_file:
            out_file.write(json_encode(self))

    def add_deletion(helix_idx: int, offset: int):
        """
        Adds a deletion to the strand(s) (if they exist) at the given helix and base offset.
        """
        for substrand in self._helix_substrand_map[helix_idx]:
            if substrand.contains_offset(offset):
                substrand.deletions.append(offset)

    def assign_dna(self, strand, sequence):
        """
        Assigns `sequence` as DNA sequence of `strand`.


        If any :class:`scadnano.Strand` is bound to `strand`,
        it is assigned the reverse Watson-Crick complement of the relevant portion,
        and any remaining portions
        of the other strand are assigned to be the symbol ``?``.

        Before assigning, `sequence` is first forced to be the same length as `strand` as follows:
        If `sequence` is longer, it is truncated.
        If `sequence` is shorter, it is padded with ``?``'s.
        """

        if len(sequence) > len(strand):
            sequence = sequence[:len(strand)]
        elif len(sequence) < len(strand):
            sequence += '?' * (len(strand) - len(sequence))
        strand.dna_sequence = sequence

        for other_strand in self.strands:
            if strand == other_strand:
                continue
            if other_strand.overlaps(strand):
                other_strand.assign_dna_complement_from(strand)


# def _read_m13():
#     with open('M13_seq_from5588.txt', 'r') as infile:
#         seq = infile.read().strip()
#     return seq


if __name__ == "__main__":
    pass
