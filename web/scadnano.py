"""
Scripting library for scadnano. Used to write python scripts outputting ``*.dna`` files readable
by `scadnano <https://web.cs.ucdavis.edu/~doty/scadnano/>`_.
"""

import enum
import re
from dataclasses import dataclass, field
from typing import Tuple, List, Dict
from collections import defaultdict, OrderedDict
import sys
import os.path

from json_utils import JSONSerializable, json_encode, NoIndent
import m13


# TODO: make explicit rules about when strands can be added and sequences assigned.
#  For instance, if we add a strand to overlap one that already has a DNA sequence sequence assigned,
#  should the complement be automatically assigned?

# TODO: add support for writing 3D positions (in addition to 2D svg_positions)

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

    def to_json_serializable(self, suppress_indent=True):
        # Return object representing this Color that is JSON serializable.
        return NoIndent(self.__dict__) if suppress_indent else self.__dict__


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

    honeycomb = "honeycomb"
    """Honeycomb lattice."""

    none = "none"
    """No fixed grid."""


# convenience names for users
left = False
forward = True
square = Grid.square
hexagonal = Grid.hex  # should not use identifier "hex" because that's a Python built-in function
honeycomb = Grid.honeycomb

##########################################################################
# constants

current_version: str = "0.0.1"

default_idt_scale = "25nm"
default_idt_purification = "STD"


def default_major_tick_distance(grid: Grid) -> int:
    return 7 if grid in (Grid.hex, Grid.honeycomb) else 8


default_grid: Grid = Grid.none

base_width_svg: float = 10.0
"""Width of a single base in the SVG main view of scadnano."""

base_height_svg: float = 10.0
"""Height of a single base in the SVG main view of scadnano."""

distance_between_helices_svg: float = (base_width_svg * 2.5 / 0.34)
"""Distance between tops of two consecutive helices (using default positioning rules).

This is set to (:const:`base_width_svg` * 2.5/0.34) based on the following calculation,
to attempt to make the DNA appear to scale in 2D drawings:
The width of one base pair of double-stranded DNA bp is 0.34 nm.
In a DNA origami, AFM images estimate that the average distance between adjacent double helices is 2.5 nm.
(A DNA double-helix is only 2 nm wide, but the helices electrostatically repel each other so the spacing
in a DNA origami or an other DNA nanostructure with many parallel DNA helices---e.g., single-stranded tile
lattices---is larger than 2 nm.)
Thus the distance between the helices is 2.5/0.34 ~ 7.5 times the width of a single DNA base.
"""

DNA_base_wildcard: str = '?'
"""Symbol to insert when a DNA sequence has been assigned to a strand through complementarity, but
some regions of the strand are not bound to the strand that was just assigned. Also used in case the
DNA sequence assigned to a strand is too short; the sequence is padded with :any:`DNA_base_wildcard` to 
make its length the same as the length of the strand."""

m13_sequence = m13.sequence
"""
The M13mp18 DNA sequence, starting from cyclic rotation 5588, as defined in
`GenBank <https://www.neb.com/~/media/NebUs/Page%20Images/Tools%20and%20Resources/Interactive%20Tools/DNA%20Sequences%20and%20Maps/Text%20Documents/m13mp18gbk.txt>`_.
"""  # noqa (suppress PEP warning)

##################
# keys

# DNADesign keys
version_key = 'version'
grid_key = 'grid'
major_tick_distance_key = 'major_tick_distance'
major_ticks_key = 'major_ticks'
helices_key = 'helices'
strands_key = 'strands'

# Helix keys
idx_key = 'idx'
max_bases_key = 'max_bases'
grid_position_key = 'grid_position'
svg_position_key = 'svg_position'
# position_key = 'position'; # support in the future

# Strand keys
color_key = 'color'
dna_sequence_key = 'dna_sequence'
substrands_key = 'substrands'
idt_key = 'idt'

# Substrand keys
helix_idx_key = 'helix_idx'
forward_key = 'forward'
start_key = 'start'
end_key = 'end'
deletions_key = 'deletions'
insertions_key = 'insertions'


# end keys
##################

# end constants
##########################################################################


def in_browser() -> bool:
    """Test if this code is running in the browser.

    Checks for existence of package "pyodide" used in pyodide. If present it is assumed the code is
    running in the browser."""
    try:
        import pyodide
        return True
    except ModuleNotFoundError:
        return False


