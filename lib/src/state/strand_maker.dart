import 'package:scadnano/src/state/design.dart';
import 'package:scadnano/src/state/domain.dart';
import 'package:scadnano/src/state/loopout.dart';
import 'package:scadnano/src/state/modification.dart';
import 'package:scadnano/src/state/strand.dart';
import 'package:color/color.dart';
import 'package:scadnano/src/state/substrand.dart';

class StrandMaker {
  List<Substrand> substrands = [];
  Color color = Color.rgb(247, 67, 8); //(#f74308) 
  String dna_sequence = null;
  String domain_dna_sequence = null;
  Object label = null;
  Object domain_label = null;
  Modification5Prime modification_5p = null;
  Modification3Prime modification_3p = null;
  int current_helix, current_offset, loopout_length;
  Map<int, ModificationInternal> modifications_int = {};
  bool is_scaffold = false;

  StrandMaker(
    int current_helix,
    int current_offset,
  ) {
    this.current_helix = current_helix;
    this.current_offset = current_offset;
  }

//always the final call that creates the new strand
  Strand commit() {
    Strand strand = new Strand(substrands,
        color: this.color,
        is_scaffold: this.is_scaffold,
        dna_sequence: this.dna_sequence,
        label: this.label,
        modification_3p: this.modification_3p,
        modification_5p: this.modification_5p,
        modifications_int: this.modifications_int);
    return strand;
  }

  void to(int offset) {
    if (this.loopout_length != null) {
      Loopout loopout = Loopout(this.loopout_length, this.current_offset, offset, this.is_scaffold);
      this.substrands.add(loopout);
      this.loopout_length = null;
    }
    bool forward;
    var start, end;
    if (offset > this.current_offset) {
      forward = true;
      start = this.current_offset;
      end = offset;
    } else if (offset < this.current_offset) {
      forward = false;
      start = offset;
      end = this.current_offset;
    } else {
      throw IllegalDNADesignError("offset cannot be equal to current offset");
    }
    this.current_offset = offset;
    Domain new_domain = new Domain(
        helix: this.current_helix,
        forward: forward,
        start: start,
        end: end,
        is_scaffold: this.is_scaffold,
        dna_sequence: this.domain_dna_sequence,
        label: this.domain_label);
    this.substrands.add(new_domain);
  }

  void cross(int helix, [int offset = null]) {
    this.current_helix = helix;
    if (offset != null) {
      this.current_offset = offset;
    }
  }

  void loopout(int helix, int length, [int offset = null]) {
    this.loopout_length = length;
    this.cross(helix, offset);
  }

  void as_scaffold() {
    this.is_scaffold = true;
  }

  void with_modification_5p(Modification5Prime mod) {
    this.modification_5p = mod;
  }

  void with_modification_3p(Modification3Prime mod) {
    this.modification_3p = mod;
  }

  void with_modification_internal(int idx, ModificationInternal mod) {
    if (idx < 0) {
      throw IllegalDNADesignError('idx of modification must be nonnegative');
    } else {
      this.modifications_int[idx] = mod;
    }
  }

  void with_color(Color color) {
    this.color = color;
  }

  void with_sequence(String sequence) {
    this.dna_sequence = sequence;
  }

  void with_domain_sequence(String sequence) {
    this.domain_dna_sequence = sequence;
  }

  void with_label(Object label) {
    this.label = label;
  }

  void with_domain_label(Object label) {
    this.domain_label = label;
  }
}
