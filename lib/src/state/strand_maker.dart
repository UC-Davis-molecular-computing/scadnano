import 'package:scadnano/src/actions/actions.dart';
import 'package:scadnano/src/state/design.dart';
import 'package:scadnano/src/state/domain.dart';
import 'package:scadnano/src/state/loopout.dart';
import 'package:scadnano/src/state/extension.dart';
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
  bool circular = false;
  String name = null;
  String label = null;
  Modification5Prime modification_5p = null;
  Modification3Prime modification_3p = null;
  int current_helix, current_offset, loopout_length;
  Map<int, ModificationInternal> modifications_int = {};
  bool is_scaffold = false;
  bool contains_extension = false;
  String loopout_dna_sequence = null;
  String loopout_name = null;
  Object loopout_label = null;
  Color loopout_color = null;

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
    this.design = this.design.add_strand(strand); //error-checking automatically done by this method
    return this.design;
  }

  // relative coordinates
  StrandMaker move(int delta) => to(current_offset + delta);

  bool most_recently_added_substrand_is_loopout() => this.loopout_length != null;

  // absolute coordinates
  StrandMaker to(int offset) {
    if (most_recently_added_substrand_is_loopout()) {
      Loopout loopout = Loopout(
        loopout_num_bases: loopout_length,
        prev_domain_idx: substrands.length - 1,
        is_scaffold: is_scaffold,
        dna_sequence: loopout_dna_sequence,
        name: loopout_name,
        label: loopout_label,
        color: loopout_color,
      );
      this.substrands.add(loopout);
      this.loopout_length = null;
      this.loopout_dna_sequence = null;
      this.loopout_name = null;
      this.loopout_label = null;
      this.loopout_color = null;
    }

    if (this._most_recently_added_substrand_is_extension_3p()) {
      throw IllegalDesignError('cannot make a new domain once 3\' extension has been added');
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
      // label: this.domain_label,
      // name: this.domain_name,
    );
    //Fix for domain_label and domain_name repeating bug:
    //this.domain_label = this.domain_name = null;

    if (substrands.isNotEmpty && substrands.last is Extension) {
      Extension ext = substrands.last;
      ext = ext.rebuild((b) => b..adjacent_domain.replace(new_domain));
      int last_idx = substrands.length - 1;
      substrands[last_idx] = ext;
    }
    this.substrands.add(new_domain);
    return this;
  }

  StrandMaker cross(int helix, [int offset = null]) {
    if (this._most_recently_added_substrand_is_extension()) {
      throw IllegalDesignError('Cannot cross after an extension.');
    }
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

  StrandMaker extension_3p(int num_bases,
      {double display_length = constants.default_display_length,
      double display_angle = constants.default_display_angle}) {
    _verify_extension_3p_is_valid();
    Domain adjacent_domain = this.substrands.last;
    Extension ext = Extension(
      num_bases: num_bases,
      display_length: display_length,
      display_angle: display_angle,
      is_5p: false,
      adjacent_domain: adjacent_domain,
    );
    this.substrands.add(ext);
    this.contains_extension = true;
    return this;
  }

  void _verify_extension_3p_is_valid() {
    if (substrands.length == 0) {
      throw IllegalDesignError('Cannot add a 3\' extension when there are no domains. '
          'Did you mean to create a 5\' extension?');
    }
    if (this.most_recently_added_substrand_is_loopout()) {
      throw IllegalDesignError('Cannot add a 3\' extension immediately after a loopout.');
    }
    if (this._most_recently_added_substrand_is_extension_3p()) {
      throw IllegalDesignError('Cannot add a 3\' extension after another 3\' extension.');
    }
    this._verify_strand_is_not_circular();
  }

  void _verify_strand_is_not_circular() {
    if (this.circular) {
      throw new IllegalDesignError('Cannot add an extension to a circular strand.');
    }
  }

  bool _most_recently_added_substrand_is_extension() => substrands.last is Extension;

  bool _most_recently_added_substrand_is_extension_3p() =>
      substrands.length > 1 && this._most_recently_added_substrand_is_extension();

  StrandMaker extension_5p(int num_bases,
      {double display_length = constants.default_display_length,
      double display_angle = constants.default_display_angle}) {
    this._verify_extension_5p_is_valid();
    Extension ext = Extension(
      num_bases: num_bases,
      display_length: display_length,
      display_angle: display_angle,
      is_5p: true,
    );
    this.substrands.add(ext);
    this.contains_extension = true;
    return this;
  }

  void _verify_extension_5p_is_valid() {
    if (substrands.length > 0) {
      throw IllegalDesignError('Cannot add a 5\' extension when there are already domains. '
          'Did you mean to create a 3\' extension?');
    }
    if (this.circular) {
      throw IllegalDesignError('cannot have extensions on a circular strand');
    }
  }

  StrandMaker as_circular() {
    if (this.contains_extension) {
      throw IllegalDesignError('cannot have extensions on a circular strand');
    }
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
    this.idt = IDTFields(scale: scale, purification: purification, plate: plate, well: well);
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
    if (most_recently_added_substrand_is_loopout()) {
      this.loopout_dna_sequence = sequence;
      return this;
    }
    int idx_last = this.substrands.length - 1;
    Substrand substrand = this.substrands[idx_last];
    Substrand new_substrand;
    if (substrand is Domain) {
      new_substrand = substrand.rebuild((b) => b..dna_sequence = sequence);
    } else if (substrand is Extension) {
      new_substrand = substrand.rebuild((b) => b..dna_sequence = sequence);
    } else {
      throw AssertionError('substrand should be Domain or Extension, but is ${substrand}');
    }
    substrands[idx_last] = new_substrand;
    return this;
  }

  StrandMaker with_label(String label) {
    this.label = label;
    return this;
  }

  StrandMaker with_domain_label(String label) {
    if (most_recently_added_substrand_is_loopout()) {
      this.loopout_label = label;
      return this;
    }
    int idx_last = this.substrands.length - 1;
    Substrand substrand = this.substrands[idx_last];
    Substrand new_substrand;
    if (substrand is Domain) {
      new_substrand = substrand.rebuild((b) => b..label = label);
    } else if (substrand is Loopout) {
      new_substrand = substrand.rebuild((b) => b..label = label);
    } else if (substrand is Extension) {
      new_substrand = substrand.rebuild((b) => b..label = label);
    } else {
      throw AssertionError('substrand should be Domain, Loopout, or Extension, but is ${substrand}');
    }
    substrands[idx_last] = new_substrand;
    return this;
  }

  StrandMaker with_domain_name(String name) {
    if (most_recently_added_substrand_is_loopout()) {
      this.loopout_name = name;
      return this;
    }
    int idx_last = this.substrands.length - 1;
    Substrand substrand = this.substrands[idx_last];
    Substrand new_substrand;
    if (substrand is Domain) {
      new_substrand = substrand.rebuild((b) => b..name = name);
    } else if (substrand is Loopout) {
      new_substrand = substrand.rebuild((b) => b..name = name);
    } else if (substrand is Extension) {
      new_substrand = substrand.rebuild((b) => b..name = name);
    } else {
      throw AssertionError('substrand should be Domain, Loopout, or Extension, but is ${substrand}');
    }
    substrands[idx_last] = new_substrand;
    return this;
  }

  StrandMaker with_domain_color(Color color) {
    if (most_recently_added_substrand_is_loopout()) {
      this.loopout_color = color;
      return this;
    }
    int idx_last = this.substrands.length - 1;
    Substrand substrand = this.substrands[idx_last];
    Substrand new_substrand;
    if (substrand is Domain) {
      new_substrand = substrand.rebuild((b) => b..color = color);
    } else if (substrand is Loopout) {
      new_substrand = substrand.rebuild((b) => b..color = color);
    } else if (substrand is Extension) {
      new_substrand = substrand.rebuild((b) => b..color = color);
    } else {
      throw AssertionError('substrand should be Domain, Loopout, or Extension, but is ${substrand}');
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

  // more convenient version of add_deletion where you don't have to specify helix;
  // it goes to most recently added domain
  StrandMaker with_deletion(int deletion) {
    return this.with_deletions([deletion]);
  }

  StrandMaker with_deletions(Iterable<int> deletions) {
    if (this.substrands.isEmpty) {
      throw ArgumentError('no Strand created yet; make at least one domain first');
    }

    var last_ss = substrands.last;

    if (most_recently_added_substrand_is_loopout()) {
      throw ArgumentError('can only create a deletion on a bound Domain, '
          'not a ${last_ss.runtimeType}; be sure only to call with_deletions immediately '
          'after a call to move, to, or update_to');
    }
    Domain last_domain = last_ss;

    for (int deletion in deletions) {
      if (!(last_domain.start <= deletion && deletion < last_domain.end)) {
        throw IllegalDesignError('all deletions must be between start=${last_domain.start} '
            'and end=${last_domain.end}, but deletion=${deletion} is outside that range');
      }
    }

    last_domain = last_domain.rebuild((b) => b..deletions.replace(deletions));
    substrands.last = last_domain;

    return this;
  }

  StrandMaker with_insertion(int offset, int count) {
    var insertion = Insertion(offset, count);
    return this.with_insertions([insertion]);
  }

  StrandMaker with_insertions(Iterable<Insertion> insertions) {
    if (this.substrands.isEmpty) {
      throw ArgumentError('no Strand created yet; make at least one domain first');
    }

    var last_ss = substrands.last;

    if (most_recently_added_substrand_is_loopout()) {
      throw ArgumentError('can only create an insertion on a bound Domain, '
          'not a ${last_ss.runtimeType}; be sure only to call with_insertions immediately '
          'after a call to move, to, or update_to');
    }
    Domain last_domain = last_ss;

    for (Insertion insertion in insertions) {
      if (!(last_domain.start <= insertion.offset && insertion.offset < last_domain.end)) {
        throw IllegalDesignError('all insertions must be between start=${last_domain.start} '
            'and end=${last_domain.end}, but insertion=${insertion} is outside that range');
      }
    }

    last_domain = last_domain.rebuild((b) => b..insertions.replace(insertions));
    substrands.last = last_domain;

    return this;
  }
}
