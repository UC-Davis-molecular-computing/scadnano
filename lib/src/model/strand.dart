import 'package:color/color.dart';
import 'package:react/react.dart';
import 'package:tuple/tuple.dart';
import 'package:w_flux/w_flux.dart';

import '../dispatcher/actions.dart';
import 'select_mode.dart';
import 'selectable.dart';
import 'crossover.dart';
import 'strand_ui_model.dart';
import '../json_serializable.dart';
import '../constants.dart' as constants;
import '../util.dart' as util;
import 'dna_design.dart';
import 'bound_substrand.dart';
import 'loopout.dart';

class StrandsStore extends Store {
  List<Strand> _strands;

  List<Strand> get strands => this._strands;

  set strands(List<Strand> new_strands) {
    this._strands = new_strands;
  }

  StrandsStore() {
    this._strands = [];
    _handle_actions();
  }

  _handle_actions() {
    triggerOnActionV2(Actions.select);
    triggerOnActionV2(Actions.select_all);
    triggerOnActionV2(Actions.unselect);
    triggerOnActionV2(Actions.toggle);
    triggerOnActionV2(Actions.toggle_all);
    triggerOnActionV2(Actions.unselect_all);
  }

}

//class Strand extends SelfListeningStore implements JSONSerializable {
class Strand with Selectable implements JSONSerializable {
  static Color DEFAULT_STRAND_COLOR = RgbColor.name('black');

  Color color = null;
  String dna_sequence = null;
  List<Substrand> substrands = [];
  IDTFields idt = null;

  StrandUIModel ui_model;

  Map<Tuple2<BoundSubstrand, BoundSubstrand>, Crossover> crossovers = {};

  Strand([this.substrands, this.color, this.dna_sequence]) {
    this.ui_model = StrandUIModel(this);
//    this.handle_actions();
    this._build_crossovers();
  }

//  handle_actions() {
////    this.register_selectable(() => app.model.main_view_ui_model.selection.strands);
//    for (var ss in substrands) {
//      ss.handle_actions();
//    }
//    for (var crossover in crossovers.values) {
//      crossover.handle_actions();
//    }
//  }

  register_selectables(SelectablesStore store) {
    store.register(this);
    for (var ss in substrands) {
      ss.register_selectables(store);
    }
    for (var crossover in crossovers.values) {
      crossover.register_selectables(store);
    }
  }

//  trigger() {
//    print('calling Strand.trigger() on ${id()}');
//    super.trigger();
//  }

  _build_crossovers() {
    this.crossovers.clear();
    for (int i = 0; i < substrands.length - 1; i++) {
      var prev_ss = substrands[i];
      var next_ss = substrands[i + 1];
      if (prev_ss is BoundSubstrand && next_ss is BoundSubstrand) {
        var pair = Tuple2<BoundSubstrand, BoundSubstrand>(prev_ss, next_ss);
        crossovers[pair] = Crossover(prev_ss, next_ss);
      }
    }
  }

  SelectModeChoice select_mode() => SelectModeChoice.strand;

  String id() {
    var first_ss = this.first_bound_substrand();
    return 'strand-H${first_ss.helix}-${first_ss.offset_5p}-${first_ss.forward ? 'forward' : 'reverse'}';
  }

  String toString() {
    var first_ss = this.first_bound_substrand();
    return 'Strand(helix=${first_ss.helix}, start=${first_ss.offset_5p}, ${first_ss.forward ? 'forward' : 'reverse'})';
  }

  List<BoundSubstrand> bound_substrands() => [for (var ss in this.substrands) if (ss.is_bound_substrand()) ss];

  List<BoundSubstrand> loopouts() => [for (var ss in this.substrands) if (ss.is_loopout()) ss];

  int dna_length() {
    int num = 0;
    for (var substrand in substrands) {
      num += substrand.dna_length();
    }
    return num;
  }

  Map<String, dynamic> to_json_serializable() {
    var json_map = Map<String, dynamic>();

    if (this.color != null) {
      json_map[constants.color_key] = NoIndent(this.color.toRgbColor().toMap());
    }

    if (this.dna_sequence != null) {
      json_map[constants.dna_sequence_key] = this.dna_sequence;
    }

    if (this.idt != null) {
      json_map[constants.dna_sequence_key] = NoIndent(this.idt.to_json_serializable());
    }

    json_map[constants.substrands_key] = [for (var ss in this.substrands) ss.to_json_serializable()];

    return json_map;
  }

