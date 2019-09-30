import 'package:scadnano/src/dispatcher/actions.dart';
import 'package:w_flux/w_flux.dart';

import 'strand.dart';
import '../app.dart';

/// Converts from raw mouseover data (helix, offset, forward) to data user wants to see in the footer (substrand)
class MouseoverParameters {
  final int helix_idx;
  final int offset;
  final bool forward;

  MouseoverParameters(this.helix_idx, this.offset, this.forward);

  MouseoverData mouseover_data() {
    BoundSubstrand substrand = null;
    for (Substrand ss in app.model.dna_design.substrands_on_helix(this.helix_idx)) {
      if (ss.is_bound_substrand()) {
        var bound_ss = ss as BoundSubstrand;
        if (bound_ss.contains_offset(this.offset) && bound_ss.forward == this.forward) {
          substrand = ss;
          break;
        }
      }
    }
    var ret = MouseoverData(this.helix_idx, this.offset, substrand);
    return ret;
  }
}

class MouseoverData {
  final int helix_idx;
  final int offset;
  final BoundSubstrand substrand;

  MouseoverData([this.helix_idx = null, this.offset = null, this.substrand = null]);

  String toString() =>
      'MouseoverData(helix=${this.helix_idx}, offset=${this.offset}, substrand=${this.substrand})';
}


class MouseoverDataStore extends Store {

  Action<MouseoverParameters> get update_mouseover_data => Actions.update_mouseover_data;

  Action<Null> get remove_mouseover_data => Actions.remove_mouseover_data;

  MouseoverData _data = null;

  MouseoverData get data => this._data;

  MouseoverDataStore() {
    triggerOnActionV2<MouseoverParameters>(
        this.update_mouseover_data, (params) => this._data = params.mouseover_data());
    triggerOnActionV2<Null>(this.remove_mouseover_data, (_) => this._data = null);
  }
}
