import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:built_collection/built_collection.dart';

import '../constants.dart' as constants;

part 'select_mode.g.dart';

class SelectModeChoice extends EnumClass {
  const SelectModeChoice._(String name) : super(name);

  static Serializer<SelectModeChoice> get serializer => _$selectModeChoiceSerializer;

  static const SelectModeChoice end_5p_strand = _$end_5p_strand;
  static const SelectModeChoice end_3p_strand = _$end_3p_strand;
  static const SelectModeChoice end_5p_domain = _$end_5p_substrand;
  static const SelectModeChoice end_3p_domain = _$end_3p_substrand;
  static const SelectModeChoice domain = _$domain;
  static const SelectModeChoice crossover = _$crossover;
  static const SelectModeChoice loopout = _$loopout;
  static const SelectModeChoice extension_ = _$extension_; // extension is reserved keyword
  static const SelectModeChoice strand = _$strand;
  static const SelectModeChoice insertion = _$insertion;
  static const SelectModeChoice deletion = _$deletion;
  static const SelectModeChoice modification = _$modification;
  static const SelectModeChoice scaffold = _$scaffold;
  static const SelectModeChoice staple = _$staple;

  static BuiltSet<SelectModeChoice> get values => _$values;

  static SelectModeChoice valueOf(String name) => _$valueOf(name);

  String to_json() => name;

  @memoized
  String get display_name {
    if (this == end_5p_strand) {
      return "5' strand";
    } else if (this == end_3p_strand) {
      return "3' strand";
    } else if (this == end_5p_domain) {
      return "5' domain";
    } else if (this == end_3p_domain) {
      return "3' domain";
    } else {
      return super.toString();
    }
  }

  @override
  String toString() => display_name;

  @memoized
  String get image_file {
    // edit this to display a different string than the identifier name above
    switch (this) {
      case end_5p_strand:
        return 'images/select_mode_icons/5pstrand.svg';
      case end_3p_strand:
        return 'images/select_mode_icons/3pstrand.svg';
      case end_5p_domain:
        return 'images/select_mode_icons/5pdomain.svg';
      case end_3p_domain:
        return 'images/select_mode_icons/3pdomain.svg';
      case domain:
        return 'images/select_mode_icons/domain.svg';
      case crossover:
        return 'images/select_mode_icons/crossover.svg';
      case loopout:
        return 'images/select_mode_icons/loopout.svg';
      case extension_:
        return 'images/select_mode_icons/extension.svg';
      case deletion:
        return 'images/select_mode_icons/del.svg';
      case insertion:
        return 'images/select_mode_icons/inser.svg';
      case modification:
        return 'images/select_mode_icons/mod.svg';
      case strand:
        return 'images/select_mode_icons/strand.svg';
      case scaffold:
        return 'images/select_mode_icons/scaffold.svg';
      case staple:
        return 'images/select_mode_icons/staple.svg';
    }
    return '';
  }

