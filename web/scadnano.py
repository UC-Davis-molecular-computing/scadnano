"""
Scripting library for scadnano. Used to write python scripts outputting ``*.dna`` files readable
by `scadnano <https://web.cs.ucdavis.edu/~doty/scadnano/>`_.

This library uses typing hints from the Python typing library.
(https://docs.python.org/3/library/typing.html)
Each function and method indicate intended types of the parameters.
However, due to Python's design, these types are not enforced at runtime.
It is suggested to use a static analysis tool such as that provided by an IDE such as PyCharm
(https://www.jetbrains.com/pycharm/)
to see warnings when the typing rules are violated. Such warnings probably indicate an erroneous usage.

Most of the classes in this module are Python dataclasses
(https://docs.python.org/3/library/dataclasses.html)
whose fields show up in the documentation (their types are listed in parentheses after the name of the class;
for example :any:`Color` has ``int`` fields :py:data:`Color.r`, :py:data:`Color.g`, :py:data:`Color.b`.
In general it is safe to read these fields directly, but not to write to them directly.
Setter methods (named ``set_<fieldname>``) are provided for fields where it makes sense to set it to another
value than it had originally.
However, due to Python naming conventions for dataclass fields and property setters,
it is not straightforward to enforce that the fields cannot be written, so the user must take care not to set
them.
"""

import enum
import itertools
import re
from dataclasses import dataclass, field
from typing import Tuple, List, Dict, Union, Optional
from collections import defaultdict, OrderedDict
import sys
import os.path
import xlwt

from json_utils import JSONSerializable, json_encode, NoIndent
import m13


# TODO: add support for writing Excel files for uploading 96-well and 384-well plates to IDT

# TODO: write from_json for DNADesign so .dna files can be read into the library

# TODO: make explicit rules about when strands can be added and sequences assigned.
#  For instance, if we add a strand to overlap one that already has a DNA sequence sequence assigned,
#  should the complement be automatically assigned?

# TODO: add support for writing 3D positions (in addition to 2D svg_positions)


def _pairwise(iterable):
    """s -> (s0,s1), (s1,s2), (s2, s3), ..."""
    a, b = itertools.tee(iterable)
    next(b, None)
    return zip(a, b)


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
reverse = False
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
The M13mp18 DNA sequence (commonly called simply M13), starting from cyclic rotation 5588, as defined in
`GenBank <https://www.neb.com/~/media/NebUs/Page%20Images/Tools%20and%20Resources/Interactive%20Tools/DNA%20Sequences%20and%20Maps/Text%20Documents/m13mp18gbk.txt>`_.
This is the "standard" variant of consisting of 7249 bases, sold by companies such as  
`New England Biolabs <https://www.neb.com/~/media/nebus/page%20images/tools%20and%20resources/interactive%20tools/dna%20sequences%20and%20maps/m13mp18_map.pdf>`_
and
`Tilibit <https://cdn.shopify.com/s/files/1/1299/5863/files/Product_Sheet_single-stranded_scaffold_DNA_type_7249_M1-10.pdf?14656642867652657391>`_.

The actual M13 DNA strand itself is circular, 
so assigning this sequence to the scaffold :any:`Strand` in a :any:`DNADesign`
means that the "5' end" of the scaffold :any:`Strand` 
(which is a fiction since the actual circular DNA strand has no endpoint) 
will have the sequence starting at position 5588 starting at the displayed 5' in scadnano,
assigned until the displayed 3' end. 
Assuming the displayed scaffold :any:`Strand` has length :math:`n < 7249`, then a loopout of length 
:math:`7249 - n` consisting of the undisplayed bases will be present in the actual DNA structure.
For a more detailed discussion of why this particular rotation of M13 is chosen,
see 
`Supplementary Note S8 <http://www.dna.caltech.edu/Papers/DNAorigami-supp1.linux.pdf>`_ 
in
[`Folding DNA to create nanoscale shapes and patterns. Paul W. K. Rothemund, Nature 440:297-302 (2006) <http://www.nature.com/nature/journal/v440/n7082/abs/nature04586.html>`_].
"""  # noqa (suppress PEP warning)

##################
# keys

# DNADesign keys
version_key = 'version'
grid_key = 'grid'
major_tick_distance_key = 'major_tick_distance'
major_ticks_key = 'major_ticks'
helices_key = 'helices'
potential_helices_key = 'potential_helices'
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
helix_idx_key = 'helix'
forward_key = 'forward'
start_key = 'start'
end_key = 'end'
deletions_key = 'deletions'
insertions_key = 'insertions'

# Loopout keys
loopout_key = 'loopout'


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
class PotentialHelix(JSONSerializable):
    grid_position: Tuple[int, int, int] = None
    """`(h,v,b)` position of this :any:`PotentialHelix` in the side view grid.
    
    It has the same interpretation as :py:data:`Helix.grid_position`."""

    def to_json_serializable(self, suppress_indent=True):
        dct = self.__dict__

        if self.grid_position[2] == 0:  # don't bother writing grid position base coordinate if it is 0
            dct[grid_position_key] = (self.grid_position[0], self.grid_position[1])

        return NoIndent(dct) if suppress_indent else dct


# TODO: rename max_bases to max_offset, add min_offset, and allow offsets to be negative

@dataclass
class Helix(JSONSerializable):
    max_bases: int = -1
    """Maximum length of :any:`Substrand` that can be drawn on this :any:`Helix`. If unspecified,
    it is calculated when the :any:`DNADesign` is instantiated as the largest :any:`Substrand.end`
    index of any :any:`Substrand` in the design.
    
    Once part of a :any:`DNADesign`, a :any:`Helix` has an index (accessible  via ``the_helix.idx()``
    once the :any:`DNADesign` is created) 
    representing its order in the list of all :any:`Helix`'s. This index is how a :any:`Substrand` is
    associated to the :any:`Helix` via the integer index :any:`Substrand.helix`."""

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
    
    Default is `h` = 0, `v` = index of :any:`Helix` in :py:data:`DNADesign.helices`, `b` = 0."""

    svg_position: Tuple[float, float] = None
    """`(x,y)` SVG coordinates of base offset 0 of this Helix in the main view. 
    
    If `grid_position` and `position` are both omitted, then the default is 
    `x` = 0, `y` = [index of helix] * :any:`scadnano.distance_between_helices_svg`.
    
    If `grid_position = (h,v,b)` is specified but `position` is omitted, then the default is
    `x` = b * BASE_WIDTH_SVG, `y` = [index of :any:`Helix`] * :any:`scadnano.distance_between_helices_svg`."""

    _idx: int = -1

    # for optimization; list of substrands on that Helix
    _substrands: List['Substrand'] = field(default_factory=list)

    def to_json_serializable(self, suppress_indent=True):
        dct = dict()

        if self.max_bases >= 0:
            dct[max_bases_key] = self.max_bases

        if self.grid_position[2] == 0:  # don't bother writing grid position base coordinate if it is 0
            dct[grid_position_key] = (self.grid_position[0], self.grid_position[1])
        else:
            dct[grid_position_key] = (self.grid_position[0], self.grid_position[1], self.grid_position[2])

        # print(f'self.svg_position()    = {self.svg_position}')
        # print(f'default_svg_position() = {self.default_svg_position()}')
        default_x, default_y = self.default_svg_position()
        if not (_is_close(self.svg_position[0], default_x) and _is_close(self.svg_position[1], default_y)):
            dct[svg_position_key] = (self.svg_position[0], self.svg_position[1])

        if self.major_tick_distance > 0:
            dct[major_tick_distance_key] = self.major_tick_distance

        if self.major_ticks is not None:
            dct[major_ticks_key] = self.major_ticks

        return NoIndent(dct) if suppress_indent else dct

    def __post_init__(self):
        if self.major_ticks is not None:
            for major_tick in self.major_ticks:
                if major_tick > self.max_bases:
                    raise IllegalDNADesignError(f'major tick {major_tick} in list {self.major_ticks} is '
                                                f'outside the range of available offsets since max_bases = '
                                                f'{self.max_bases}')

    def default_svg_position(self):
        return 0, self._idx * distance_between_helices_svg

    def set_idx(self, idx):
        self._idx = idx

    def idx(self):
        return self._idx

    def default_grid_position(self):
        return (0, self.idx(), 0)


