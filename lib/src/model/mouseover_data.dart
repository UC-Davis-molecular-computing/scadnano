import 'package:scadnano/src/dispatcher/actions.dart';
import 'package:tuple/tuple.dart';
import 'package:w_flux/w_flux.dart';

import 'helix.dart';
import 'strand.dart';
import '../app.dart';

/// Converts from raw mouseover data (helix, offset, forward) to data user wants to see in the footer (substrand)
class MouseoverParameters {
  // each tuple is (helix_idx, offset, forward)
  final List<Tuple3<int, int, bool>> param_list;

  MouseoverParameters(this.param_list);

  List<MouseoverData> mouseover_data() {
    BoundSubstrand substrand = null;
    List<MouseoverData> mouseover_datas = [];
    for (Tuple3<int, int, bool> param in this.param_list) {
      int helix_idx = param.item1;
      int offset = param.item2;
      bool forward = param.item3;
      for (Substrand ss in app.model.dna_design.substrands_on_helix(helix_idx)) {
        if (ss.is_bound_substrand()) {
          var bound_ss = ss as BoundSubstrand;
          if (bound_ss.contains_offset(offset) && bound_ss.forward == forward) {
            substrand = ss;
            break;
          }
        }
      }
      Helix helix = app.model.dna_design.helices[helix_idx];
      mouseover_datas.add(MouseoverData(helix, offset, substrand));
    }
    return mouseover_datas;
  }
}

class MouseoverData {
  final Helix helix;
  final int offset;
  final BoundSubstrand substrand;

  MouseoverData(this.helix, this.offset, this.substrand);

  String toString() =>
      'MouseoverData(helix=${this.helix.idx()}, offset=${this.offset}, substrand=${this.substrand})';
}

class MouseoverDataStore extends Store {
  List<MouseoverData> _data = [];

  List<MouseoverData> get data => this._data;

  MouseoverDataStore() {
    triggerOnActionV2<MouseoverParameters>(Actions.update_mouseover_data, (params) {
      this._data = params.mouseover_data();
    });
    triggerOnActionV2<Null>(Actions.remove_mouseover_data, (_) => this._data = []);

    // don't need to update any data, but want to alert listeners that data has changed; this helps to
    // see the new rotation right away instead of waiting for a mouse move
    triggerOnActionV2<SetHelixRotationActionParameters>(Actions.set_helix_rotation);
  }
}
