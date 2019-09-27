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

class MouseoverActions {
  final Action<MouseoverParameters> update_data = Action<MouseoverParameters>();
  final Action<Null> remove_data = Action<Null>();
}

class MouseoverDataStore extends Store {
  MouseoverActions _actions = MouseoverActions();

  Action<MouseoverParameters> get update_data => this._actions.update_data;

  Action<Null> get remove_data => this._actions.remove_data;

  MouseoverData _data = null;

  MouseoverData get data => this._data;

  MouseoverDataStore() {
    triggerOnActionV2<MouseoverParameters>(
        this._actions.update_data, (params) => this._data = params.mouseover_data());
    triggerOnActionV2<Null>(this._actions.remove_data, (_) => this._data = null);
  }
}