@dataclass
class Helix(JSONSerializable):
    idx: int
    """ idx: Index of helix (used helices must be given indices 0..num_helices-1, 
    unused helices must be given a negative index). """

    max_bases: int = -1
    """Maximum length of :any:`Substrand` that can be drawn on this :any:`Helix`. If unspecified,
    it is calculated when the :any:`DNADesign` is instantiated as the largest :any:`Substrand.end`
    index of any :any:`Substrand` in the design."""

    major_tick_distance: int = -1
    """If positive, overrides :any:`DNADesign.major_tick_distance`."""

    major_ticks: List[int] = None
    """If not None, overrides :any:`DNADesign.major_tick_distance` and :any:`Helix.major_tick_distance`
    to specify a list of offsets at which to put major ticks."""

    grid_position: Tuple[int, int, int] = None
    """`(h,v,b)` position of this helix in the side view grid,
    if :const:`Grid.square`, :const:`Grid.hex` , or :const:`Grid.honeycomb` is used
    in the :any:`DNADesign` containing this helix.
    `h` and `v` are in units of "helices": incrementing `h` moves right one helix in the grid
    and incrementing `v` moves down one helix in the grid. (down and to the left in the case of
    the hexagonal or honeycomb lattice)
    `b` goes in and out of the screen in the side view, and it is in units of "bases".
    Incrementing `b` moves the whole helix one base into the screen.
    In the main view, a helix with `b` = 1 would have its base offset 0 line up with base offset 1
    of a helix with `b` = 0.
    However, the default y svg_position for helices does not otherwise depend on grid_position.
    The default is to list the y-coordinates in order by helix idx.
    
    Default is `h` = 0, `v` = :any:`Helix.idx`, `b` = 0."""

    svg_position: Tuple[float, float] = None
    """`(x,y)` SVG coordinates of base offset 0 of this Helix in the main view. 
    
    If `grid_position` and `position` are both omitted, then the default is 
    `x` = 0, `y` = :any:`Helix.idx` * :any:`scadnano.distance_between_helices_svg`.
    
    If `grid_position = (h,v,b)` is specified but `position` is omitted, then the default is
    `x` = b * BASE_WIDTH_SVG, `y` = :any:`Helix.idx` * :any:`scadnano.distance_between_helices_svg`."""

    @property
    def used(self):
        """If ``False``, this helix has :any:`Helix.idx` = ``None`` and appears only in the side view,
        not the main view. If ``True``, it appears in the main view and has a positive integer value
        for :any:`Helix.idx`, though it may not actually have any :any:`Substrand`'s on it."""
        return self.idx >= 0

    def to_json_serializable(self, suppress_indent=True):
        dct = self.__dict__

        if self.major_tick_distance <= 0:
            del dct[major_tick_distance_key]

        if self.major_ticks is None:
            del dct[major_ticks_key]

        # print(f'self.svg_position()    = {self.svg_position}')
        # print(f'default_svg_position() = {self.default_svg_position()}')
        default_x, default_y = self.default_svg_position()
        if _is_close(self.svg_position[0], default_x) and _is_close(self.svg_position[1], default_y):
            del dct[svg_position_key]

        if self.grid_position[2] == 0:  # don't bother writing grid position base coordinate if it is 0
            dct[grid_position_key] = (self.grid_position[0], self.grid_position[1])

        return NoIndent(dct) if suppress_indent else dct

    def __post_init__(self):
        if self.grid_position is None:
            # default to same x-coordinate 0, and y-coordinate = idx
            self.grid_position = (0, self.idx, 0)
        if self.svg_position is None:
            # default to same x- and z-coordinates 0, and y-coordinate scales with idx
            self.svg_position = self.default_svg_position()
        if self.major_ticks is not None:
            for major_tick in self.major_ticks:
                if major_tick > self.max_bases:
                    raise IllegalDNADesignError(f'major tick {major_tick} in list {self.major_ticks} is '
                                                f'outside the range of available offsets since max_bases = '
                                                f'{self.max_bases}')

    def default_svg_position(self):
        return 0, self.idx * distance_between_helices_svg


def _is_close(x1: float, x2: float):
    return abs(x1 - x2) < 0.00000001


