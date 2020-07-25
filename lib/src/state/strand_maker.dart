import 'package:scadnano/src/state/design.dart';
import 'package:scadnano/src/state/domain.dart';
import 'package:scadnano/src/state/loopout.dart';
import 'package:scadnano/src/state/modification.dart';
import 'package:scadnano/src/state/strand.dart';
import 'package:color/color.dart';

class StrandMaker{
  Design design;
  Strand strand;
  Color color;
  String dna_sequence;
  Domain last_domain;
  Object label;
  Modification5Prime modification_5p;
  Modification3Prime modification_3p;
  int current_helix, current_offset, loopout_length;
  Map<int, ModificationInternal> modifications_int;
  bool is_scaffold;
  StrandMaker(
    int current_helix,
    int current_offset,
    {int loopout_length = null,
    Domain last_domain = null,
    Strand strand = null,
    }) {
    this.current_helix = current_helix;
    this.current_offset = current_offset;
    this.loopout_length = loopout_length;
    this.strand = strand;
    this.last_domain = last_domain;
  }

  void cross(int helix, var offset){
    this.last_domain = null;
    this.current_helix = helix;
    if(offset != null){
      this.current_offset = offset;
    }
  }

  void to(int offset){
    bool forward;
    var start, end;
    if ((this.last_domain != null) && ((this.last_domain.forward && offset < this.current_offset) ||
    (!this.last_domain.forward && offset > this.current_offset))){
      throw IllegalDNADesignError("offsets must be monotonic ");
    }
    if(offset > this.current_offset){
      forward = true;
      start = this.current_offset;
      end = offset;
    }else if(offset < this.current_offset){
      forward = false;
      start = offset;
      end = this.current_offset;
    }else{
      throw IllegalDNADesignError("offset cannot be equal to current offset");
    }
    if(this.loopout_length != null){
      this.last_domain = Domain(helix: this.current_helix, forward: forward, start: start, end: end);
    }
  }

  Design commit(){
    Strand new_strand = Strand(this.strand.substrands, color: color, dna_sequence: this.dna_sequence, is_scaffold: this.is_scaffold, modification_5p: this.modification_5p, 
    modification_3p: this.modification_3p, modifications_int: this.modifications_int, label: this.label);
    new_strand.domains().add(this.last_domain);
    this.design.add_strand(new_strand);
    return this.design;
  }

  void loopout(int helix, int length, int offset){
    this.loopout_length = length;
    this.cross(helix, offset);
  }

  void as_scaffold(){
    this.is_scaffold = true;
  }
  
  void with_modification_5p(Modification5Prime mod){
    this.modification_5p = mod;
  }

  void with_modification_3p(Modification3Prime mod){
    this.modification_3p = mod;
  }

  void with_modification_internal(int idx, ModificationInternal mod, [bool warn_on_no_dna = true]){
    if(idx < 0){
      throw IllegalDNADesignError('idx of modification must be nonnegative');
    } else if(idx >= this.strand.dna_length()){
      throw IllegalDNADesignError('idx of modification must be at most length of DNA');
    } else{
      this.modifications_int[idx] = mod;
    }
  }

  void with_color(Color color){
    this.color = color;
  }

  void with_sequence(String sequence){
    this.dna_sequence = sequence;
  }
  void with_label(Object label){
    this.label = label;
  }

}
