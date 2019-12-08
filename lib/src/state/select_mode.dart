import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:built_collection/built_collection.dart';

part 'select_mode.g.dart';

class SelectModeChoice extends EnumClass {
  const SelectModeChoice._(String name) : super(name);

  static Serializer<SelectModeChoice> get serializer => _$selectModeChoiceSerializer;

  static const SelectModeChoice end_5p_strand = _$end_5p_strand;
  static const SelectModeChoice end_3p_strand = _$end_3p_strand;
  static const SelectModeChoice end_5p_substrand = _$end_5p_substrand;
  static const SelectModeChoice end_3p_substrand = _$end_3p_substrand;
  static const SelectModeChoice crossover = _$crossover;
  static const SelectModeChoice loopout = _$loopout;
  static const SelectModeChoice strand = _$strand;
  static const SelectModeChoice scaffold = _$scaffold;
  static const SelectModeChoice staple = _$staple;

  static BuiltSet<SelectModeChoice> get values => _$values;

  static SelectModeChoice valueOf(String name) => _$valueOf(name);

  String to_json() => name;

  String display_name() {
    if (this == end_5p_strand) {
      return "5' strand";
    } else if (this == end_3p_strand) {
      return "3' strand";
    } else if (this == end_5p_substrand) {
      return "5' (other)";
    } else if (this == end_3p_substrand) {
      return "3' (other)";
    } else {
      return super.toString();
    }
  }

  @override
  String toString() => display_name();

//  static const end_5p_strand = SelectModeChoice._("5' strand", 'five-prime-end-first-substrand');
//  static const end_3p_strand = SelectModeChoice._("3' strand", 'three-prime-end-last-substrand');
//  static const end_5p_substrand = SelectModeChoice._("5' (other)", 'five-prime-end');
//  static const end_3p_substrand = SelectModeChoice._("3' (other)", 'three-prime-end');
//  static const crossover = SelectModeChoice._('crossover', 'crossover-curve');
//  static const loopout = SelectModeChoice._('loopout', 'loopout-line');
//  static const strand = SelectModeChoice._('strand', 'strand');
//  static const scaffold = SelectModeChoice._('scaffold', 'scaffold');
//  static const staple = SelectModeChoice._('staple', 'staple');

  String css_selector() {
    switch (this) {
      case end_5p_strand:
        return 'five-prime-end-first-substrand';
      case end_3p_strand:
        return 'three-prime-end-last-substrand';
      case end_5p_substrand:
        return 'five-prime-end';
      case end_3p_substrand:
        return 'three-prime-end';
      case crossover:
        return 'crossover-curve';
      case loopout:
        return 'loopout-line';
      case strand:
        return 'strand';
      case scaffold:
        return 'scaffold';
      case staple:
        return 'staple';
    }
    throw AssertionError('should not be reachable; unknown SelectModeChoice used: ${this}');
  }

  static SelectModeChoice from_json(String json_name) => valueOf(json_name);

  static final BuiltList<SelectModeChoice> all_choices =
      BuiltList<SelectModeChoice>(non_origami_choices.toList() + [scaffold, staple]);

  static final BuiltList<SelectModeChoice> non_origami_choices =
      BuiltList<SelectModeChoice>(strand_parts.toList() + [strand]);

  static final BuiltList<SelectModeChoice> strand_parts = BuiltList<SelectModeChoice>([
    end_5p_strand,
    end_3p_strand,
    end_5p_substrand,
    end_3p_substrand,
    crossover,
    loopout,
  ]);

  static final BuiltList<SelectModeChoice> ends = BuiltList<SelectModeChoice>([
    end_5p_strand,
    end_3p_strand,
    end_5p_substrand,
    end_3p_substrand,
  ]);

}
