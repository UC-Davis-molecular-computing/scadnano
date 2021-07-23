import 'package:scadnano/src/actions/actions.dart';
import 'package:scadnano/src/state/design.dart';
import 'package:scadnano/src/state/domain.dart';
import 'package:scadnano/src/state/loopout.dart';
import 'package:scadnano/src/state/modification.dart';
import 'package:scadnano/src/state/strand.dart';
import 'package:color/color.dart';
import 'package:scadnano/src/state/substrand.dart';

import '../constants.dart' as constants;
import 'helix.dart';
import 'idt_fields.dart';

class StrandMaker {
  Design design;
  List<Substrand> substrands = [];
  Color color = Color.rgb(247, 67, 8); //(#f74308)
  IDTFields idt = null; //(#f74308)
  String dna_sequence = null;
  String domain_dna_sequence = null;
  bool circular = false;
  String name = null;
  Object label = null;
  Modification5Prime modification_5p = null;
  Modification3Prime modification_3p = null;
  int current_helix, current_offset, loopout_length;
  Map<int, ModificationInternal> modifications_int = {};
  bool is_scaffold = false;

  StrandMaker(
    Design design,
    int current_helix,
    int current_offset,
  ) {
    this.design = design;
    this.current_helix = current_helix;
    this.current_offset = current_offset;
  }

//always the final call that creates the new strand
  Design commit() {
    Strand strand = new Strand(substrands,
        color: this.color,
        circular: circular,
        is_scaffold: this.is_scaffold,
        dna_sequence: this.dna_sequence,
        label: this.label,
        idt: this.idt,
        name: this.name,
        modification_3p: this.modification_3p,
        modification_5p: this.modification_5p,
        modifications_int: this.modifications_int);
    this.design = this
        .design
        .add_strand(strand); //error-checking automatically done by this method
    return this.design;
  }

  // relative coordinates
  StrandMaker move(int delta) => to(current_offset + delta);

  // absolute coordinates
  StrandMaker to(int offset) {
    if (this.loopout_length != null) {
      Loopout loopout = Loopout(
        loopout_length: loopout_length,
        prev_domain_idx: current_offset,
        next_domain_idx: offset,
        is_scaffold: is_scaffold,
      );
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
      throw IllegalDesignError("offset cannot be equal to current offset");
    }
    this.current_offset = offset;
    Domain new_domain = new Domain(
      helix: this.current_helix,
      forward: forward,
      start: start,
      end: end,
      is_scaffold: this.is_scaffold,
      dna_sequence: this.domain_dna_sequence,

      /*label: this.domain_label,
        name: this.domain_name,*/
    );
    //Fix for domain_label and domain_name repeating bug:
    //this.domain_label = this.domain_name = null;

    this.substrands.add(new_domain);
    return this;
  }

  StrandMaker cross(int helix, [int offset = null]) {
    this.current_helix = helix;
    if (offset != null) {
      this.current_offset = offset;
    }
    return this;
  }

  StrandMaker loopout(int helix, int length, [int offset = null]) {
    this.loopout_length = length;
    this.cross(helix, offset);
    return this;
  }

  StrandMaker as_circular() {
    this.circular = true;
    return this;
  }

  StrandMaker as_scaffold() {
    this.is_scaffold = true;
    return this;
  }

  StrandMaker with_modification_5p(Modification5Prime mod) {
    this.modification_5p = mod;
    return this;
  }

  StrandMaker with_modification_3p(Modification3Prime mod) {
    this.modification_3p = mod;
    return this;
  }

  StrandMaker with_modification_internal(int idx, ModificationInternal mod) {
    if (idx < 0) {
      throw IllegalDesignError('idx of modification must be nonnegative');
    } else {
      this.modifications_int[idx] = mod;
    }
    return this;
  }

  StrandMaker with_idt(
      {String scale = constants.default_idt_scale,
      String purification = constants.default_idt_purification,
      String plate = null,
      String well = null}) {
    this.idt = IDTFields(
        scale: scale, purification: purification, plate: plate, well: well);
    return this;
  }

  StrandMaker with_name(String name) {
    this.name = name;
    return this;
  }

  StrandMaker with_color(Color color) {
    this.color = color;
    return this;
  }

  StrandMaker with_sequence(String sequence) {
    this.dna_sequence = sequence;
    return this;
  }

  StrandMaker with_domain_sequence(String sequence) {
    this.domain_dna_sequence = sequence;
    return this;
  }

  StrandMaker with_label(Object label) {
    this.label = label;
    return this;
  }

  StrandMaker with_domain_label(Object label) {
    int idx_last = this.substrands.length - 1;
    Substrand substrand = this.substrands[idx_last];
    Substrand new_substrand;
    if (substrand is Domain) {
      new_substrand = substrand.rebuild((b) => b..label = label);
    } else if (substrand is Loopout) {
      new_substrand = substrand.rebuild((b) => b..label = label);
    }
    substrands[idx_last] = new_substrand;
    return this;
  }

  StrandMaker with_domain_name(String name) {
    int idx_last = this.substrands.length - 1;
    Substrand substrand = this.substrands[idx_last];
    Substrand new_substrand;
    if (substrand is Domain) {
      new_substrand = substrand.rebuild((b) => b..name = name);
    } else if (substrand is Loopout) {
      new_substrand = substrand.rebuild((b) => b..name = name);
    }
    substrands[idx_last] = new_substrand;
    return this;
  }

  StrandMaker add_deletion(num helix, num offset) {
    for (int i = 0; i < this.substrands.length; i++) {
      Substrand substrand = this.substrands[i];
      if (substrand is Domain) {
        if (substrand.contains_offset(offset) && substrand.helix == helix) {
          List<int> new_deletions = substrand.deletions.toList();
          new_deletions.add(offset);
          Substrand new_substrand = substrand.rebuild((b) => b..deletions.replace(new_deletions));
          this.substrands[i] = new_substrand;
        }
      }
    }
    return this;
  }

  StrandMaker add_insertion(num helix, num offset, num length) {
    for (int i = 0; i < this.substrands.length; i++) {
      Substrand substrand = this.substrands[i];
      if (substrand is Domain) {
        if (substrand.contains_offset(offset) && substrand.helix == helix) {
          List<Insertion> new_insertions = substrand.insertions.toList();
          new_insertions.add(Insertion(offset, length));
          Substrand new_substrand = substrand.rebuild((b) => b..insertions.replace(new_insertions));
          this.substrands[i] = new_substrand;
        }
      }
    }
    return this;
  }
}
