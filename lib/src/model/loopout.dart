import '../app.dart';
import 'strand.dart';
import 'strand_ui_model.dart';
import 'selectable.dart';
import '../constants.dart' as constants;
import '../util.dart' as util;

class Loopout extends Substrand with Selectable<Loopout> {
  int loopout_length;

  Loopout(this.loopout_length) {
    this._handle_actions();
  }

  _handle_actions() {
    trigger_on_select_toggle_actions(() => app.model.main_view_ui_model.selection.loopouts);

//    this.trigger_on_action_if_this(Actions.loopout_select_toggle, (_) {
//      this.ui_model.selected = !this.ui_model.selected;
//    });
//    Actions.remove_all_selections.listen((_) {
//      if (this.ui_model.selected) {
//        this.ui_model.selected = false;
//        trigger();
//      }
//    });

  }

  String toString() => 'Loopout(${this.loopout_length})';

  bool is_loopout() => true;

  int dna_length() => this.loopout_length;

  String dna_sequence() {
    String strand_seq = this.strand.dna_sequence;
    if (strand_seq == null) {
      return null;
    }

    int str_idx_left = this.get_seq_start_idx();
    int str_idx_right = str_idx_left + this.loopout_length; // EXCLUSIVE (unlike similar code for Substrand)
    String subseq = strand_seq.substring(str_idx_left, str_idx_right);
    return subseq;
  }

  /// Starting DNA subsequence index for first base of this :any:`Loopout` on its Parent
  /// :any:`Strand`'s DNA sequence.
  int get_seq_start_idx() {
    List<Substrand> substrands = this.strand.substrands;
    // index of self in parent strand's list of substrands
    int self_substrand_idx = substrands.indexOf(this);
    // index of self's position within the DNA sequence of parent strand
    int self_seq_idx_start = 0;
    for (Substrand prev_substrand in substrands.sublist(0, self_substrand_idx)) {
      self_seq_idx_start += prev_substrand.dna_length();
    }
    return self_seq_idx_start;
  }

  Loopout.from_json(Map<String, dynamic> json_map) {
    this._handle_actions();
    var name = 'Loopout';
    this.loopout_length = util.get_value(json_map, constants.loopout_key, name);
  }

  Map<String, dynamic> to_json_serializable() {
    var json_map = {
      constants.loopout_key: this.loopout_length,
    };
    return json_map;
  }
}
