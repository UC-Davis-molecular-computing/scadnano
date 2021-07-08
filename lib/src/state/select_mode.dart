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
  static const SelectModeChoice strand = _$strand;
  static const SelectModeChoice deletion = _$deletion;
  static const SelectModeChoice insertion = _$insertion;
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

  static final BuiltList<SelectModeChoice> all_choices =
      BuiltList<SelectModeChoice>(non_origami_choices.toList() + [scaffold, staple]);

  static final BuiltList<SelectModeChoice> non_origami_choices =
      BuiltList<SelectModeChoice>([strand] + strand_parts.toList());

  static final BuiltList<SelectModeChoice> strand_parts = BuiltList<SelectModeChoice>([
    domain,
    end_5p_strand,
    end_3p_strand,
    end_5p_domain,
    end_3p_domain,
    crossover,
    loopout,
    deletion,
    insertion,
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