def _is_close(x1: float, x2: float):
    return abs(x1 - x2) < 0.00000001


@dataclass
class Substrand(JSONSerializable):
    """
    A maximal portion of a :any:`Strand` that is continguous on a single :any:`Helix`.
    A :any:`Strand` contains a list of :any:`Substrand`'s (and also :any:`Loopout`'s).
    """

    helix: int
    """index of the :any:`Helix` on which this :any:`Substrand` resides 
    in the list :any:`DNADesign.helices`."""

    forward: bool
    """Whether the strand "points" forward (i.e., its 3' end has a larger offset than its 5' end).
    If :any:`Substrand.forward` is ``True``, then 
    :any:`Substrand.start` is the 5' end of the :any:`Substrand` and 
    :any:`Substrand.end` is the 3' end of the :any:`Substrand`.
    If :any:`Substrand.forward` is ``False``, these roles are reversed."""

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
    i.e., inclusive for start but exclusive for end,
    the same convention used in Python for slices of lists and strings.
    (e.g., :samp:`"abcdef"[1:3] == "bc"`)
    
    Some methods (such as :py:meth:`Substrand.dna_sequence_in`) use the convention of being inclusive on 
    both ends and are marked with the word "INCLUSIVE".
    (This is easier to reason about when there are insertions and deletions.)
    """

    deletions: List[int] = field(default_factory=list)
    """List of positions of deletions on this Substrand."""

    insertions: List[Tuple[int, int]] = field(default_factory=list)
    """List of (position,num_insertions) pairs on this Substrand.
    
    This is the number of *extra* bases in addition to the base already at this position. 
    The total number of bases at this offset is num_insertions+1."""

    # not serialized; for efficiency
    _parent_strand: 'Strand' = field(init=False, repr=False, compare=False, default=None)

    def __post_init__(self):
        self._check_start_end()

    def __repr__(self):
        rep = (f'Substrand(helix={self.helix}'
               f', forward={self.forward}'
               f', start={self.start}'
               f', end={self.end}') + \
              (f', deletions={self.deletions}' if len(self.deletions) > 0 else '') + \
              (f', insertions={self.insertions}' if len(self.insertions) > 0 else '') + \
              ')'
        return rep

    def __str__(self):
        return repr(self)

    def _check_start_end(self):
        if self.start >= self.end:
            raise StrandError(self._parent_strand,
                              f'start = {self.start} must be less than end = {self.end}')

    def to_json_serializable(self, suppress_indent=True):
        dct = OrderedDict()
        dct[helix_idx_key] = self.helix
        dct[forward_key] = self.forward
        dct[start_key] = self.start
        dct[end_key] = self.end
        if len(self.deletions) > 0:
            dct[deletions_key] = self.deletions
        if len(self.insertions) > 0:
            dct[insertions_key] = self.insertions
        return NoIndent(dct) if suppress_indent else dct

    @staticmethod
    def is_loopout():
        return False

    @staticmethod
    def is_substrand():
        return True

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

    def __len__(self):
        """Same as :meth:`Substrand.dna_length`.

        See also :meth:`Substrand.visual_length`."""
        return self.dna_length()

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
        """Distance between :any:`Substrand.start` offset and :any:`Substrand.end` offset.

        This can be more or less than the :meth:`Substrand.dna_length` due to insertions and deletions."""
        return self.end - self.start

    def dna_sequence(self) -> Optional[str]:
        """Return DNA sequence of this Substrand, or ``None`` if no DNA sequence has been assigned
        to this :any:`Substrand`'s :any:`Strand`."""
        return self.dna_sequence_in(self.start, self.end - 1)

    def dna_sequence_in(self, offset_left: int, offset_right: int) -> Optional[str]:
        """Return DNA sequence of this Substrand in the interval of offsets given by
        [`offset_left`, `offset_right`], INCLUSIVE, or ``None`` if no DNA sequence has been assigned
        to this :any:`Substrand`'s :any:`Strand`.

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
        return (self.helix == other.helix and
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
        return (self.helix == other.helix and
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

    def insertion_offsets(self) -> List[int]:
        """Return offsets of insertions (but not their lengths)."""
        return [ins_off for (ins_off, _) in self.insertions]


@dataclass
class Loopout(JSONSerializable):
    """Represents a single-stranded loopout on a :any:`Strand`.

    One could think of a :any:`Loopout` as a type of :any:`Substrand`, but none of the fields of
    :any:`Substrand` make sense for :any:`Loopout`, so they are not related to each other in the type
    hierarchy. It is interpreted that a :any:`Loopout` is a single-stranded region bridging two
    :any:`Substrand`'s that are connected to :any:`Helix`'s, or if it occurs on the end of a :any:`Strand`,
    then it is a single-stranded extension. It is illegal for two consecutive :any:`Substrand`'s to both
    be :any:`Loopout`'s, and for a :any:`Strand` to have only one element of :any:`Strand.substrands`
    that is a :any:`Loopout`.

    Loopout has only a single field :py:data:`length` that specifies the length of the loopout.

    For example, one use of a loopout is to describe a hairpin (a.k.a.,
    `stem-loop <https://en.wikipedia.org/wiki/Stem-loop>`_).
    The following creates a :any:`Strand` that represents a hairpin with a stem length of 10 and a loop
    length of 5.

    .. code-block:: Python

        import scadnano as sc

        ss_f = sc.Substrand(helix=0, forward=True, start=0, end=10)
        loop = sc.Loopout(length=5)
        ss_r = sc.Substrand(helix=0, forward=False, start=0, end=10)
        strand_forward = sc.Strand([ss_f, loop, ss_r])
    """
    length: int

    # not serialized; for efficiency
    _parent_strand: 'Strand' = field(init=False, repr=False, compare=False, default=None)

    def to_json_serializable(self, suppress_indent=True):
        dct = {loopout_key: self.length}
        return NoIndent(dct)

    def __repr__(self):
        return f'Loopout({self.length})'

    def __str__(self):
        return repr(self)

    @staticmethod
    def is_loopout() -> bool:
        return True

    @staticmethod
    def is_substrand() -> bool:
        return False

    def __len__(self):
        """Same as :any:`Loopout.dna_length`"""
        return self.dna_length()

    def dna_length(self) -> int:
        """Length of this :any:`Loopout`; same as field :py:data:`Loopout.length`."""
        return self.length

    def dna_sequence(self) -> Optional[str]:
        """Return DNA sequence of this :any:`Loopout`, or ``None`` if no DNA sequence has been assigned
        to the :any:`Strand` of this :any:`Loopout`."""
        strand_seq = self._parent_strand.dna_sequence
        if strand_seq is None:
            return None

        str_idx_left = self.get_seq_start_idx()
        str_idx_right = str_idx_left + self.length  # EXCLUSIVE (unlike similar code for Substrand)
        subseq = strand_seq[str_idx_left:str_idx_right]
        return subseq

    def get_seq_start_idx(self) -> int:
        """Starting DNA subsequence index for first base of this :any:`Loopout` on its
        :any:`Strand`'s DNA sequence."""
        substrands = self._parent_strand.substrands
        # index of self in parent strand's list of substrands
        self_substrand_idx = substrands.index(self)
        # index of self's position within the DNA sequence of parent strand
        self_seq_idx_start = sum(prev_substrand.dna_length()
                                 for prev_substrand in substrands[:self_substrand_idx])
        return self_seq_idx_start


