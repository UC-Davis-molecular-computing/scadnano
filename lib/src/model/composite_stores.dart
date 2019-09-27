import 'package:w_flux/w_flux.dart';

import 'strand.dart';
import 'model_ui.dart';

/// These are stores that reference other stores, notifying their listeners when any of those Stores update.
/// Useful for parts of the view that listen to disparate parts of the Model.

_subscribe_to_stores(Store composite_store, Iterable<Store> stores) {
  for (Store store in stores) {
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