@dataclass
class Substrand(JSONSerializable):
    """
    A maximal portion of a :any:`Strand` that is continguous on a single :any:`Helix`.
    A :any:`Strand` contains a list of :any:`Substrand`'s.
    """

    helix_idx: int
    """:any:`Helix.idx` of the :any:`Helix` where this Substrand resides."""

    forward: bool
    """Whether the strand "points" forward (i.e., its 3' end has a larger offset than its 5' end)."""

    start: int
    """
    The smallest offset position of any base on this Substrand
    (3' end if :any:`Substrand.forward` = ``False``,
    5' end if :any:`Substrand.forward` = ``True``).
    """

    # TODO: give option to user in constructor to specify that end is inclusive (default exclusive)
    end: int
    """
    1 plus the largest offset position of any base on this Substrand
    (5' end if :any:`Substrand.forward` = ``False``,
    3' end if :any:`Substrand.forward` = ``True``).
    Note that the set of base offsets occupied by this Substrand is {start, start+1, ..., end-1},
    the same convention used in Python for slices of lists and strings.
    (e.g., :samp:`"abcdef"[1:3] == "bc"`)
    """

    deletions: List[int] = field(default_factory=list)
    """List of positions of deletions on this Substrand."""

    insertions: List[Tuple[int, int]] = field(default_factory=list)
    """List of (position,num_insertions) pairs on this Substrand."""

    # not serialized; for efficiency
    _parent_strand: 'Strand' = field(init=False, repr=False, compare=False, default=None)

    def __post_init__(self):
        self._check_start_end()

    def __repr__(self):
        rep = f'Substrand(helix_idx={self.helix_idx}' \
              f', dir={"right" if self.forward else "left"}' \
              f', start={self.start}' \
              f', end={self.end}' \
              '' if len(self.deletions) == 0 else f', deletions={self.deletions}' \
              '' if len(self.insertions) == 0 else f', insertions={self.insertions}' \
              ')'
        return rep

    def __str__(self):
        return repr(self)

    def _check_start_end(self):
        if self.start >= self.end:
            raise IllegalDNADesignError(f'start = {self.start} must be less than end = {self.end}')

    def to_json_serializable(self, suppress_indent=True):
        dct = OrderedDict()
        dct[helix_idx_key] = self.helix_idx
        dct[forward_key] = self.forward
        dct[start_key] = self.start
        dct[end_key] = self.end
        if len(self.deletions) > 0:
            dct[deletions_key] = self.deletions
        if len(self.insertions) > 0:
            dct[insertions_key] = self.insertions
        return NoIndent(dct) if suppress_indent else dct

    def set_start(self, new_start: int):
        self.start = new_start
        self._check_start_end()

    def set_end(self, new_end: int):
        self.end = new_end
        self._check_start_end()

    def offset_5p(self) -> int:
        if self.forward:
            return self.start
        else:
            return self.end - 1
        # return self.start if self.forward else self.end - 1

    def offset_3p(self) -> int:
        return self.end - 1 if self.forward else self.start

    def _num_insertions(self) -> int:
        # total number of insertions in this Substrand
        return sum(insertion[1] for insertion in self.insertions)

    def contains_offset(self, offset: int) -> bool:
        """Indicates if `offset` is the offset of a base on this substrand.

        Note that offsets refer to visual portions of the displayed grid for the Helix.
        If for example, this Substrand starts at position 0 and ends at 10, and it has 5 deletions,
        then it contains the offset 7 even though there is no base 7 positions from the start."""
        return self.start <= offset < self.end

    def dna_length(self) -> int:
        """Number of bases in this Substrand."""
        return self.end - self.start - len(self.deletions) + self._num_insertions()

    def dna_length_in(self, left, right) -> int:
        """Number of bases in this Substrand between left and right (INCLUSIVE)."""
        if not left <= right + 1:
            raise ValueError(f'left = {left} and right = {right} but we should have left <= right + 1')
        if not self.start <= left:
            raise ValueError(f'left = {left} should be at least self.start = {self.start}')
        if not right < self.end:
            raise ValueError(f'right = {right} should be at most self.end - 1 = {self.end - 1}')
        num_deletions = sum(1 for offset in self.deletions if left <= offset <= right)
        num_insertions = sum(length for (offset, length) in self.insertions if left <= offset <= right)
        return (right - left + 1) - num_deletions + num_insertions

    def visual_length(self) -> int:
        """Distance between left offset and right offset.

        This can be more or less than the :meth:`Substrand.dna_length` due to insertions and deletions."""
        return self.end - self.start

    def dna_sequence(self) -> str:
        """Return DNA sequence of this Substrand."""
        return self.dna_sequence_in(self.start, self.end - 1)

    def dna_sequence_in(self, offset_left: int, offset_right: int) -> str:
        """Return DNA sequence of this Substrand in the interval of offsets given by
        [`left`, `right`], INCLUSIVE.

        WARNING: This is inclusive on both ends,
        unlike other parts of this API where the right endpoint is exclusive.
        This is to make the notion well-defined when one of the endpoints is on an offset with a
        deletion or insertion."""
        strand_seq = self._parent_strand.dna_sequence
        if strand_seq is None:
            return None

        # if on a deletion, move inward until we are off of it
        while offset_left in self.deletions:
            offset_left += 1
        while offset_right in self.deletions:
            offset_right -= 1

        if offset_left > offset_right:
            return ''
        if offset_left >= self.end:
            return ''
        if offset_right < 0:
            return ''

        str_idx_left = self.offset_to_str_idx(offset_left, self.forward)
        str_idx_right = self.offset_to_str_idx(offset_right, not self.forward)
        if not self.forward:  # these will be out of order if strand is left
            str_idx_left, str_idx_right = str_idx_right, str_idx_left
        subseq = strand_seq[str_idx_left:str_idx_right + 1]
        return subseq

    def get_seq_start_idx(self) -> int:
        """Starting DNA subsequence index for first base of this :any:`Substrand` on its
        Parent :any:`Strand`'s DNA sequence."""
        substrands = self._parent_strand.substrands
        # index of self in parent strand's list of substrands
        self_substrand_idx = substrands.index(self)
        # index of self's position within the DNA sequence of parent strand
        self_seq_idx_start = sum(prev_substrand.dna_length()
                                 for prev_substrand in substrands[:self_substrand_idx])
        return self_seq_idx_start

    def offset_to_str_idx(self, offset: int, offset_closer_to_5p: bool) -> int:
        """ Convert from offset on this :any:`Substrand`'s :any:`Helix`
        to string index on the parent :any:`Strand`'s DNA sequence.

        If `offset_closer_to_5p` is ``True``, (this only matters if `offset` contains an insertion)
        then the only leftmost string index corresponding to this offset is included,
        otherwise up to the rightmost string index (including all insertions) is included."""
        if offset in self.deletions:
            raise ValueError(f'offset {offset} illegally contains a deletion from {self.deletions}')

        # length adjustment for insertions depends on whether this is a left or right offset
        len_adjust = self._net_ins_del_length_increase_from_5p_to(offset, offset_closer_to_5p)

        # get string index assuming this Substrand is first on Strand
        if self.forward:
            offset += len_adjust  # account for insertions and deletions
            ss_str_idx = offset - self.start
        else:
            # account for insertions and deletions
            offset -= len_adjust  # account for insertions and deletions
            ss_str_idx = self.end - 1 - offset

        # correct for existence of previous Substrands on this Strand
        return ss_str_idx + self.get_seq_start_idx()

    def _net_ins_del_length_increase_from_5p_to(self, offset_edge: int, offset_closer_to_5p: bool) -> int:
        """Net number of insertions from 5'/3' end to offset_edge,
        INCLUSIVE on 5'/3' end, EXCLUSIVE on offset_edge.

        Set `five_p` ``= False`` to test from 3' end to `offset_edge`."""
        length_increase = 0
        for deletion in self.deletions:
            if self._between_5p_and_offset(deletion, offset_edge):
                length_increase -= 1
        for (insertion_offset, insertion_length) in self.insertions:
            if self._between_5p_and_offset(insertion_offset, offset_edge):
                length_increase += insertion_length
        # special case for when offset_edge is an endpoint closer to the 3' end,
        # we add its extra insertions also in this case
        if not offset_closer_to_5p:
            insertion_map: Dict[int, int] = dict(self.insertions)
            if offset_edge in insertion_map:
                insertion_length = insertion_map[offset_edge]
                length_increase += insertion_length
        return length_increase

    def _between_5p_and_offset(self, offset_to_test: int, offset_edge: int) -> bool:
        return ((self.forward and self.start <= offset_to_test < offset_edge) or
                (not self.forward and offset_edge < offset_to_test < self.end))

    # def _between_3p_and_offset(self, offset_to_test: int, offset_edge: int) -> bool:
    #     return ((self.direction == Direction.left and self.start <= offset_to_test < offset_edge) or
    #             (self.direction == Direction.forward and offset_edge < offset_to_test < self.end))

    # The type hint 'Substrand' must be in quotes since Substrand is not yet defined.
    # This is a "forward reference": https://www.python.org/dev/peps/pep-0484/#forward-references
    def overlaps(self, other: 'Substrand') -> bool:
        r"""Indicates if this substrand's set of offsets (the set
        :math:`\{x \in \mathbb{N} \mid`
        ``self.start``
        :math:`\leq x \leq`
        ``self.end``
        :math:`\}`)
        has nonempty intersection with those of `other`,
        and they appear on the same helix,
        and they point in opposite directions."""  # noqa (suppress PEP warning)
        return (self.helix_idx == other.helix_idx and
                self.forward == (not other.forward) and
                self.compute_overlap(other)[0] >= 0)

    def overlaps_illegally(self, other: 'Substrand'):
        r"""Indicates if this substrand's set of offsets (the set
        :math:`\{x \in \mathbb{N} \mid`
        ``self.start``
        :math:`\leq x \leq`
        ``self.end``
        :math:`\}`)
        has nonempty intersection with those of `other`,
        and they appear on the same helix,
        and they point in the same direction."""  # noqa (suppress PEP warning)
        return (self.helix_idx == other.helix_idx and
                self.forward == other.forward and
                self.compute_overlap(other)[0] >= 0)

    def compute_overlap(self, other: 'Substrand') -> Tuple[int, int]:
        """Return [left,right) offset indicating overlap between this Substrand and `other`.

        Return ``(-1,-1)`` if they do not overlap (different helices, or non-overlapping regions
        of the same helix)."""
        overlap_start = max(self.start, other.start)
        overlap_end = min(self.end, other.end)
        if overlap_start >= overlap_end:  # overlap is empty
            return -1, -1
        return overlap_start, overlap_end

    def insertion_offsets(self) -> List[Tuple[int, int]]:
        """Return offsets of insertions (but not their lengths)."""
        return [ins_off for (ins_off, _) in self.insertions]