_wctable = str.maketrans('ACGTacgt', 'TGCAtgca')


def wc(seq: str) -> str:
    """Return reverse Watson-Crick complement of `seq`."""
    return seq.translate(_wctable)[::-1]


@dataclass
class IDTFields(JSONSerializable):
    """Data required when ordering DNA strands from the synthesis company
    `IDT DNA Technologies <https://www.idtdna.com/>`_.
    This data is used when automatically generating files used to order DNA from IDT."""

    name: str
    """Name of the strand (first field in IDT bulk input: https://www.idtdna.com/site/order/oligoentry).
    
    Non-optional field.
    """

    scale: str = default_idt_scale
    """Synthesis scale at which to synthesize the strand (third field in IDT bulk input:
    https://www.idtdna.com/site/order/oligoentry).
    Choices supplied by IDT at the time this was written: 
    ``"25nm"``, ``"100nm"``, ``"250nm"``, ``"1um"``, ``"5um"``, 
    ``"10um"``, ``"4nmU"``, ``"20nmU"``, ``"PU"``, ``"25nmS"``.
    
    Optional field.
    """

    purification: str = default_idt_purification
    """Purification options (fourth field in IDT bulk input:
    https://www.idtdna.com/site/order/oligoentry). 
    Choices supplied by IDT at the time this was written: 
    ``"STD"``, ``"PAGE"``, ``"HPLC"``, ``"IEHPLC"``, ``"RNASE"``, ``"DUALHPLC"``, ``"PAGEHPLC"``.
    
    Optional field.
    """

    plate: Optional[str] = None
    """Name of plate in case this strand will be ordered on a 96-well or 384-well plate.
    
    Optional field, but non-optional if :py:data:`IDTField.well` is not ``None``.
    """

    well: Optional[str] = None
    """Well position on plate in case this strand will be ordered on a 96-well or 384-well plate.
    
    Optional field, but non-optional if :py:data:`IDTField.plate` is not ``None``.
    """

    def __post_init__(self):
        _check_idt_string_not_none_or_empty(self.name, 'name')
        _check_idt_string_not_none_or_empty(self.scale, 'scale')
        _check_idt_string_not_none_or_empty(self.purification, 'purification')
        if self.plate is None and self.well is not None:
            raise IllegalDNADesignError(f'IDTFields.plate cannot be None if IDTFields.well is not None\n'
                                        f'IDTFields.well = {self.well}')
        if self.plate is not None and self.well is None:
            raise IllegalDNADesignError(f'IDTFields.well cannot be None if IDTFields.plate is not None\n'
                                        f'IDTFields.plate = {self.plate}')

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

    A portion of the :any:`Strand` not associated to any :any:`Helix` is represented by a :any:`Loopout`.
    Two :any:`Loopout`'s cannot occur consecutively on a :any:`Strand`, nor can a :any:`Strand`
    contain only a :any:`Loopout` but no :any:`Substrand`.

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

    substrands: List[Union[Substrand, Loopout]]
    """:any:`Substrand`'s (or :any:`Loopout`'s) composing this Strand. 
    Each :any:`Substrand` is contiguous on a single :any:`Helix`, 
    and each :any:`Loopout` is single-stranded and has no :any:`Helix`."""

    dna_sequence: Optional[str] = None
    """Do not assign directly to this field. Always use :any:`DNADesign.assign_dna` 
    (for complementarity checking) or :any:`Strand.set_dna_sequence` (to allow mismatches)."""

    color: Optional[Color] = None
    """Color to show this strand in the main view. If not specified in the constructor,
    a color is assigned by cycling through a list of defaults given by 
    :meth:`ColorCycler.colors`"""

    automatically_assign_color: bool = field(repr=False, default=True)
    """If `automatically_assign_color` = ``False`` and `color` = ``None``, do not automatically
    assign a :any:`Color` to this :any:`Strand`. 
    In this case color will be set to its default of ``None`` and will not be
    written to the JSON with :py:meth:`DNADesign.write_scadnano_file` or :py:meth:`DNADesign.to_json`."""

    idt: Optional[IDTFields] = None
    """Fields used when ordering strands from the synthesis company IDT 
    (Integrated DNA Technologies, Coralville, IA). If present (i.e., not equal to :const:`None`)
    then the method :py:meth:`DNADesign.write_idt_file` can be called to automatically
    generate an IDT file for ordering strands: https://eu.idtdna.com/site/order/oligoentry"""

    use_default_idt: bool = False
    """If ``True``, assigns an :any:`IDTFields` to this :any:`Strand` with same naming convention as
    cadnano, i.e., :py:data:`IDTFields.name` = "ST{h5}[{s}]{h3}[{e}]", where h5 and h3 are the 
    :any:`Helix`'s of the 5' and 3' ends, respectively, of the :any:`Strand`, 
    and s and e are the respective start and end offsets on those helices.
    """

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
            if substrand.is_substrand():
                self._helix_idx_substrand_map[substrand.helix].append(substrand)

        for substrand in self.substrands:
            substrand._parent_strand = self

        if len(self.substrands) == 1:
            if self.first_substrand().is_loopout():
                raise StrandError(self, 'strand cannot have a single Loopout as its only substrand')

        for ss1, ss2 in _pairwise(self.substrands):
            if ss1.is_loopout() and ss2.is_loopout():
                raise StrandError(self, 'cannot have two consecutive Loopouts in a strand')

        if self.use_default_idt:
            self.set_default_idt(True)

    def set_default_idt(self, use_default_idt):
        """Sets idt field to be the default given the Substrand data of this :any:`Strand`."""
        self.use_default_idt = use_default_idt
        if use_default_idt:
            start_helix = self.first_bound_substrand().helix
            end_helix = self.last_bound_substrand().helix
            start_offset = self.first_bound_substrand().offset_5p()
            end_offset = self.last_bound_substrand().offset_3p()
            self.idt = IDTFields(name=f'ST{start_helix}[{start_offset}]{end_helix}[{end_offset}]')
        else:
            self.idt = None

    def first_substrand(self) -> Union[Substrand, Loopout]:
        return self.substrands[0]

    def last_substrand(self) -> Union[Substrand, Loopout]:
        return self.substrands[-1]

    def set_dna_sequence(self, sequence: str):
        """Set this :any:`Strand`'s DNA sequence to `seq`
        WITHOUT checking for complementarity with overlapping
        :any:`Strand`'s or automatically assigning their sequences.
        To assign a sequence to a :any:`Strand` and have the overlapping
        :any:`Strand`'s automatically have the appropriate Watson-Crick complements assigned,
        use :any:`DNADesign.assign_dna`.

        All whitespace in `sequence` is removed,
        and lowercase bases 'a', 'c', 'g', 't' are converted to uppercase.

        `sequence`, after all whitespace is removed, must be exactly the same length as
        :py:meth:`Strand.dna_length`.
        Wildcard symbols (:py:const:`DNA_case_wildcard`) are allowed to leave part of the DNA unassigned.
        """
        trimmed_seq = _remove_whitespace_and_uppercase(sequence)
        if len(trimmed_seq) != self.dna_length():
            ss = self.first_substrand()
            raise StrandError(self, f"strand starting at helix {ss.helix} offset {ss.offset_5p()} "
                                    f"has length {self.dna_length()}, but you attempted to assign a "
                                    f"DNA sequence of length {len(trimmed_seq)}: {sequence}")
        self.dna_sequence = trimmed_seq

    def dna_length(self) -> int:
        """Return sum of DNA length of Substrands of this Strand."""
        acc = 0
        for substrand in self.substrands:
            acc += substrand.dna_length()
        return acc
        # return sum(len(substrand) for substrand in self.substrands)

    def bound_substrands(self) -> List[Union[Substrand, Loopout]]:
        """:any:`Substrand`'s of this :any:`Strand` that are not :any:`Loopout`'s."""
        return [ss for ss in self.substrands if ss.is_substrand()]

    def offset_5p(self) -> int:
        return self.first_substrand().offset_5p()

    def offset_3p(self) -> int:
        return self.last_substrand().offset_3p()

    def overlaps(self, other: 'Strand') -> bool:
        """Indicates whether `self` overlaps `other_strand`, meaning that the set of offsets occupied
        by `self` has nonempty intersection with those occupied by `other_strand`."""
        for substrand_self in self.bound_substrands():
            for substrand_other in other.bound_substrands():
                if substrand_self.overlaps(substrand_other):
                    return True
        return False

    def assign_dna_complement_from(self, other: 'Strand'):
        """Assuming a DNA sequence has been assigned to `other`, assign its Watson-Crick
        complement to the portions of this Strand that are bound to `other`.

        Generally this is not called directly; use :py:meth:`DNADesign.assign_dna` to assign
        a DNA sequence to a :any:`Strand`. The method :py:meth:`DNADesign.assign_dna` will calculate
        which other :any:`Strand`'s need
        to be assigned via :py:meth:`Strand.assign_dna_complement_from`.

        However, it is permitted to assign the field :py:data:`Strand.dna_sequence` directly
        via the method :py:meth:`Strand.set_dna_sequence`.
        This is used, for instance, to assign a DNA sequence to a :any:`Strand` bound to another
        :any:`Strand`
        with an assigned DNA sequence where they overlap. In this case no error checking
        about sequence complementarity is done. This can be used to intentionally assign *mismatching*
        DNA sequences to :any:`Strand`'s that are bound on a :any:`Helix`."""

        already_assigned = self.dna_sequence is not None

        # put DNA sequences to assign to substrands in List, one position per substrand
        strand_complement_builder = []
        if already_assigned:
            for substrand in self.substrands:
                strand_complement_builder.append(substrand.dna_sequence())
        else:
            for substrand in self.substrands:
                wildcards = DNA_base_wildcard * substrand.dna_length()
                strand_complement_builder.append(wildcards)

        for (ss_idx, substrand_self) in enumerate(self.substrands):
            if substrand_self.is_loopout():
                substrand_self_dna_sequence = DNA_base_wildcard * substrand_self.dna_length()
            else:
                helix = substrand_self.helix

                # for helix, substrands_on_helix_self in self._helix_idx_substrand_map.items():
                substrands_on_helix_other = other._helix_idx_substrand_map[helix]
                # for substrand_self in substrands_on_helix_self:
                overlaps = []
                for substrand_other in substrands_on_helix_other:
                    if substrand_self != substrand_other and substrand_self.overlaps(substrand_other):
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

            # merge with existing pre-assigned sequence
            existing_substrand_self_dna_sequence = strand_complement_builder[ss_idx]
            merged_substrand_self_dna_sequence = _string_merge_wildcard(substrand_self_dna_sequence,
                                                                        existing_substrand_self_dna_sequence,
                                                                        DNA_base_wildcard)
            strand_complement_builder[ss_idx] = merged_substrand_self_dna_sequence

        strand_complement = ''.join(strand_complement_builder)
        new_dna_sequence = strand_complement
        if self.dna_sequence is not None:
            try:
                new_dna_sequence = _string_merge_wildcard(self.dna_sequence, new_dna_sequence,
                                                          DNA_base_wildcard)
            except ValueError:
                ss_self = self.first_substrand()
                ss_other = other.first_substrand()
                msg = f'strand starting at helix {ss_self.helix}, offset {ss_self.offset_5p()} has ' \
                      f'length ' \
                      f'{self.dna_length()} and already has a partial DNA sequence assignment of length ' \
                      f'{len(self.dna_sequence)}, which is \n' \
                      f'{self.dna_sequence}, ' \
                      f'but you tried to assign sequence of length {len(new_dna_sequence)} to it, which ' \
                      f'is\n{new_dna_sequence} (this assignment was indirect, since you assigned directly ' \
                      f'to a strand bound to this one). This occurred while directly assigning a DNA ' \
                      f'sequence to the strand whose 5\' end is at helix {ss_other.helix}, and is of ' \
                      f'length {other.dna_length()}.'
                raise IllegalDNADesignError(msg)

        self.set_dna_sequence(new_dna_sequence)
        # self.dna_sequence = _pad_dna(new_dna_sequence, self.dna_length())

    def _insert_substrand(self, order, substrand):
        """Only intended to be called by DNADesign.insert_substrand"""
        self.substrands.insert(order, substrand)
        substrand._parent_strand = self
        if substrand.is_substrand():
            self._helix_idx_substrand_map[substrand.helix].append(substrand)
        if self.use_default_idt:
            self.set_default_idt()

    def _remove_substrand(self, substrand):
        """Only intended to be called by DNADesign.remove_substrand"""
        self.substrands.remove(substrand)
        substrand._parent_strand = None
        if substrand.is_substrand():
            self._helix_idx_substrand_map[substrand.helix].remove(substrand)
        if self.use_default_idt:
            self.set_default_idt()

    def contains_loopouts(self):
        for ss in self.substrands:
            if ss.is_loopout():
                return True
        return False

    def first_bound_substrand(self):
        for substrand in self.substrands:
            if substrand.is_substrand():
                return substrand

    def last_bound_substrand(self):
        substrands_rev = list(self.substrands)
        substrands_rev.reverse()
        for substrand in substrands_rev:
            if substrand.is_substrand():
                return substrand


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

    def __init__(self, the_cause: str):
        self.cause = the_cause

    # __str__ is to print() the value
    def __str__(self):
        return repr(self.cause)


