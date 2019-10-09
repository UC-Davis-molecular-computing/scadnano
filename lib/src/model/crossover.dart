import 'package:quiver/core.dart';
import 'package:scadnano/src/model/composite_stores.dart';
import 'package:w_flux/w_flux.dart';

import '../app.dart';
import 'selectable.dart';
import 'bound_substrand.dart';


class Crossover extends Store with Selectable<Crossover> {
  BoundSubstrand prev_substrand;
  BoundSubstrand next_substrand;

  Crossover(this.prev_substrand, this.next_substrand){
    _handle_actions();
  }

  _handle_actions() {
    subscribe_to_stores(this, [prev_substrand, next_substrand]);
    trigger_on_select_toggle_actions(() => app.model.main_view_ui_model.selection.crossovers);
  }

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
//  int get hashCode => hash2(this.prev_substrand, this.next_substrand);
  int get hashCode {
    return hash2(this.prev_substrand, this.next_substrand);
  }

}

/*

// Crossover components listen to this on the BoundSubstrands on either end of them.
class CrossoverStore extends Store with Selectable<CrossoverStore> {
  BoundSubstrand prev_substrand;
  BoundSubstrand next_substrand;
  CrossoverUIModel crossover_ui_model;

  CrossoverStore(this.prev_substrand, this.next_substrand, this.crossover_ui_model) {
    _subscribe_to_stores(this, [this.prev_substrand, this.next_substrand]);

    trigger_on_select_toggle_actions(() => app.model.main_view_ui_model.selection.crossovers);

    Actions.crossover_select_toggle.listen((pair) {
      if (pair.item1 == prev_substrand && pair.item2 == next_substrand) {
        crossover_ui_model.selected = !crossover_ui_model.selected;
        this.trigger();
      }
    });

    Actions.remove_all_selections.listen((_) {
      if (this.crossover_ui_model.selected) {
        this.crossover_ui_model.selected = false;
        trigger();
      }
    });
  }
}

 */