  Strand.from_json(Map<String, dynamic> json_map) {
    this.ui_model = StrandUIModel(this);

    // need to use List.from because List.map returns Iterable, not List
    var name = 'Strand';
    this.substrands = List<Substrand>.from(util
        .get_value(json_map, constants.substrands_key, name)
        .map((substrand_json) => Substrand.from_json(substrand_json)));
    for (var substrand in this.substrands) {
      substrand.strand = this;
    }

    if (json_map.containsKey(constants.color_key)) {
      this.color = parse_json_color(json_map[constants.color_key]);
    } else {
      this.color = DEFAULT_STRAND_COLOR;
    }

    this.dna_sequence = json_map.containsKey(constants.dna_sequence_key) ? json_map[constants.dna_sequence_key] : null;
    if (this.dna_sequence != null) {
      int seq_len = this.dna_sequence.length;
      int dna_len_strand = this.dna_length();
      if (seq_len != dna_len_strand) {
        throw StrandError(this, 'Strand length $dna_len_strand does not match DNA sequence length $seq_len');
      }
    }

    if (json_map.containsKey(constants.idt_key)) {
      try {
        this.idt = IDTFields.from_json(json_map[constants.idt_key]);
      } catch (err) {
        throw StrandError(this, err.toString());
      }
    }

    if (this.substrands.first is Loopout) {
      throw StrandError(this, 'Loopout at beginning of strand not supported');
    }

    if (this.substrands.last is Loopout) {
      throw StrandError(this, 'Loopout at end of strand not supported');
    }

    _build_crossovers();

    //XXX: need to handle actions for each Strand sub-component at the end,
    // because it requires registering id's with a glboal map, which don't exist
    // until the whole Strand is created.
//    handle_actions();
  }

  BoundSubstrand first_bound_substrand({int starting_at = 0}) {
    for (int i = starting_at; i < this.substrands.length; i++) {
      if (this.substrands[i] is BoundSubstrand) {
        return this.substrands[i];
      }
    }
    throw AssertionError('should not be reachable');
  }

  BoundSubstrand last_bound_substrand() {
    if (this.substrands.last is BoundSubstrand) {
      return (this.substrands.last as BoundSubstrand);
    } else {
      int len = this.substrands.length;
      assert(len >= 2);
      assert(this.substrands[len - 2] is BoundSubstrand);
      return (this.substrands[len - 2] as BoundSubstrand);
    }
  }
}

abstract class Substrand // extends Store
    implements JSONSerializable {
  // for efficiency but not serialized since it would introduce a JSON cycle
  Strand strand;

  int dna_length();

  bool is_loopout();

  bool is_bound_substrand() => !this.is_loopout();

  String dna_sequence();

  static Substrand from_json(Map<String, dynamic> json_map) {
    if (json_map.containsKey(constants.loopout_key)) {
      return Loopout.from_json(json_map);
    } else {
      return BoundSubstrand.from_json(json_map);
    }
  }

  /// Order this substrand appears in the Strand
  int order() => strand.substrands.indexOf(this);

//  handle_actions();

  register_selectables(SelectablesStore store);
}

class IDTFields implements JSONSerializable {
  String name;
  String scale;
  String purification;
  String plate;
  String well;

  IDTFields(this.name, this.scale, this.purification);

  Map<String, dynamic> to_json_serializable() {
    Map<String, dynamic> json_map = {
      constants.idt_name_key: this.name,
      constants.idt_scale_key: this.scale,
      constants.idt_purification_key: this.purification
    };
    if (this.plate != null) {
      json_map[constants.idt_plate_key] = this.plate;
    }
    if (this.well != null) {
      json_map[constants.idt_well_key] = this.well;
    }
    return json_map;
  }

  IDTFields.from_json(Map<String, dynamic> json_map) {
    var field_name = 'IDTFields';
    this.name = util.get_value(json_map, constants.idt_name_key, field_name);
    this.scale = util.get_value(json_map, constants.idt_scale_key, field_name);
    this.purification = util.get_value(json_map, constants.idt_purification_key, field_name);
    if (json_map.containsKey(constants.idt_plate_key)) {
      this.plate = json_map[constants.idt_plate_key];
    }
    if (json_map.containsKey(constants.idt_scale_key)) {
      this.scale = json_map[constants.idt_scale_key];
    }
    if (this.plate == null && this.well != null) {
      throw IllegalDNADesignError("cannot set IDTFields.well to ${this.well} when plate is null\n"
          "this occurred when reading IDTFields entry:\n${json_map}");
    }
    if (this.plate != null && this.well == null) {
      throw IllegalDNADesignError("cannot set IDTFields.plate to ${this.plate} when well is null\n"
          "this occurred when reading IDTFields entry:\n${json_map}");
    }
  }
}
