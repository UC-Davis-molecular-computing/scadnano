import 'package:w_flux/w_flux.dart';

import 'dna_design.dart';
import 'model.dart';
import 'strand.dart';
import 'ui_model.dart';

/// These are stores that reference other stores, notifying their listeners when any of those Stores update.
/// They have no Actions that mutate them directly, and only serve as "funnels" for notification.
/// Useful for parts of the view that listen to parts of the Model that are disparate in the Model tree.
subscribe_to_stores(Store composite_store, Iterable<Store> stores) {
  for (var store in stores) {
    store.listen((_) => composite_store.trigger());
  }
}

//class DNASequencesStore extends Store {
//  final StrandsStore strands_store;
//  final ShowDNAStore show_dna_store;
//
//  DNASequencesStore(this.strands_store, this.show_dna_store) {
//    subscribe_to_stores(this, [this.strands_store, this.show_dna_store]);
//  }
//}
//
//class MismatchesStore extends Store {
//  final StrandsStore strands_store;
//  final ShowMismatchesStore show_mismatches_store;
//
//  MismatchesStore(this.strands_store, this.show_mismatches_store) {
//    subscribe_to_stores(this, [this.strands_store, this.show_mismatches_store]);
//  }
//}
//
///// Contains data about whether to show various things in Main view (DNA, mismatches, editor)
//class ShowStore extends Store {
//  final ShowDNAStore show_dna_store;
//  final ShowMismatchesStore show_mismatches_store;
//  final ShowEditorStore show_editor_store;
//
//  ShowStore(this.show_dna_store, this.show_mismatches_store, this.show_editor_store) {
//    subscribe_to_stores(this, [this.show_dna_store, this.show_mismatches_store, this.show_editor_store]);
//  }
//}
//
//// Fires when either Design or ErrorMessage updates so Design view knows to redraw.
//class DesignOrErrorStore extends Store {
//  DNADesign dna_design;
//  ErrorMessageStore error_message_store;
//
//  DesignOrErrorStore(this.dna_design, this.error_message_store) {
//    subscribe_to_stores(this, [this.dna_design, this.error_message_store]);
//  }
//}







//
//// Crossover components listen to this on the BoundSubstrands on either end of them.
//class CrossoverStore extends Store with Selectable<CrossoverStore> {
//  BoundSubstrand prev_substrand;
//  BoundSubstrand next_substrand;
//  CrossoverUIModel crossover_ui_model;
//
//  CrossoverStore(this.prev_substrand, this.next_substrand, this.crossover_ui_model) {
//    _subscribe_to_stores(this, [this.prev_substrand, this.next_substrand]);
//
//    trigger_on_select_toggle_actions(() => app.model.main_view_ui_model.selection.crossovers);
//
//    Actions.crossover_select_toggle.listen((pair) {
//      if (pair.item1 == prev_substrand && pair.item2 == next_substrand) {
//        crossover_ui_model.selected = !crossover_ui_model.selected;
//        this.trigger();
//      }
//    });
//
//    Actions.remove_all_selections.listen((_) {
//      if (this.crossover_ui_model.selected) {
//        this.crossover_ui_model.selected = false;
//        trigger();
//      }
//    });
//  }
//}


