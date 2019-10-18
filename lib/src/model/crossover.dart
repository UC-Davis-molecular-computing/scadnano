import 'package:quiver/core.dart';
import 'package:scadnano/src/model/composite_stores.dart';
import 'package:w_flux/w_flux.dart';

import '../app.dart';
import 'select_mode.dart';
import 'selectable.dart';
import 'bound_substrand.dart';


class Crossover //extends Store
    with Selectable {
  BoundSubstrand prev_substrand;
  BoundSubstrand next_substrand;

  Crossover(this.prev_substrand, this.next_substrand);

  register_selectables(SelectablesStore store) {
    store.register(this);
  }

  SelectModeChoice select_mode() => SelectModeChoice.crossover;

  String id() => 'crossover-${prev_substrand.id()}-${next_substrand.id()}';

  @override
  bool operator ==(other) {
    if (!(other is Crossover)) {
      return false;
    }
    Crossover other_crossover = other;
    return this.prev_substrand == other_crossover.prev_substrand &&
        this.next_substrand == other_crossover.next_substrand;
  }

  @override
  int get hashCode => hash2(this.prev_substrand, this.next_substrand);

}
