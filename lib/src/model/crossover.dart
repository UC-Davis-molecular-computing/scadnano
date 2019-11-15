import 'package:quiver/core.dart';

import 'select_mode.dart';
import 'selectable.dart';
import 'bound_substrand.dart';

import 'package:built_value/built_value.dart';

part 'crossover.g.dart';

abstract class Crossover with Selectable implements Built<Crossover, CrossoverBuilder> {
  Crossover._();
  factory Crossover([void Function(CrossoverBuilder) updates]) = _$Crossover;

  BoundSubstrand get prev_substrand;
  BoundSubstrand get next_substrand;

  register_selectables(SelectablesStore store) {
    store.register(this);
  }

  SelectModeChoice select_mode() => SelectModeChoice.crossover;

  String id() => 'crossover-${prev_substrand.id()}-${next_substrand.id()}';

}

