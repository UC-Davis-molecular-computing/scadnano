"""
Scripting library for scadnano. Used to write python scripts outputting ``*.dna`` files readable
by `scadnano <https://web.cs.ucdavis.edu/~doty/scadnano/>`_.
"""

import enum
from dataclasses import dataclass, field
from typing import Tuple, List, Dict
from collections import defaultdict, OrderedDict
import sys
import os.path

from json_utils import JSONSerializable, json_encode, NoIndent
import m13


# TODO: add support for writing 3D positions (in addition to 2D svg_positions)

# TODO: add check for whether RUNNING_IN_BROWSER is true and change behavior of write_to_file or provide some means of exporting DNADesign as JSON to Dart

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
right = True
square = Grid.square
hexagonal = Grid.hex  # should not use identifier "hex" because that's a Python built-in function
honeycomb = Grid.honeycomb

##########################################################################
# constants

current_version: str = "0.0.1"


def default_major_tick_distance(grid: Grid) -> int:
    return 7 if grid in (Grid.hex, Grid.honeycomb) else 8


default_grid: Grid = Grid.none

base_width_svg: float = 10.0
"""Width of a single base in the SVG main view of scadnano."""

base_height_svg: float = 10.0
"""Height of a single base in the SVG main view of scadnano."""

distance_between_helices_svg: float = (base_width_svg * 2.5 / 0.34)
"""Distance between tops of two consecutive helices (using default positioning rules).

This is set to (base_width_svg * 2.5/0.34) based on the following calculation,
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
DNA sequence assigned to a strand is too short; the sequence is padded to make its length the same
as the length of the strand."""

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

# Substrand keys
helix_idx_key = 'helix_idx'
right_key = 'right'
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
        if close(self.svg_position[0], default_x) and close(self.svg_position[1], default_y):
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


def close(x1: float, x2: float):
    return abs(x1 - x2) < 0.000001