class StrandError(IllegalDNADesignError):
    """Indicates that the :any:`DNADesign` is illegal due to some specific :any:`Strand`.
    Information about the :any:`Strand` is embedded in the error message when this exception is
    raised that helps to identify which :any:`Strand` caused the problem."""

    def __init__(self, strand: Strand, the_cause: str):
        first_substrand = strand.first_bound_substrand()
        last_substrand = strand.last_bound_substrand()

        msg = (f'{the_cause}\n'
               f'strand length        =  {strand.dna_length()}\n'
               f'DNA length           =  {len(strand.dna_sequence) if strand.dna_sequence else "N/A"}\n'
               f'DNA sequence         =  {strand.dna_sequence}'
               f"strand 5' helix      =  {first_substrand.helix if first_substrand else 'N/A'}\n"
               f"strand 5' end offset =  {first_substrand.offset_5p() if first_substrand else 'N/A'}\n"
               f"strand 3' helix      =  {last_substrand.helix if last_substrand else 'N/A'}\n"
               f"strand 3' end offset =  {last_substrand.offset_3p() if last_substrand else 'N/A'}\n")

        super(IllegalDNADesignError, self).__init__(msg)


# TODO: add mutation operations to DNADesign to mutate all of its parts:
#  - Helix
#    - idx
#    - max_bases
#    - major_ticks (possibly as part of a deletion on strands that actually deletes the whole offset)
#    - svg_position (can help with importing cadnano designs that display poorly with default positions)
#  - Substrand
#    - helix
#    - right
#    - start
#    - end
#  - Strand
#    - unassign DNA sequence
#  - DNADesign
#    - add Helix
#    - remove Helix


