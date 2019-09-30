import 'package:scadnano/src/model/dna_design.dart';
import 'package:scadnano/src/model/model.dart';
import 'package:w_flux/w_flux.dart';

import 'strand.dart';
import 'model_ui.dart';

/// These are stores that reference other stores, notifying their listeners when any of those Stores update.
/// They have no Actions that mutate them directly, and only serve as "funnels" for notification.
/// Useful for parts of the view that listen to parts of the Model that are disparate in the Model tree.
_subscribe_to_stores(Store composite_store, Iterable<Store> stores) {
  for (var store in stores) {
    store.listen((_) => composite_store.trigger());
  }
}

class DNASequencesStore extends Store {
  final StrandsStore strands_store;
  final ShowDNAStore show_dna_store;

  DNASequencesStore(this.strands_store, this.show_dna_store) {
    _subscribe_to_stores(this, [this.strands_store, this.show_dna_store]);
  }
}

class MismatchesStore extends Store {
  final StrandsStore strands_store;
  final ShowMismatchesStore show_mismatches_store;

  MismatchesStore(this.strands_store, this.show_mismatches_store) {
    _subscribe_to_stores(this, [this.strands_store, this.show_mismatches_store]);
  }
}

/// Contains data about whether to show various things in Main view (DNA, mismatches, editor)
class ShowStore extends Store {
  final ShowDNAStore show_dna_store;
  final ShowMismatchesStore show_mismatches_store;
  final ShowEditorStore show_editor_store;

  ShowStore(this.show_dna_store, this.show_mismatches_store, this.show_editor_store) {
    _subscribe_to_stores(this, [this.show_dna_store, this.show_mismatches_store, this.show_editor_store]);
  }
}

// Fires when either Design or ErrorMessage updates so Design view knows to redraw.
class DesignOrErrorStore extends Store {
  DNADesign dna_design;
  ErrorMessageStore error_message_store;

  DesignOrErrorStore(this.dna_design, this.error_message_store) {
    _subscribe_to_stores(this, [this.dna_design, this.error_message_store]);
  }
}
