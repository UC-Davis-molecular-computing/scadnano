import 'package:scadnano/src/dispatcher/actions.dart';
import 'package:w_flux/w_flux.dart';

import 'helix.dart';
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
    Helix helix = app.model.dna_design.helices[this.helix_idx];
    var ret = MouseoverData(helix, this.offset, substrand);
    return ret;
  }
}

class MouseoverData {
  final Helix helix;
  final int offset;
  final BoundSubstrand substrand;

  MouseoverData([this.helix = null, this.offset = null, this.substrand = null]);

  String toString() =>
      'MouseoverData(helix=${this.helix.idx()}, offset=${this.offset}, substrand=${this.substrand})';
}


class MouseoverDataStore extends Store {

  MouseoverData _data = null;

  MouseoverData get data => this._data;

  MouseoverDataStore() {
    triggerOnActionV2<MouseoverParameters>(
        Actions.update_mouseover_data, (params) => this._data = params.mouseover_data());
    triggerOnActionV2<Null>(Actions.remove_mouseover_data, (_) => this._data = null);

    // don't need to update any data, but want to alert listeners that data has changed; this helps to
    // see the new rotation right away instead of waiting for a mouse move
    triggerOnActionV2<SetHelixRotationActionParameters>(Actions.set_helix_rotation);
  }
}
