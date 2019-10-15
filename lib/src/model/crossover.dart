import 'package:quiver/core.dart';
import 'package:scadnano/src/model/composite_stores.dart';
import 'package:w_flux/w_flux.dart';

import '../app.dart';
import 'select_mode.dart';
import 'selectable.dart';
import 'bound_substrand.dart';


class Crossover extends Store with Selectable {
  BoundSubstrand prev_substrand;
  BoundSubstrand next_substrand;

  Crossover(this.prev_substrand, this.next_substrand);

  handle_actions() {
    subscribe_to_stores(this, [prev_substrand, next_substrand]);
  }

  register_selectables(SelectableStore store) {
    store.register(this);
  }

  //TODO: Crossover.trigger() gets called when a 5'/3' end "near" it is selected
//  trigger() {
//    print('calling Crossover.trigger() on ${id()}');
//    super.trigger();
//  }

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