@dataclass
class Substrand(JSONSerializable):
    """
    A maximal portion of a :any:`Strand` that is continguous on a single :any:`Helix`.
    A :any:`Strand` contains a list of :any:`Substrand`'s.
    """

    helix_idx: int
    """:any:`Helix.idx` of the :any:`Helix` where this Substrand resides."""

    right: bool
    """Whether the strand "points" right (i.e., its 3' end has a larger offset than its 5' end)."""

    start: int
    """
    The smallest offset position of any base on this Substrand
    (3' end if :any:`Substrand.right` = ``False``,
    5' end if :any:`Substrand.right` = ``True``).
    """

    # TODO: give option to user in constructor to specify that end is inclusive (default exclusive)
    end: int
    """
    1 plus the largest offset position of any base on this Substrand
    (5' end if :any:`Substrand.right` = ``False``,
    3' end if :any:`Substrand.right` = ``True``).
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

    def to_json_serializable(self, suppress_indent=True):
        dct = OrderedDict()
        dct[helix_idx_key] = self.helix_idx
        dct[right_key] = self.right
        dct[start_key] = self.start
        dct[end_key] = self.end
        if len(self.deletions) > 0:
            dct[deletions_key] = self.deletions
        if len(self.insertions) > 0:
            dct[insertions_key] = self.insertions
        return NoIndent(dct) if suppress_indent else dct

    def dna_length(self):
        """Number of bases in this Substrand."""
        return self.end - self.start - len(self.deletions) + self._num_insertions()

    def visual_length(self):
        """Distance between left offset and right offset.

        This can be more or less than the :meth:`Substrand.dna_length` due to insertions and deletions."""
        return self.end - self.start

    def _num_insertions(self) -> int:
        # total number of insertions in this Substrand
        return sum(insertion[1] for insertion in self.insertions)

    def contains_offset(self, offset: int) -> bool:
        """Indicates if `offset` is the offset of a base on this substrand.

        Note that offsets refer to visual portions of the displayed grid for the Helix.
        If for example, this Substrand starts at position 0 and ends at 10, and it has 5 deletions,
        then it contains the offset 7 even though there is no base 7 positions from the start."""
        return self.start <= offset < self.end

    def dna_sequence(self) -> str:
        """Return DNA sequence of this Substrand."""
        return self.dna_sequence_in(self.start, self.end - 1)

    def dna_sequence_in(self, offset_left: int, offset_right: int):
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

        str_idx_left = self.offset_to_str_idx(offset_left, self.right)
        str_idx_right = self.offset_to_str_idx(offset_right, not self.right)
        if not self.right:  # these will be out of order if strand is left
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
        if self.right:
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
        return ((self.right and self.start <= offset_to_test < offset_edge) or
                (not self.right and offset_edge < offset_to_test < self.end))

    # def _between_3p_and_offset(self, offset_to_test: int, offset_edge: int) -> bool:
    #     return ((self.direction == Direction.left and self.start <= offset_to_test < offset_edge) or
    #             (self.direction == Direction.right and offset_edge < offset_to_test < self.end))

    # The type hint 'Substrand' must be in quotes since Substrand is not yet defined.
    # This is a "forward reference": https://www.python.org/dev/peps/pep-0484/#forward-references
    def overlaps(self, other: 'Substrand') -> bool:
        """Indicates if this substrand's set of offsets (the set
        :math:`\{x \in \mathbb{N} \mid`
        ``self.start``
        :math:`\leq x \leq`
        ``self.end``
        :math:`\}`)
        has nonempty intersection with those of `other`,
        and they appear on the same helix,
        and they point in opposite directions."""  # noqa (suppress PEP warning)
        return (self.helix_idx == other.helix_idx and
                self.right == (not other.right) and
                self.compute_overlap(other)[0] >= 0)

    def overlaps_illegally(self, other: 'Substrand'):
        """Indicates if this substrand's set of offsets (the set
        :math:`\{x \in \mathbb{N} \mid`
        ``self.start``
        :math:`\leq x \leq`
        ``self.end``
        :math:`\}`)
        has nonempty intersection with those of `other`,
        and they appear on the same helix,
        and they point in the same direction."""  # noqa (suppress PEP warning)
        return (self.helix_idx == other.helix_idx and
                self.right == other.right and
                self.compute_overlap(other)[0] >= 0)

    def compute_overlap(self, other: 'Substrand') -> Tuple[int, int]:
        """Return [left,right) offset indicating overlap between this Substrand and `other`.

        Return ``(-1,-1))`` if they do not overlap (different helices, or non-overlapping regions
        of the same helix)."""
        overlap_start = max(self.start, other.start)
        overlap_end = min(self.end, other.end)
        if overlap_start >= overlap_end:  # overlap is empty
            return -1, -1
        return overlap_start, overlap_end

    def insertion_offsets(self):
        """Return offsets of insertions (but not their lengths)."""
        return [ins_off for (ins_off, _) in self.insertions]


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

        scaffold_substrands = [ ... ]
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

    automatically_assign_color: bool = field(repr=False, default=True)
    """If `automatically_assign_color` = ``False`` and `color` = ``None``, do not automatically
    assign a :any:`Color` to this Strand."""

    # not serialized; efficient way to see a list of all substrands on a given helix
    _helix_idx_substrand_map: Dict[int, List[Substrand]] = field(
        init=False, repr=False, compare=False, default=None)

    def to_json_serializable(self, suppress_indent=True):
        dct = OrderedDict()
        if self.color is not None:
            dct[color_key] = self.color.to_json_serializable(suppress_indent)
        if self.dna_sequence is not None:
            dct[dna_sequence_key] = self.dna_sequence
        dct[substrands_key] = [substrand.to_json_serializable(suppress_indent) for substrand in self.substrands]
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

    def dna_length(self):
        """Return sum of DNA length of Substrands of this Strand."""
        acc = 0
        for substrand in self.substrands:
            acc += substrand.dna_length()
        return acc
        # return sum(len(substrand) for substrand in self.substrands)

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
        to be assigned via this method."""

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
                for ((overlap_left, overlap_right), substrand_other) in overlaps:
                    wildcards = DNA_base_wildcard * (overlap_left - start_idx)
                    other_seq = substrand_other.dna_sequence_in(overlap_left, overlap_right - 1)
                    overlap_complement = wc(other_seq)
                    substrand_complement_builder.append(wildcards)
                    substrand_complement_builder.append(overlap_complement)
                    start_idx = overlap_right

                # last wildcard for gap between last overlap and end
                last_wildcards = DNA_base_wildcard * (substrand_self.end - start_idx)
                substrand_complement_builder.append(last_wildcards)

                # each individual overlap sequence was reverse orientation in wc(), but not the list
                # of all of them put together until now.
                substrand_complement_builder.reverse()

                strand_complement_builder.extend(substrand_complement_builder)

        strand_complement = ''.join(strand_complement_builder)
        new_dna_sequence = strand_complement
        if self.dna_sequence is not None:
            new_dna_sequence = string_union_wildcard(self.dna_sequence, new_dna_sequence, DNA_base_wildcard)
        self.dna_sequence = new_dna_sequence