_wctable = str.maketrans('ACGTacgt', 'TGCAtgca')


def wc(seq: str) -> str:
    """Return reverse Watson-Crick complement of seq"""
    return seq.translate(_wctable)[::-1]


# TODO: print set of strands with unique names (but give error if two different strands with the same
#  name have different sequences, and give warning even if the have the same sequence)

@dataclass
class IDTFields(JSONSerializable):
    name: str
    """Name of the strand (first field in IDT bulk input).
    Non-optional field."""

    scale: str = default_idt_scale
    """Synthesis scale at which to synthesize the strand (second field in IDT bulk input).
    Choices supplied by IDT at the time this was written: 
    ``"25nm"``, ``"100nm"``, ``"250nm"``, ``"1um"``, ``"5um"``, ``"10um"``, ``"4nmU"``, ``"20nmU"``, 
    ``"PU"``, ``"25nmS"``.
    Optional field.
    """

    purification: str = default_idt_purification
    """Purification options. 
    Choices supplied by IDT at the time this was written: 
    ``"STD"``, ``"PAGE"``, ``"HPLC"``, ``"IEHPLC"``, ``"RNASE"``, ``"DUALHPLC"``, ``"PAGEHPLC"``.
    Optional field.
    """

    def __post_init__(self):
        _check_idt_string_not_none_or_empty(self.name, 'name')
        _check_idt_string_not_none_or_empty(self.scale, 'scale')
        _check_idt_string_not_none_or_empty(self.purification, 'purification')

    def to_json_serializable(self, suppress_indent=True):
        dct = self.__dict__
        return NoIndent(dct)