def _plates(idt_strands):
    plates = set()
    for strand in idt_strands:
        if strand.idt is not None and strand.idt.plate is not None:
            plates.add(strand.idt.plate)
    return list(plates)


_PLATE_ROWS = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H']
_PLATE_COLS = list(range(1, 13))


class _PlateCoordinate:

    def __init__(self):
        self._plate: int = 1
        self._row_idx: int = 0
        self._col_idx: int = 0

    def increment(self):
        self._row_idx += 1
        if self._row_idx == len(_PLATE_ROWS):
            self._row_idx = 0
            self._col_idx += 1
            if self._col_idx == len(_PLATE_COLS):
                self._col_idx = 0
                self._plate += 1

    def plate(self) -> int:
        return self._plate

    def row(self) -> str:
        return _PLATE_ROWS[self._row_idx]

    def col(self) -> int:
        return _PLATE_COLS[self._col_idx]

    def well(self) -> str:
        return f'{self.row()}{self.col()}'


@dataclass
class DNADesign(JSONSerializable):
    """Object representing the entire design of the DNA structure."""

    strands: List[Strand]
    """All of the :any:`Strand`'s in this :any:`DNADesign`.
    
    Required field."""

    helices: List[Helix] = None
    """All of the :any:`Helix`'s in this :any:`DNADesign`. 
    
    Optional field. If not specified, then the number of helices will be just large enough to store the
    largest index :py:data:`Substrand.helix` 
    stored in any :any:`Substrand` 
    in :py:data:`DNADesign.strands`."""

    potential_helices: List[PotentialHelix] = field(default_factory=list)
    """Potential helices, which are gray circle positions listed in the side view where 
    a :any:`Helix` can be added by Ctrl+click.
    
    Optional field."""

    grid: Grid = Grid.none
    """Common choices for how to arrange helices relative to each other.
    
    Optional field."""

    major_tick_distance: int = -1
    """Distance between major ticks (bold) delimiting boundaries between bases.
    
    Optional field.
    If not specified, default value is 8 unless overridden by :py:data:`DNADesign.grid`.
    If 0 then no major ticks are drawn.
    If negative then the default value is assumed, but `major_tick_distance` is not stored in the JSON file
    when serialized.
    If :any:`DNADesign.grid` = :any:`Grid.square` then the default value is 8.
    If :any:`DNADesign.grid` = :any:`Grid.hex` or :any:`Grid.honeycomb` then the default value is 7."""

    def to_json_serializable(self, suppress_indent=True):
        dct = OrderedDict()
        dct[version_key] = current_version
        if self.grid != default_grid:
            dct[grid_key] = str(self.grid)[5:]  # remove prefix 'Grid.'
        if self.major_tick_distance >= 0 and (
                self.major_tick_distance != default_major_tick_distance(self.grid)):
            dct[major_tick_distance_key] = self.major_tick_distance

        dct[helices_key] = [helix.to_json_serializable(suppress_indent) for helix in self.helices]

        if len(self.potential_helices) > 0:
            dct[potential_helices_key] = [ph.to_json_serializable(suppress_indent) for ph in
                                          self.potential_helices]

        dct[strands_key] = [strand.to_json_serializable(suppress_indent) for strand in self.strands]

        for helix in self.helices:
            max_offset = max((ss.end for ss in helix._substrands), default=-1)
            helix_json = dct[helices_key][helix.idx()].value  # get past NoIndent surrounding helix
            if max_offset == helix_json[max_bases_key]:
                del helix_json[max_bases_key]

        return dct

    def __post_init__(self):
        if self.major_tick_distance < 0:
            self.major_tick_distance = default_major_tick_distance(self.grid)

        # doing this first matters because most of DNADesign assumes helices has been set
        if self.helices is None:
            max_helix_idx = max(ss.helix for strand in self.strands for ss in strand.bound_substrands())
            self.helices = list(Helix() for _ in range(max_helix_idx + 1))

        # XXX: exact order of these calls is important
        self._set_helices_idxs()
        self._set_helices_grid_and_svg_positions()
        self._build_substrands_on_helix_lists()
        self._set_helices_max_bases(update=False)
        self._check_legal_design()

    def _set_helices_idxs(self):
        for idx, helix in enumerate(self.helices):
            helix.set_idx(idx)

    def _set_helices_grid_and_svg_positions(self):
        for idx, helix in enumerate(self.helices):
            if helix.grid_position is None:
                helix.grid_position = helix.default_grid_position()
            if helix.svg_position is None:
                helix.svg_position = helix.default_svg_position()

    def _set_helices_max_bases(self, update: bool):
        """update = whether to overwrite existing Helix.max_bases. Don't do this when DNADesign is first
        created, but do it later when updating."""
        for helix in self.helices:
            if update or helix.max_bases < 0:
                max_bases = -1
                for substrand in helix._substrands:
                    max_bases = max(max_bases, substrand.end)
                helix.max_bases = max_bases

    def set_default_idt(self, use_default_idt):
        """If ``True``, sets :py:data:`Strand.use_default_idt` to ``True`` for every :any:`Strand` in this
        :any:`DNADesign` and calls :py:meth:`Strand.set_default_idt` on each of them to assign a
        default idt field.

        If ``False``, removes IDT field from each :any:`Strand`."""
        for strand in self.strands:
            strand.set_default_idt(use_default_idt)

    def strands_starting_on_helix(self, helix: int) -> List[Strand]:
        """Return list of :any:`Strand`'s that begin (have their 5' end)
        on the :any:`Helix` with index `helix`."""
        return [strand for strand in self.strands if strand.substrands[0].helix == helix]

    def strands_ending_on_helix(self, helix: int) -> List[Strand]:
        """Return list of :any:`Strand`'s that finish (have their 3' end)
        on the :any:`Helix` with index `helix`."""
        return [strand for strand in self.strands if strand.substrands[-1].helix == helix]

    def _check_legal_design(self):
        # self._check_helix_indices()
        self._check_strands_reference_helices_legally()
        self._check_loopouts_not_consecutive_or_singletons_or_zero_length()
        self._check_strands_overlap_legally()

    # def _check_helix_indices(self):
    #     # ensure if there are H helices, the list of sorted indices is 0,1,...,H-1
    #     indices_helices = sorted([(helix.idx, helix) for helix in self.helices],
    #                              key=lambda x: x[0])
    #     for (correct_idx, (helix_idx, helix)) in enumerate(indices_helices):
    #         if correct_idx != helix_idx:
    #             if correct_idx < helix_idx:
    #                 err_msg = f"missing Helix with helix {correct_idx}"
    #             else:
    #                 err_msg = f"duplicate Helices with helix {helix_idx}"
    #             raise IllegalDNADesignError(err_msg)

    def _check_strands_overlap_legally(self, substrand_to_check: Substrand = None):
        """If `substrand_to_check` is None, check all.
        Otherwise only check pairs where one is substrand_to_check."""

        def err_msg(substrand1, substrand2, h_idx):
            return f"two substrands overlap on helix {h_idx}: " \
                   f"\n{substrand1}\n  and\n{substrand2}\n  but have the same direction"

        # ensure that if two strands overlap on the same helix,
        # they point in opposite directions
        for helix_idx, substrands in enumerate(helix._substrands for helix in self.helices):
            if substrand_to_check is not None and substrand_to_check.helix != helix_idx:
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

    def _check_loopouts_not_consecutive_or_singletons_or_zero_length(self):
        for strand in self.strands:
            DNADesign._check_loopout_not_singleton(strand)
            DNADesign._check_two_consecutive_loopouts(strand)
            DNADesign._check_loopouts_length(strand)

    # TODO: make StrandError like in Dart code to give info about strand in error message

    @staticmethod
    def _check_two_consecutive_loopouts(strand):
        for ss1, ss2 in _pairwise(strand.substrands):
            if ss1 is Loopout and ss2 is Loopout:
                raise StrandError(strand, 'cannot have two consecutive Loopouts in a strand')

    @staticmethod
    def _check_loopout_not_singleton(strand):
        if len(strand.substrands) == 1:
            if strand.first_substrand().is_loopout():
                raise StrandError(strand, 'strand cannot have a single Loopout as its only substrand')

    @staticmethod
    def _check_loopouts_length(strand):
        for loopout in strand.substrands:
            if loopout.is_loopout() and loopout.length <= 0:
                raise StrandError(strand, f'loopout length must be positive but is {loopout.length}')

    def _check_strands_reference_helices_legally(self):
        # ensure each strand refers to an existing helix
        for strand in self.strands:
            self._check_strand_references_legal_helices(strand)
            self._check_strand_has_legal_offsets_in_helices(strand)

    def _check_strand_has_legal_offsets_in_helices(self, strand: Strand):
        for substrand in strand.substrands:
            if substrand.is_substrand():
                helix = self.helices[substrand.helix]
                if substrand.end > helix.max_bases:
                    err_msg = f"substrand {substrand} has end offset {substrand.end}, beyond the end of " \
                              f"Helix {substrand.helix} that has max_bases = {helix.max_bases}"
                    raise StrandError(substrand._parent_strand, err_msg)

    def _check_strand_references_legal_helices(self, strand: Strand):
        for substrand in strand.substrands:
            if substrand.is_substrand() and not (0 <= substrand.helix < len(self.helices)):
                err_msg = f"substrand {substrand} refers to nonexistent Helix index {substrand.helix}"
                raise StrandError(substrand._parent_strand, err_msg)

        # ensure helix_idx's are never negative twice in a row
        for ss1, ss2 in _pairwise(strand.substrands):
            if ss1.is_loopout() and ss2.is_loopout():
                err_msg = f"Loopouts {ss1} and {ss2} are consecutive on strand {strand}. " \
                          f"At least one of any consecutive pair must be a Substrand, not a Loopout."
                raise StrandError(strand, err_msg)

    def substrands_at(self, helix: int, offset: int) -> List[Substrand]:
        """Return list of :any:`Substrand`'s that overlap `offset` on helix with idx `helix`.

        If constructed properly, this list should have 0, 1, or 2 elements."""
        substrands_on_helix = self.helices[helix]._substrands
        # TODO: replace this with a faster algorithm using binary search
        substrands_on_helix = [substrand for substrand in substrands_on_helix if
                               substrand.contains_offset(offset)]
        if len(substrands_on_helix) not in [0, 1, 2]:
            raise AssertionError(f'There should be at most 2 substrands on helix {helix}, '
                                 f'but there are {len(substrands_on_helix)}:\n{substrands_on_helix}')
        return substrands_on_helix

    # TODO: add_strand and insert_substrand should check for existing deletions/insertion parallel strands
    def add_strand(self, strand: Strand):
        """Add `strand` to this design."""
        self._check_strand_references_legal_helices(strand)
        self.strands.append(strand)
        for substrand in strand.substrands:
            self.helices[substrand.helix]._substrands.append(substrand)

    def remove_strand(self, strand: Strand):
        """Remove `strand` from this design."""
        self.strands.remove(strand)
        for substrand in strand.substrands:
            self.helices[substrand.helix]._substrands.remove(substrand)

    def insert_substrand(self, strand: Strand, order: int, substrand: Union[Substrand, Loopout]):
        """Insert `substrand` into `strand` at index given by `order`. Uses same indexing as Python lists,
        e.g., ``strand.insert_substrand(ss, 0)`` inserts ``ss`` as the new first :any:`Substrand`."""
        assert strand in self.strands
        strand._insert_substrand(order, substrand)
        self._check_strand_references_legal_helices(strand)
        self._check_loopouts_not_consecutive_or_singletons_or_zero_length()
        self.helices[substrand.helix]._substrands.append(substrand)

    def remove_substrand(self, strand: Strand, substrand: Union[Substrand, Loopout]):
        """Remove `substrand` from `strand`."""
        assert strand in self.strands
        strand._remove_substrand(substrand)
        self.helices[substrand.helix]._substrands.remove(substrand)

    def _build_substrands_on_helix_lists(self):
        for helix in self.helices:
            helix._substrands = []
        for strand in self.strands:
            for substrand in strand.substrands:
                if substrand.is_substrand():
                    if substrand.helix < len(self.helices):
                        self.helices[substrand.helix]._substrands.append(substrand)
                    else:
                        msg = f"substrand's helix is {substrand.helix} but largest helix is {len(self.helices) - 1}"
                        raise StrandError(strand=strand, the_cause=msg)

    def to_json(self, suppress_indent=True) -> str:
        """Return string representing this DNADesign, suitable for reading by scadnano if written to
        a JSON file."""
        return json_encode(self, suppress_indent)

    # TODO: create version of add_deletion and add_insertion that simply changes the major tick distance
    #  on the helix at that position, as well as updating the end offset of the substrand (and subsequent
    #  substrands on the same helix)

    def add_deletion(self, helix: int, offset: int):
        """Adds a deletion to every :class:`scadnano.Strand` at the given helix and base offset."""
        substrands = self.substrands_at(helix, offset)
        if len(substrands) == 0:
            raise IllegalDNADesignError(f"no substrands are at helix {helix} offset {offset}")
        for substrand in substrands:
            if substrand.contains_offset(offset):
                substrand.deletions.append(offset)

    def add_insertion(self, helix: int, offset: int, length: int):
        """Adds an insertion with the given length to every :class:`scadnano.Strand`
        at the given helix and base offset, with the given length."""
        substrands = self.substrands_at(helix, offset)
        if len(substrands) == 0:
            raise IllegalDNADesignError(f"no substrands are at helix {helix} offset {offset}")
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
        """Moves all strands backward (if `delta` < 0) or forward (if `delta` > 0) by `delta`."""
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
                substrand.helix += delta
        self._check_strands_reference_helices_legally()

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
            except ValueError:
                first_ss = strand.first_substrand()
                msg = f'strand starting at helix {first_ss.helix}, offset {first_ss.offset_5p()} has ' \
                      f'length ' \
                      f'{strand.dna_length()} and already has a DNA sequence assignment of length ' \
                      f'{len(strand.dna_sequence)}, which is \n' \
                      f'{strand.dna_sequence}, ' \
                      f'but you tried to assign a different sequence of length {len(padded_sequence)} to ' \
                      f'it, which is\n{padded_sequence}.'
                raise IllegalDNADesignError(msg)

        strand.set_dna_sequence(merged_sequence)

        for other_strand in self.strands:
            # note that possibly strand==other_strand; it might bind to itself at some point and we want to
            # allow a partial assignment to one substrand to automatically assign the complement to the
            # bound substrand.
            # However, if there are no wildcards in the assigned sequence we can safely skip strand.
            if strand == other_strand and DNA_base_wildcard not in strand.dna_sequence:
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
        if two different :any:`Strand`'s have the same name but different sequences, IDT scales, or IDT
        purifications.

        `warn_on_non_idt_strands` specifies whether to print a warning for strands that lack the field
        :any:`Strand.idt`. Such strands will not be part of the output.
        """
        added_strands = self._idt_strands(warn_duplicate_name, warn_on_non_idt_strands)

        idt_lines = [
            delimiter.join([strand.idt.name, strand.dna_sequence, strand.idt.scale, strand.idt.purification])
            for strand in added_strands.values()]

        idt_string = '\n'.join(idt_lines)
        return idt_string

    def _idt_strands(self, warn_duplicate_name, warn_on_non_idt_strands) -> Dict[str, Strand]:
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
                            f'  strand 1: helix {ss.helix}, 5\' end at offset {ss.offset_5p()}, '
                            f'sequence: {strand.dna_sequence}\n'
                            f'  strand 2: helix {existing_ss.helix}, 5\' end at offset '
                            f'{existing_ss.offset_5p()}, '
                            f'sequence: {existing_strand.dna_sequence}\n')
                    elif strand.idt.scale != existing_strand.idt.scale:
                        raise IllegalDNADesignError(
                            f'two strands with same IDT name {name} but different IDT scales:\n'
                            f'  strand 1: helix {ss.helix}, 5\' end at offset {ss.offset_5p()}, '
                            f'scale: {strand.idt.scale}\n'
                            f'  strand 2: helix {existing_ss.helix}, 5\' end at offset '
                            f'{existing_ss.offset_5p()}, '
                            f'scale: {existing_strand.idt.scale}\n')
                    elif strand.idt.purification != existing_strand.idt.purification:
                        raise IllegalDNADesignError(
                            f'two strands with same IDT name {name} but different purifications:\n'
                            f'  strand 1: helix {ss.helix}, 5\' end at offset {ss.offset_5p()}, '
                            f'purification: {strand.idt.purification}\n'
                            f'  strand 2: helix {existing_ss.helix}, 5\' end at offset '
                            f'{existing_ss.offset_5p()}, '
                            f'purification: {existing_strand.idt.purification}\n')
                    elif warn_duplicate_name:
                        print(
                            f'WARNING: two strands with same IDT name {name}:\n'
                            f'  strand 1: helix {ss.helix}, 5\' end at offset {ss.offset_5p()}\n'
                            f'  strand 2: helix {existing_ss.helix}, 5\' end at offset '
                            f'{existing_ss.offset_5p()}\n')
                added_strands[name] = strand
            elif warn_on_non_idt_strands:
                print(f"WARNING: strand with 5' end on helix {strand.first_substrand().helix} "
                      f"does not have a field idt, so will not be part of IDT output.")
        return added_strands

    def write_idt_file(self, directory: str = '.', filename=None, delimiter: str = ',',
                       warn_duplicate_name: bool = False, warn_on_non_idt_strands=False):
        """Write ``.idt`` file encoding the strands of this :any:`DNADesign` with the field
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
        if two different :any:`Strand`'s have the same name but different sequences, IDT scales, or IDT
        purifications.

        `warn_on_non_idt_strands` specifies whether to print a warning for strands that lack the field
        :any:`Strand.idt`. Such strands will not be output into the file.

        The string written is that returned by :meth:`DNADesign.to_idt_bulk_input_format`.
        """
        contents = self.to_idt_bulk_input_format(delimiter, warn_duplicate_name, warn_on_non_idt_strands)
        _write_file_same_name_as_running_python_script(contents, 'idt', directory, filename)

    def write_idt_plate_excel_file(self, directory: str = '.', filename=None,
                                   warn_duplicate_name: bool = False, warn_on_non_idt_strands=False,
                                   use_default_plates=False, warn_using_default_plates=True):
        """Write ``.xls`` (Microsoft Excel) file encoding the strands of this :any:`DNADesign` with the field
        :any:`Strand.idt`, suitable for uploading to IDT
        (Integrated DNA Technologies, Coralville, IA, https://www.idtdna.com/)
        to describe a 96-well or 384-well plate
        (https://www.idtdna.com/site/order/plate/index/dna/),
        with the output file having the same name as the running script but with ``.py`` changed to ``.xls``,
        unless `filename` is explicitly specified.
        For instance, if the script is named ``my_origami.py``,
        then the sequences will be written to ``my_origami.xls``.

        `directory` specifies a directory in which to place the file, either absolute or relative to
        the current working directory. Default is the current working directory.

        `warn_duplicate_name` if ``True`` prints a warning when two different :any:`Strand`'s have the same
        :py:attr:`IDTField.name` and the same :any:`Strand.dna_sequence`. An :any:`IllegalDNADesignError` is
        raised (regardless of the value of this parameter)
        if two different :any:`Strand`'s have the same name but different sequences, IDT scales, or IDT
        purifications.

        `warn_on_non_idt_strands` specifies whether to print a warning for strands that lack the field
        :any:`Strand.idt`. Such strands will not be output into the file.

        The string written is that returned by :meth:`DNADesign.to_idt_bulk_input_format`.
        """

        idt_strands = list(self._idt_strands(warn_duplicate_name, warn_on_non_idt_strands).values())

        if not use_default_plates:
            self._write_plates_assuming_explicit_in_each_strand(directory, filename, idt_strands)
        else:
            if warn_using_default_plates:
                print("WARNING: ignoring plate data in each strand and using default sequential assignment "
                      "of plates and wells")
            self._write_plates_default(directory, filename, idt_strands)

    def _write_plates_assuming_explicit_in_each_strand(self, directory, filename, idt_strands):
        plates = list({strand.idt.plate for strand in idt_strands if strand.idt is not None if
                       strand.idt.plate is not None})
        plates.sort()
        filename_plate, workbook = self._setup_excel_file(directory, filename)
        for plate in plates:
            worksheet = self._add_new_excel_plate_sheet(plate, workbook)

            strands_in_plate = [strand for strand in idt_strands if
                                strand.idt is not None and strand.idt.plate == plate]

            strands_in_plate.sort(key=lambda s: (int(s.idt.well[1:]), s.idt.well[0]))

            for row, strand in enumerate(strands_in_plate):
                worksheet.write(row + 1, 0, strand.idt.well)
                worksheet.write(row + 1, 1, strand.idt.name)
                worksheet.write(row + 1, 2, strand.dna_sequence)

            workbook.save(filename_plate)

    def _add_new_excel_plate_sheet(self, plate_name: str, workbook: xlwt.Workbook) -> xlwt.Worksheet:
        worksheet = workbook.add_sheet(plate_name)
        worksheet.write(0, 0, 'Well Position')
        worksheet.write(0, 1, 'Name')
        worksheet.write(0, 2, 'Sequence')
        return worksheet

    def _setup_excel_file(self, directory, filename):
        plate_extension = f'xls'
        if filename is None:
            filename_plate = _get_filename_same_name_as_running_python_script(
                directory, plate_extension, filename)
        else:
            filename_plate = filename + plate_extension
        workbook = xlwt.Workbook()
        return filename_plate, workbook

    def _write_plates_default(self, directory, filename, idt_strands):
        plate_coord = _PlateCoordinate()
        plate = 1
        excel_row = 1
        filename_plate, workbook = self._setup_excel_file(directory, filename)
        worksheet = self._add_new_excel_plate_sheet(f'plate{plate}', workbook)

        for strand in idt_strands:
            well = plate_coord.well()
            worksheet.write(excel_row, 0, well)
            worksheet.write(excel_row, 1, strand.idt.name)
            worksheet.write(excel_row, 2, strand.dna_sequence)
            plate_coord.increment()
            if plate != plate_coord.plate():
                workbook.save(filename_plate)
                plate = plate_coord.plate()
                worksheet = self._add_new_excel_plate_sheet(f'plate{plate}', workbook)
                excel_row = 1
            else:
                excel_row += 1

        workbook.save(filename_plate)

    def write_scadnano_file(self, directory: str = '.', filename=None):
        """Write ``.dna`` file representing this :any:`DNADesign`, suitable for reading by scadnano,
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


def _name_of_this_script() -> str:
    """Return name of the currently running script, WITHOUT the .py extension."""
    return os.path.basename(sys.argv[0])[:-3]


def _write_file_same_name_as_running_python_script(contents: str, extension: str, directory: str = '.',
                                                   filename=None):
    relative_filename = _get_filename_same_name_as_running_python_script(directory, extension, filename)
    with open(relative_filename, 'w') as out_file:
        out_file.write(contents)


def _get_filename_same_name_as_running_python_script(directory, extension, filename):
    if filename is None:
        filename = _name_of_this_script() + f'.{extension}'
    if not os.path.exists(directory):
        os.makedirs(directory)
    relative_filename = os.path.join(directory, filename)
    return relative_filename


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