def string_union_wildcard(s1: str, s2: str, wildcard: str) -> str:
    """Takes a "union" of two equal-length strings `s1` and `s2`.
    Whenever one has a symbol `wildcard` and the other does not, the result has the non-wildcard symbol.

    Raises :py:class:`ValueError` if `s1` and `s2` are not the same length or do not agree on non-wildcard
    symbols at any position."""
    if len(s1) != len(s2):
        raise ValueError(f's1={s1} and s2={s2} are not the same length.')
    union_builder = []
    for i in range(len(s1)):
        c1, c2 = s1[i], s2[i]
        if c1 == wildcard:
            union_builder.append(c2)
        elif c2 == wildcard:
            union_builder.append(c1)
        elif c1 != c2:
            raise ValueError(f's1={s1} and s2={s2} have unequal symbols {c1} and {c2} at position {i}.')
    return ''.join(union_builder)


class IllegalDNADesignError(ValueError):
    """Indicates that some aspect of the DNADesign object is illegal."""


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
    helix_substrand_map: Dict[int, List[Substrand]] = None

    def __post_init__(self):
        if self.major_tick_distance < 0:
            self.major_tick_distance = default_major_tick_distance(self.grid)
        self._build_helix_substrand_map()
        self._check_legal_design()

    def to_json_serializable(self, suppress_indent=True):
        dct = OrderedDict()
        dct[version_key] = current_version
        if self.grid != default_grid:
            dct[grid_key] = str(self.grid)[5:] # remove prefix 'Grid.'
        if self.major_tick_distance >= 0 and (
                self.major_tick_distance != default_major_tick_distance(self.grid)):
            dct[major_tick_distance_key] = self.major_tick_distance
        dct[helices_key] = [helix.to_json_serializable(suppress_indent) for helix in self.helices]
        dct[strands_key] = [strand.to_json_serializable(suppress_indent) for strand in self.strands]
        return dct

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

    def _check_strands_overlap_legally(self):
        def err_msg(ss1, ss2, h_idx):
            return f"two substrands overlap on helix {h_idx}:" \
                f"{ss1} and {ss2} but have the same direction"

        # ensure that if two strands overlap on the same helix,
        # they point in opposite directions
        helix_idx_substrands_map: Dict[int, List[Substrand]] = defaultdict(list)
        for strand in self.strands:
            for substrand in strand.substrands:
                helix_idx_substrands_map[substrand.helix_idx].append(substrand)
        for helix_idx, substrands in helix_idx_substrands_map.items():
            if len(substrands) == 0:
                continue
            # check all consecutive substrands on the same helix, sorted by start index
            # TODO: work out a proof that it suffices to check only consecutive triples
            substrands.sort(key=lambda ss: ss.start)
            ss_prev: Substrand = substrands[0]
            for ss_idx in range(1, len(substrands)):
                ss_cur: Substrand = substrands[ss_idx]
                if ss_prev.end > ss_cur.start:
                    # overlap found! but it's okay if they point in opposite directions
                    if ss_prev.right == ss_cur.right:
                        raise IllegalDNADesignError(err_msg(ss_prev, ss_cur, helix_idx))
                    elif ss_idx + 1 < len(substrands):
                        # check next substrand to ensure don't have all three overlapping
                        ss_next: Substrand = substrands[ss_idx + 1]
                        if ss_prev.end > ss_next.start:
                            # overlap found! okay if they point in opposite directions
                            if ss_prev.right == ss_cur.right:
                                raise IllegalDNADesignError(err_msg(ss_prev, ss_next, helix_idx))
                            else:
                                # okay if prev and next are opposite, but if we're here
                                # it means prev and cur are also opposite, so cur and next
                                # are same direction, so cannot overlap
                                if ss_cur.end > ss_next.start:
                                    raise IllegalDNADesignError(err_msg(ss_cur, ss_next, helix_idx))

    def _check_strands_reference_legal_helices(self):
        # ensure each strand refers to an existing helix
        helix_idxs_set = set(helix.idx for helix in self.helices)
        for strand in self.strands:
            for substrand in strand.substrands:
                if substrand.helix_idx not in helix_idxs_set:
                    err_msg = f"substrand {substrand} refers to nonexistent Helix index {substrand.helix_idx}"
                    raise IllegalDNADesignError(err_msg)

    def substrands_at(self, helix_idx, offset):
        """Return list of substrands that overlap `offset` on helix with idx `helix_idx`.

        If constructed properly, this list should have 0, 1, or 2 elements, but no such check is done."""
        substrands_on_helix = self.helix_substrand_map[helix_idx]
        # TODO: replace this with a faster algorithm using binary search
        return [substrand for substrand in substrands_on_helix if substrand.contains_offset(offset)]

    def _build_helix_substrand_map(self):
        self.helix_substrand_map = defaultdict(list)
        for strand in self.strands:
            for substrand in strand.substrands:
                self.helix_substrand_map[substrand.helix_idx].append(substrand)

    def to_json(self, suppress_indent=True):
        """Return string representing this DNADesign, suitable for reading by scadnano if written to
        a JSON file."""
        return json_encode(self, suppress_indent)

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

    def assign_dna(self, strand: Strand, sequence: str):
        """
        Assigns `sequence` as DNA sequence of `strand`.

        If any :class:`scadnano.Strand` is bound to `strand`,
        it is assigned the reverse Watson-Crick complement of the relevant portion,
        and any remaining portions
        of the other strand are assigned to be the symbol :py:data:`DNA_base_wildcard`.

        Before assigning, `sequence` is first forced to be the same length as `strand`
        as follows:
        If `sequence` is longer, it is truncated.
        If `sequence` is shorter, it is padded with :py:data:`DNA_base_wildcard`'s.
        """
        if len(sequence) > strand.dna_length():
            sequence = sequence[:strand.dna_length()]
        elif len(sequence) < strand.dna_length():
            sequence += DNA_base_wildcard * (strand.dna_length() - len(sequence))
        strand.dna_sequence = sequence

        for other_strand in self.strands:
            if strand == other_strand:
                continue
            if other_strand.overlaps(strand):
                other_strand.assign_dna_complement_from(strand)

    def write_file(self, directory: str = '.', filename=None):
        """Write ``.dna`` file representing this DNADesign, suitable for reading by scadnano,
        with the output file having the same name as the running script but with ``.py`` changed to ``.dna``,
        unless `filename` is explicitly specified.

        For instance, if the script is named ``my_origami.py``, then the design will be written to ``my_origami.dna``.

        `directory` specifies a directory in which to place the file, either absolute or relative to
        the current working directory. Default is the current working directory.

        The string written is that returned by :meth:`DNADesign.to_json`.
        """
        if filename is None:
            filename = os.path.basename(sys.argv[0])[:-3] + '.dna'
        relative_filename = os.path.join(directory, filename)
        with open(relative_filename, 'w') as out_file:
            out_file.write(self.to_json())