def _check_idt_string_not_none_or_empty(value: str, field_name: str):
    if value is None:
        raise IllegalDNADesignError(f'field {field_name} in IDTFields cannot be None')
    if len(value) == 0:
        raise IllegalDNADesignError(f'field {field_name} in IDTFields cannot be empty')


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

        scaffold_substrands = [ ... ]
        scaffold_strand = sc.Strand(substrands=scaffold_substrands, color=sc.default_scaffold_color)
    """

    substrands: List[Substrand]
    """:any:`Substrand`'s composing this Strand. Each is contiguous on a single helix."""

    # is_scaffold: bool = False
    # """For DNA origami designs, designating one (or more) strands as "scaffold" enables
    # some custom behavior (e.g., scaffold color is always the same)."""

    dna_sequence: str = None
    """Do not assign directly to this field. Always use :any:`DNADesign.assign_dna` 
    (for complementarity checking) or :any:`Strand.set_dna_sequence` (to allow mismatches)."""

    color: Color = None
    """Color to show this strand in the main view. If not specified in the constructor,
    a color is assigned by cycling through a list of defaults given by 
    :meth:`ColorCycler.colors`"""

    automatically_assign_color: bool = field(repr=False, default=True)
    """If `automatically_assign_color` = ``False`` and `color` = ``None``, do not automatically
    assign a :any:`Color` to this Strand. (So color will be set to its default None and will not be
    written to the JSON with :any:`DNADesign.write_scadnano_file` or :any:`DNADesign.to_json`."""

    idt: IDTFields = None
    """Fields used when ordering strands from the synthesis company IDT 
    (Integrated DNA Technologies, Coralville, IA). If present (i.e., not equal to :const:`None`)
    then the method :meth:`DNADesign.generate_idt_bulk_input_file` can be called to automatically
    generate an IDT file for ordering strands: https://eu.idtdna.com/site/order/oligoentry"""

    # not serialized; efficient way to see a list of all substrands on a given helix
    _helix_idx_substrand_map: Dict[int, List[Substrand]] = field(
        init=False, repr=False, compare=False, default=None)

    def to_json_serializable(self, suppress_indent=True):
        dct = OrderedDict()
        if self.color is not None:
            dct[color_key] = self.color.to_json_serializable(suppress_indent)
        if self.dna_sequence is not None:
            dct[dna_sequence_key] = self.dna_sequence
        if self.idt is not None:
            dct[idt_key] = self.idt.to_json_serializable(suppress_indent)
        dct[substrands_key] = [substrand.to_json_serializable(suppress_indent) for substrand in
                               self.substrands]
        return dct

    def __post_init__(self):
        # if color not specified, pick one by cycling through list of staple colors,
        # unless caller specified not to
        global color_cycler
        if self.color is None and self.automatically_assign_color:
            self.color = next(color_cycler)
        self._helix_idx_substrand_map = defaultdict(list)
        for substrand in self.substrands:
            self._helix_idx_substrand_map[substrand.helix_idx].append(substrand)
        for substrand in self.substrands:
            substrand._parent_strand = self

    def first_substrand(self):
        return self.substrands[0]

    def last_substrand(self):
        return self.substrands[-1]

    def set_dna_sequence(self, sequence: str):
        """Sets this Strand's DNA sequence to `seq` WITHOUT checking for complementarity with overlapping
        Strands or automatically assigning their sequences. To assign a sequence to a Strand and have
        the overlapping Strands automatically have the appropriate Watson-Crick complements assigned,
        use :any:`DNADesign.assign_dna`.

        All whitespace in `sequence` is removed,
        and lowercase bases 'a', 'c', 'g', 't' are converted to uppercase.

        `sequence`, after all whitespace is removed, must be exactly the same length as ``self.dna_length``.
        Wildcard symbols (:const:`DNA_case_wildcard`) are allowed to leave part of the DNA unassigned.
        """
        trimmed_seq = _remove_whitespace_and_uppercase(sequence)
        if len(trimmed_seq) != self.dna_length():
            ss = self.first_substrand()
            raise IllegalDNADesignError(f"strand starting at helix {ss.helix_idx} offset {ss.offset_5p()} "
                                        f"has length {self.dna_length()}, but you attempted to assign a "
                                        f"DNA sequence of length {len(trimmed_seq)}: {sequence}")
        self.dna_sequence = trimmed_seq

    def dna_length(self):
        """Return sum of DNA length of Substrands of this Strand."""
        acc = 0
        for substrand in self.substrands:
            acc += substrand.dna_length()
        return acc
        # return sum(len(substrand) for substrand in self.substrands)

    def offset_5p(self):
        return self.first_substrand().offset_5p()

    def offset_3p(self):
        return self.last_substrand().offset_3p()

    def overlaps(self, other: 'Strand'):
        """Indicates whether `self` overlaps `other_strand`, meaning that the set of offsets occupied
        by `self` has nonempty intersection with those occupied by `other_strand`."""
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
        to be assigned via this method. However, it is permitted to assign this field directly
        (for instance, to assign a DNA sequence to a strand that is not bound to any strand
        that is not already assigned a sequence where they overlap). In this case no error checking
        about sequence complementarity is done. Thus this can be used to intentionally assign mismatching
        DNA strands that are overlapping on a Helix."""

        # put DNA sequences to assign to substrands in List, one position per substrand
        strand_complement_builder = []

        for substrand_self in self.substrands:
            helix_idx = substrand_self.helix_idx

            # for helix_idx, substrands_on_helix_self in self._helix_idx_substrand_map.items():
            substrands_on_helix_other = other._helix_idx_substrand_map[helix_idx]
            # for substrand_self in substrands_on_helix_self:
            overlaps = []
            for substrand_other in substrands_on_helix_other:
                if substrand_self.overlaps(substrand_other):
                    overlap = substrand_self.compute_overlap(substrand_other)
                    overlaps.append((overlap, substrand_other))

            overlaps.sort()

            substrand_complement_builder = []
            start_idx = substrand_self.start
            # repeatedly insert wildcards into gaps, then reverse WC complement
            for ((overlap_left, overlap_right), substrand_other) in overlaps:
                # wildcards = DNA_base_wildcard * (overlap_left - start_idx)
                num_wildcard_bases = substrand_self.dna_length_in(start_idx, overlap_left - 1)
                wildcards = DNA_base_wildcard * num_wildcard_bases

                other_seq = substrand_other.dna_sequence_in(overlap_left, overlap_right - 1)
                overlap_complement = wc(other_seq)
                substrand_complement_builder.append(wildcards)
                substrand_complement_builder.append(overlap_complement)
                start_idx = overlap_right

            # last wildcard for gap between last overlap and end
            # last_wildcards = DNA_base_wildcard * (substrand_self.end - start_idx)
            num_wildcard_bases = substrand_self.dna_length_in(start_idx, substrand_self.end - 1)
            last_wildcards = DNA_base_wildcard * num_wildcard_bases

            substrand_complement_builder.append(last_wildcards)

            # If pointing left, each individual overlap sequence was reverse orientation in wc(),
            # but not the list of all of them put together until now.
            if not substrand_self.forward:
                substrand_complement_builder.reverse()

            substrand_self_dna_sequence = ''.join(substrand_complement_builder)
            strand_complement_builder.append(substrand_self_dna_sequence)

        strand_complement = ''.join(strand_complement_builder)
        new_dna_sequence = strand_complement
        if self.dna_sequence is not None:
            try:
                new_dna_sequence = _string_merge_wildcard(self.dna_sequence, new_dna_sequence,
                                                          DNA_base_wildcard)
            except ValueError as err:
                ss_self = self.first_substrand()
                ss_other = other.first_substrand()
                msg = f'strand starting at helix {ss_self.helix_idx}, offset {ss_self.offset_5p()} has ' \
                      f'length ' \
                      f'{self.dna_length()} and already has a partial DNA sequence assignment of length ' \
                      f'{len(self.dna_sequence)}, which is \n' \
                      f'{self.dna_sequence}, ' \
                      f'but you tried to assign sequence of length {len(new_dna_sequence)} to it, which ' \
                      f'is\n{new_dna_sequence} (this assignment was indirect, since you assigned directly ' \
                      f'to a strand bound to this one). This occurred while directly assigning a DNA ' \
                      f'sequence to the strand whose 5\' end is at helix {ss_other.helix_idx}, and is of ' \
                      f'length {other.dna_length()}.'
                raise IllegalDNADesignError(msg)

        self.set_dna_sequence(new_dna_sequence)
        # self.dna_sequence = _pad_dna(new_dna_sequence, self.dna_length())

    def _insert_substrand(self, order, substrand):
        """Only intended to be called by DNADesign.insert_substrand"""
        self.substrands.insert(order, substrand)
        substrand._parent_strand = self
        self._helix_idx_substrand_map[substrand.helix_idx].append(substrand)

    def _remove_substrand(self, substrand):
        """Only intended to be called by DNADesign.remove_substrand"""
        self.substrands.remove(substrand)
        substrand._parent_strand = None
        self._helix_idx_substrand_map[substrand.helix_idx].remove(substrand)


def _string_merge_wildcard(s1: str, s2: str, wildcard: str) -> str:
    """Takes a "union" of two equal-length strings `s1` and `s2`.
    Whenever one has a symbol `wildcard` and the other does not, the result has the non-wildcard symbol.

    Raises :py:class:`ValueError` if `s1` and `s2` are not the same length or do not agree on non-wildcard
    symbols at any position."""
    if len(s1) != len(s2):
        raise ValueError(f'\ns1={s1} and\ns2={s2}\nare not the same length.')
    union_builder = []
    for i in range(len(s1)):
        c1, c2 = s1[i], s2[i]
        if c1 == wildcard:
            union_builder.append(c2)
        elif c2 == wildcard:
            union_builder.append(c1)
        elif c1 != c2:
            raise ValueError(f's1={s1} and s2={s2} have unequal symbols {c1} and {c2} at position {i}.')
        elif c1 == c2:
            union_builder.append(c1)
        else:
            raise AssertionError('should be unreachable')
    return ''.join(union_builder)


class IllegalDNADesignError(ValueError):
    """Indicates that some aspect of the DNADesign object is illegal."""


# TODO: add mutation operations to DNADesign to mutate all of its parts:
#  - Helix
#    - idx
#    - max_bases
#    - major_ticks (possibly as part of a deletion on strands that actually deletes the whole offset)
#    - svg_position (can help with importing cadnano designs that display poorly with default positions)
#  - Substrand
#    - helix_idx
#    - right
#    - start
#    - end
#  - Strand
#    - unassign DNA sequence
#  - DNADesign
#    - add Helix
#    - remove Helix


@dataclass
class DNADesign(JSONSerializable):
    """Object representing the entire design of the DNA structure."""

    helices: List[Helix]
    """All of the helices in this DNADesign."""

    strands: List[Strand]
    """All of the strands in this DNADesign."""

    grid: Grid = Grid.none
    """Common choices for how to arrange helices relative to each other."""

    major_tick_distance: int = -1
    """Distance between major ticks (bold) delimiting boundaries between bases.
    
    Default value is 8 unless overridden by the grid type.
    If 0 then no major ticks are drawn.
    If negative then the default value is assumed, but `major_tick_distance` is not stored in the JSON file
    when serialized.
    If :any:`DNADesign.grid` = :any:`Grid.square` then the default value is 8.
    If :any:`DNADesign.grid` = :any:`Grid.hex` or :any:`Grid.honeycomb` then the default value is 7."""

    # for optimization; maps helix index to list of substrands on that Helix
    _helix_substrand_map: Dict[int, List[Substrand]] = None

    def __post_init__(self):
        if self.major_tick_distance < 0:
            self.major_tick_distance = default_major_tick_distance(self.grid)
        self._build_helix_substrand_map()
        self._check_legal_design()

    def to_json_serializable(self, suppress_indent=True):
        dct = OrderedDict()
        dct[version_key] = current_version
        if self.grid != default_grid:
            dct[grid_key] = str(self.grid)[5:]  # remove prefix 'Grid.'
        if self.major_tick_distance >= 0 and (
                self.major_tick_distance != default_major_tick_distance(self.grid)):
            dct[major_tick_distance_key] = self.major_tick_distance
        dct[helices_key] = [helix.to_json_serializable(suppress_indent) for helix in self.helices]
        dct[strands_key] = [strand.to_json_serializable(suppress_indent) for strand in self.strands]
        return dct

    def strands_starting_on_helix(self, helix_idx: int):
        """Return list of Strands that start (have their 5' end) on helix with index `helix_idx`."""
        return [strand for strand in self.strands if strand.substrands[0].helix_idx == helix_idx]

    def strands_ending_on_helix(self, helix_idx: int):
        """Return list of Strands that end (have their 3' end) on helix with index `helix_idx`."""
        return [strand for strand in self.strands if strand.substrands[-1].helix_idx == helix_idx]

    def used_helices(self):
        """Return list of all helices that are used."""
        return [helix for helix in self.helices if helix.used]

    def _check_legal_design(self):
        self._check_helix_indices()
        self._check_strands_reference_legal_helices()
        self._check_strands_overlap_legally()

    def _check_helix_indices(self):
        # ensure if there are H helices, the list of sorted indices is 0,1,...,H-1
        indices_helices = sorted([(helix.idx, helix) for helix in self.helices],
                                 key=lambda x: x[0])
        for (correct_idx, (helix_idx, helix)) in enumerate(indices_helices):
            if correct_idx != helix_idx:
                if correct_idx < helix_idx:
                    err_msg = f"missing Helix with helix_idx {correct_idx}"
                else:
                    err_msg = f"duplicate Helices with helix_idx {helix_idx}"
                raise IllegalDNADesignError(err_msg)

    def _check_strands_overlap_legally(self, substrand_to_check: Substrand = None):
        """If `substrand_to_check` is None, check all.
        Otherwise only check pairs where one is substrand_to_check."""

        def err_msg(substrand1, substrand2, h_idx):
            return f"two substrands overlap on helix {h_idx}: " \
                   f"\n{substrand1}\n  and\n{substrand2}\n  but have the same direction"

        # ensure that if two strands overlap on the same helix,
        # they point in opposite directions
        for helix_idx, substrands in self._helix_substrand_map.items():
            if substrand_to_check is not None and substrand_to_check.helix_idx != helix_idx:
                # TODO: if necessary, we can be more efficient by only checking this one substrand
                continue
            if len(substrands) == 0:
                continue

            # check all consecutive substrands on the same helix, sorted by start/end indices
            offsets_data = []
            for substrand in substrands:
                offsets_data.append((substrand.start, True, substrand))
                offsets_data.append((substrand.end, False, substrand))
            offsets_data.sort(key=lambda offset_data: offset_data[0])

            current_substrands: List[Substrand] = []
            for offset, is_start, substrand in offsets_data:
                if is_start:
                    if len(current_substrands) >= 2:
                        if offset >= current_substrands[1].end:
                            del current_substrands[1]
                    if len(current_substrands) >= 1:
                        if offset >= current_substrands[0].end:
                            del current_substrands[0]
                    current_substrands.append(substrand)
                    if len(current_substrands) > 2:
                        ss0, ss1, ss2 = current_substrands[0:3]
                        for s_first, s_second in [(ss0, ss1), (ss1, ss2), (ss0, ss2)]:
                            if s_first.forward == s_second.forward:
                                raise IllegalDNADesignError(err_msg(s_first, s_second, helix_idx))
                        raise AssertionError(
                            f"since current_substrands = {current_substrands} has at least three substrands, "
                            f"I expected to find a pair of illegally overlapping substrands")
                    elif len(current_substrands) == 2:
                        s_first, s_second = current_substrands
                        if s_first.forward == s_second.forward:
                            raise IllegalDNADesignError(err_msg(s_first, s_second, helix_idx))

    def _check_strands_reference_legal_helices(self):
        # ensure each strand refers to an existing helix
        helix_idxs_set = set(helix.idx for helix in self.helices)
        for strand in self.strands:
            self._check_strand_references_legal_helices(helix_idxs_set, strand)

    def _check_strand_references_legal_helices(self, helix_idxs_set, strand):
        for substrand in strand.substrands:
            self._check_substrand_references_legal_helix(helix_idxs_set, substrand)

    def _check_substrand_references_legal_helix(self, helix_idxs_set, substrand):
        if substrand.helix_idx not in helix_idxs_set:
            err_msg = f"substrand {substrand} refers to nonexistent Helix index {substrand.helix_idx}"
            raise IllegalDNADesignError(err_msg)

    def substrands_at(self, helix_idx, offset):
        """Return list of substrands that overlap `offset` on helix with idx `helix_idx`.

        If constructed properly, this list should have 0, 1, or 2 elements."""
        substrands_on_helix = self._helix_substrand_map[helix_idx]
        # TODO: replace this with a faster algorithm using binary search
        substrands_on_helix = [substrand for substrand in substrands_on_helix if
                               substrand.contains_offset(offset)]
        if len(substrands_on_helix) not in [0, 1, 2]:
            raise AssertionError(f'There should be at most 2 substrands on helix {helix_idx}, '
                                 f'but there are {len(substrands_on_helix)}:\n{substrands_on_helix}')
        return substrands_on_helix

    # TODO: add_strand and insert_substrand should check for existing deletions/insertion parallel strands
    def add_strand(self, strand: Strand):
        """Add `strand` to this design."""
        helix_idxs_set = set(helix.idx for helix in self.helices)
        self._check_strand_references_legal_helices(helix_idxs_set, strand)
        self.strands.append(strand)
        for substrand in strand.substrands:
            self._helix_substrand_map[substrand.helix_idx].append(substrand)

    def remove_strand(self, strand: Strand):
        """Add `strand` to this design."""
        self.strands.remove(strand)
        for substrand in strand.substrands:
            self._helix_substrand_map[substrand.helix_idx].remove(substrand)

    def insert_substrand(self, strand: Strand, order: int, substrand: Substrand):
        """Insert `substrand` into `strand` at index given by `order`. Uses same indexing as Python lists,
        e.g., ``strand.insert_substrand(ss, 0)`` inserts ``ss`` as the new first substrand."""
        assert strand in self.strands
        strand._insert_substrand(order, substrand)
        helix_idxs_set = set(helix.idx for helix in self.helices)
        self._check_strand_references_legal_helices(helix_idxs_set, strand)
        self._helix_substrand_map[substrand.helix_idx].append(substrand)

    def remove_substrand(self, strand: Strand, substrand: Substrand):
        """Remove `substrand` from `strand`."""
        assert strand in self.strands
        strand._remove_substrand(substrand)
        self._helix_substrand_map[substrand.helix_idx].remove(substrand)

    def _build_helix_substrand_map(self):
        self._helix_substrand_map = defaultdict(list)
        for strand in self.strands:
            for substrand in strand.substrands:
                self._helix_substrand_map[substrand.helix_idx].append(substrand)

    def to_json(self, suppress_indent=True):
        """Return string representing this DNADesign, suitable for reading by scadnano if written to
        a JSON file."""
        return json_encode(self, suppress_indent)

    # TODO: create version of add_deltion and add_insertion that simply changes the major tick distance
    #  on the helix at that position, as well as updating the end offset of the substrand (and subsequent
    #  substrands on the same helix)

    def add_deletion(self, helix_idx: int, offset: int):
        """Adds a deletion to every :class:`scadnano.Strand` at the given helix and base offset."""
        substrands = self.substrands_at(helix_idx, offset)
        if len(substrands) == 0:
            raise IllegalDNADesignError(f"no substrands are at helix {helix_idx} offset {offset}")
        for substrand in substrands:
            if substrand.contains_offset(offset):
                substrand.deletions.append(offset)

    def add_insertion(self, helix_idx: int, offset: int, length: int):
        """Adds an insertion with the given length to every :class:`scadnano.Strand`
        at the given helix and base offset, with the given length."""
        substrands = self.substrands_at(helix_idx, offset)
        if len(substrands) == 0:
            raise IllegalDNADesignError(f"no substrands are at helix {helix_idx} offset {offset}")
        for substrand in substrands:
            if substrand.contains_offset(offset):
                substrand.insertions.append((offset, length))

    def set_start(self, substrand: Substrand, start: int):
        """Sets ``substrand.start`` to `start`."""
        assert substrand in (ss for strand in self.strands for ss in strand.substrands)
        substrand.set_start(start)
        self._check_strands_overlap_legally(substrand)

    def set_end(self, substrand: Substrand, end: int):
        """Sets ``substrand.end`` to `end`."""
        assert substrand in (ss for strand in self.strands for ss in strand.substrands)
        substrand.set_end(end)
        self._check_strands_overlap_legally(substrand)

    def move_strand_offsets(self, delta: int):
        """Moves all strands left (if `delta` < 0) or right (if `delta` > 0) by `delta`."""
        for strand in self.strands:
            for substrand in strand.substrands:
                substrand.start += delta
                substrand.end += delta
        self._check_strands_overlap_legally()

    def move_strands_on_helices(self, delta: int):
        """Moves all strands up (if `delta` < 0) or down (if `delta` > 0) by the number of helices given by
        `delta`."""
        for strand in self.strands:
            for substrand in strand.substrands:
                substrand.helix_idx += delta
        self._check_strands_reference_legal_helices()

    def assign_dna(self, strand: Strand, sequence: str):
        """
        Assigns `sequence` as DNA sequence of `strand`.

        If any :class:`scadnano.Strand` is bound to `strand`,
        it is assigned the reverse Watson-Crick complement of the relevant portion,
        and any remaining portions of the other strand that have not already been assigned a DNA sequence
        are assigned to be the symbol :py:data:`DNA_base_wildcard`.

        Before assigning, `sequence` is first forced to be the same length as `strand`
        as follows:
        If `sequence` is longer, it is truncated.
        If `sequence` is shorter, it is padded with :py:data:`DNA_base_wildcard`'s.

        All whitespace in `sequence` is removed, and lowercase bases
        'a', 'c', 'g', 't' are converted to uppercase.
        """
        padded_sequence = _pad_and_remove_whitespace(sequence, strand)

        if strand.dna_sequence is None:
            merged_sequence = padded_sequence
        else:
            try:
                merged_sequence = _string_merge_wildcard(strand.dna_sequence, padded_sequence,
                                                         DNA_base_wildcard)
            except ValueError as err:
                first_ss = strand.first_substrand()
                msg = f'strand starting at helix {first_ss.helix_idx}, offset {first_ss.offset_5p()} has ' \
                      f'length ' \
                      f'{strand.dna_length()} and already has a DNA sequence assignment of length ' \
                      f'{len(strand.dna_sequence)}, which is \n' \
                      f'{strand.dna_sequence}, ' \
                      f'but you tried to assign a different sequence of length {len(padded_sequence)} to ' \
                      f'it, which is\n{padded_sequence}.'
                raise IllegalDNADesignError(msg)

        strand.set_dna_sequence(merged_sequence)

        for other_strand in self.strands:
            if strand == other_strand:
                continue
            if other_strand.overlaps(strand):
                # we do this even if other_strand has a complete DNA sequence,
                # because we get complementarity checks this way
                other_strand.assign_dna_complement_from(strand)

    def to_idt_bulk_input_format(self, delimiter: str = ',', warn_duplicate_name: bool = False,
                                 warn_on_non_idt_strands: bool = False) -> str:
        """Return string that is written to the file in the method :any:`DNADesign.write_idt_file`.

        `delimiter` is the symbol to delimit the four IDT fields name,sequence,scale,purification.

        `warn_duplicate_name` if ``True`` prints a warning when two different :any:`Strand`'s have the same
        :py:attr:`IDTField.name` and the same :any:`Strand.dna_sequence`. An :any:`IllegalDNADesignError` is
        raised (regardless of the value of this parameter)
        if two different :any:`Strand`'s have the same name but different sequences.

        `warn_on_non_idt_strands` specifies whether to print a warning for strands that lack the field
        :any:`Strand.idt`. Such strands will not be part of the output.
        """
        strands_to_output = []
        added_strands: Dict[str, Strand] = {}  # dict: name -> strand
        for strand in self.strands:
            if strand.idt is not None:
                name = strand.idt.name
                if name in added_strands:
                    existing_strand = added_strands[name]
                    assert existing_strand.idt.name == name
                    ss = strand.first_substrand()
                    existing_ss = existing_strand.first_substrand()
                    if strand.dna_sequence != existing_strand.dna_sequence:
                        raise IllegalDNADesignError(
                            f'two strands with same IDT name {name} but different sequences:\n'
                            f'  strand 1: helix {ss.helix_idx}, 5\' end at offset {ss.offset_5p()}, '
                            f'sequence: {strand.dna_sequence}\n'
                            f'  strand 2: helix {existing_ss.helix_idx}, 5\' end at offset '
                            f'{existing_ss.offset_5p()}, '
                            f'sequence: {existing_strand.dna_sequence}\n')
                    elif warn_duplicate_name:
                        print(
                            f'WARNING: two strands with same IDT name {name}:\n'
                            f'  strand 1: helix {ss.helix_idx}, 5\' end at offset {ss.offset_5p()}\n'
                            f'  strand 2: helix {existing_ss.helix_idx}, 5\' end at offset '
                            f'{existing_ss.offset_5p()}\n')
                added_strands[name] = strand
                strands_to_output.append(strand)
            elif warn_on_non_idt_strands:
                print(f"WARNING: strand with 5' end on helix {strand.first_substrand().helix_idx} "
                      f"does not have a field idt, so will not be part of IDT output.")
        idt_lines = [
            delimiter.join([strand.idt.name, strand.dna_sequence, strand.idt.scale, strand.idt.purification])
            for strand in strands_to_output]
        idt_string = '\n'.join(idt_lines)
        return idt_string

    def write_idt_file(self, directory: str = '.', filename=None, delimiter: str = ',',
                       warn_duplicate_name: bool = False, warn_on_non_idt_strands=False):
        """Write ``.idt`` file encoding the strands of this DNADesign with the field
        :any:`Strand.idt`, suitable for pasting into the "Bulk input" field of IDT
        (Integrated DNA Technologies, Coralville, IA, https://www.idtdna.com/),
        with the output file having the same name as the running script but with ``.py`` changed to ``.idt``,
        unless `filename` is explicitly specified.
        For instance, if the script is named ``my_origami.py``,
        then the sequences will be written to ``my_origami.idt``.

        `directory` specifies a directory in which to place the file, either absolute or relative to
        the current working directory. Default is the current working directory.

        `delimiter` is the symbol to delimit the four IDT fields name,sequence,scale,purification.

        `warn_duplicate_name` if ``True`` prints a warning when two different :any:`Strand`'s have the same
        :py:attr:`IDTField.name` and the same :any:`Strand.dna_sequence`. An :any:`IllegalDNADesignError` is
        raised (regardless of the value of this parameter)
        if two different :any:`Strand`'s have the same name but different sequences.

        `warn_on_non_idt_strands` specifies whether to print a warning for strands that lack the field
        :any:`Strand.idt`. Such strands will not be output into the file.

        The string written is that returned by :meth:`DNADesign.to_idt_bulk_input_format`.
        """
        contents = self.to_idt_bulk_input_format(delimiter, warn_duplicate_name, warn_on_non_idt_strands)
        _write_file_same_name_as_running_python_script(contents, 'idt', directory, filename)

    def write_scadnano_file(self, directory: str = '.', filename=None):
        """Write ``.dna`` file representing this DNADesign, suitable for reading by scadnano,
        with the output file having the same name as the running script but with ``.py`` changed to ``.dna``,
        unless `filename` is explicitly specified.
        For instance, if the script is named ``my_origami.py``,
        then the design will be written to ``my_origami.dna``.

        `directory` specifies a directory in which to place the file, either absolute or relative to
        the current working directory. Default is the current working directory.

        The string written is that returned by :meth:`DNADesign.to_json`.
        """
        contents = self.to_json()
        _write_file_same_name_as_running_python_script(contents, 'dna', directory, filename)


def _write_file_same_name_as_running_python_script(contents: str, extension: str, directory: str = '.',
                                                   filename=None):
    if filename is None:
        filename = os.path.basename(sys.argv[0])[:-3] + f'.{extension}'
    if not os.path.exists(directory):
        os.makedirs(directory)
    relative_filename = os.path.join(directory, filename)
    with open(relative_filename, 'w') as out_file:
        out_file.write(contents)

def _remove_whitespace_and_uppercase(sequence):
    sequence = re.sub(r'\s*', '', sequence)
    sequence = sequence.upper()
    return sequence

def _pad_and_remove_whitespace(sequence, strand):
    sequence = _remove_whitespace_and_uppercase(sequence)
    padded_sequence = _pad_dna(sequence, strand.dna_length())
    return padded_sequence

def _pad_dna(sequence: str, length: int) -> str:
    """Return `sequence` modified to have length `length`.

    If len(sequence) < length, pad with  :py:data:`DNA_base_wildcard`.
    If len(sequence) > length, remove extra symbols."""
    if len(sequence) > length:
        sequence = sequence[:length]
    elif len(sequence) < length:
        sequence += DNA_base_wildcard * (length - len(sequence))
    return sequence