  @memoized
  String get tooltip {
    // returns a toolip description
    switch (this) {
      case end_5p_strand:
        return '''\
5' strand: Allows one to select the 5' end (square) of a whole strand. If many
5' ends are selected, then one can add a 5' modification to all of them
by right-clicking and selecting "add modification". This will add only to
the type of modification picked. For example, if both 5' and 3' ends are
selected, and a 5' modification is added, then only the 5' ends are
modified.''';
      case end_3p_strand:
        return '''\
3' strand: Allows one to select the 3' end (triangle) of a whole strand. If 
many 3' ends are selected, then one can add a 3' modification to all of them
by right-clicking and selecting "add modification". This will add only to
the type of modification picked. For example, if both 5' and 3' ends are
selected, and a 3' modification is added, then only the 3' ends are
modified.''';
      case end_5p_domain:
        return '''\
5' domain: Each strand is composed of one or more bound domains, defined to 
be a portion of a strand that exists on a single helix. A 5'/3' end of a bound 
domain that is not the 5'/3' end of the whole strand is one of these. They are 
not normally visible, but when these select modes are enabled, they become 
visible on mouseover and can be selected and dragged. Deleting a 5'/3' 
end of a bound domain deletes the whole bound domain. Ends can be moved, but 
unlike strands and domains, they can only be moved back and forth along their
current helix.''';
      case end_3p_domain:
        return '''\
3' domain: Each strand is composed of one or more bound domains, defined to 
be a portion of a strand that exists on a single helix. A 5'/3' end of a bound 
domain that is not the 5'/3' end of the whole strand is one of these. They are 
not normally visible, but when these select modes are enabled, they become 
visible on mouseover and can be selected and dragged. Deleting a 5'/3' 
end of a bound domain deletes the whole bound domain. Ends can be moved, but 
unlike strands and domains, they can only be moved back and forth along their
current helix.''';
      case domain:
        return '''\
domain: A single bound domain can be selected. Groups of domains can be
moved, but only if they are all in the same helix group. (Though they can be
moved to a different helix group.)
[Alt+O or Alt+D (Alt+D has another behavior in Chrome that pops up a window)]''';
      case crossover:
        return '''\
crossover: Two consecutive bound domains on a strand can be joined by a
crossover, which consists of no DNA bases (Technically bound domains do not
have to be bound to another strand, but the idea is that generally in a
finished design, most of the bound domains will actually be bound to
another.)

If many crossovers/loopouts are selected, all the crossovers can be
converted to loopouts (or vice versa) by right-clicking on one of them and
picking "convert to loopout" (or "change loopout length" if a loopout;
changing to length 0 converts it to a crossover).
[Alt+C]''';
      case loopout:
        return '''\
loopout: Two consecutive bound domains on a strand can be joined by a loopout,
which is a single-stranded portion of the strand with one or more DNA bases.
(Technically bound domains do not have to be bound to another strand, but the
idea is that generally in a finished design, most of the bound domains will
actually be bound to another.)

If many crossovers/loopouts are selected, all the crossovers can be
converted to loopouts (or vice versa) by right-clicking on one of them and
picking "convert to loopout" (or "change loopout length" if a loopout;
changing to length 0 converts it to a crossover).
[Alt+L]''';
      case extension_:
        return '''\
extension: An extension is a single-stranded portion of a strand that is not on a
Helix (like a domain) and does not connect two domains. It is like a loopout but on
the end of a strand, useful for modeling toeholds for DNA strand displacement, 
for instance.
[Alt+X]''';
      case deletion:
        return '''\
deletion: Deletions can be selected and deleted in batch by pressing the Delete key.''';
      case insertion:
        return '''\
insertion: Insertions can be selected and deleted in batch by pressing the
Delete key. Also, one can change the length of all selected insertions by
right-clicking on one of them and selecting the option to change
insertion length.
[Alt+I]''';
      case modification:
        return '''\
modification: If many modifications are selected, they can be deleted at once
by pressing the Delete key (or right-clicking and selecting "remove
modification"). Those of a similar type (5', 3', or internal) can be modified
in batch by right-clicking on one of them and selecting "edit modification".
[Alt+M]''';
      case strand:
        return '''\
strand: The whole strand can be selected. Groups of strands can be copy/pasted or 
moved, but only if they are all in the same helix group. (Though they can be 
copied/moved to a different helix group.)
[Alt+S]''';
      case scaffold:
        return '''\
scaffold: This option allows one to select scaffold strands. The option is 
not shown in a non-origami design.''';
      case staple:
        return '''\
staple: All non-scaffold strands are called staples. This option allows one
to select staples. The option is not shown in a non-origami design.''';
    }
    return '';
  }

  static String get all_ends_image_file => 'images/select_mode_icons/allends.svg';

  static String get all_ends_tooltip => '''all ends: Selects all of 5' strand, 3'
strand, 5' domain, 3' domain.
[Alt+E]''';

  String css_selector() {
    switch (this) {
      case end_5p_strand:
        return constants.css_selector_end_5p_strand;
      case end_3p_strand:
        return constants.css_selector_end_3p_strand;
      case end_5p_domain:
        return constants.css_selector_end_5p_domain;
      case end_3p_domain:
        return constants.css_selector_end_3p_domain;
      case domain:
        return constants.css_selector_domain;
      case crossover:
        return constants.css_selector_crossover;
      case loopout:
        return constants.css_selector_loopout;
      case extension_:
        return constants.css_selector_extension;
      case deletion:
        return constants.css_selector_deletion;
      case insertion:
        return constants.css_selector_insertion;
      case modification:
        return constants.css_selector_modification;
      case strand:
        return constants.css_selector_strand;
      case scaffold:
        return constants.css_selector_scaffold;
      case staple:
        return constants.css_selector_staple;
    }
    throw AssertionError('should not be reachable; unknown SelectModeChoice used: ${this}');
  }

  static SelectModeChoice from_json(String json_name) => valueOf(json_name);

  static final BuiltList<SelectModeChoice> all_choices = BuiltList<SelectModeChoice>(
    non_origami_choices.toList() + [scaffold, staple],
  );

  static final BuiltList<SelectModeChoice> non_origami_choices = BuiltList<SelectModeChoice>(
    [strand] + strand_parts.toList(),
  );

  static final BuiltList<SelectModeChoice> strand_parts = BuiltList<SelectModeChoice>([
    domain,
    end_5p_strand,
    end_3p_strand,
    end_5p_domain,
    end_3p_domain,
    crossover,
    loopout,
    extension_,
    insertion,
    deletion,
    modification,
  ]);

  static final BuiltList<SelectModeChoice> ends = BuiltList<SelectModeChoice>([
    end_5p_strand,
    end_3p_strand,
    end_5p_domain,
    end_3p_domain,
  ]);

  static final BuiltList<SelectModeChoice> ends_on_origami = BuiltList<SelectModeChoice>([
    end_5p_strand,
    end_3p_strand,
    end_5p_domain,
    end_3p_domain,
    scaffold,
    staple,
  ]);
}
