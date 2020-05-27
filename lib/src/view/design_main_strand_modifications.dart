import 'package:built_collection/built_collection.dart';
import 'package:over_react/over_react.dart';
import 'package:scadnano/src/state/domain.dart';
import 'package:scadnano/src/state/dna_design.dart';
import 'package:scadnano/src/state/loopout.dart';
import 'package:scadnano/src/state/substrand.dart';
import 'package:scadnano/src/view/design_main_strand_modification_domain.dart';

import '../state/strand.dart';
import '../state/helix.dart';

part 'design_main_strand_modifications.over_react.g.dart';

UiFactory<DesignMainStrandModificationsProps> DesignMainStrandModifications = _$DesignMainStrandModifications;

mixin DesignMainStrandModificationsProps on UiProps {
  Strand strand;
  BuiltMap<int, Helix> helices;
  BuiltSet<int> side_selected_helix_idxs;
  bool only_display_selected_helices;
  bool display_connector;
  int font_size;
}

class DesignMainStrandModificationsComponent extends UiComponent2<DesignMainStrandModificationsProps> {
  @override
  render() {
    List<ReactElement> modifications = [];

    if (props.strand.modification_5p != null) {
      var ss = props.strand.first_domain();
      if (!props.only_display_selected_helices || props.side_selected_helix_idxs.contains(ss.helix)) {
        Helix helix_5p = props.helices[ss.helix];
        modifications.add((DesignMainStrandModificationDomain()
          ..address = Address(helix_idx: helix_5p.idx, offset: ss.offset_5p, forward: ss.forward)
          ..helix = helix_5p
          ..modification = props.strand.modification_5p
          ..font_size = props.font_size
          ..display_connector = props.display_connector
          ..key = "5'")());
      }
    }

    if (props.strand.modification_3p != null) {
      var ss = props.strand.last_bound_substrand();
      if (!props.only_display_selected_helices || props.side_selected_helix_idxs.contains(ss.helix)) {
        Helix helix_3p = props.helices[ss.helix];
        modifications.add((DesignMainStrandModificationDomain()
          ..address = Address(helix_idx: helix_3p.idx, offset: ss.offset_3p, forward: ss.forward)
          ..helix = helix_3p
          ..modification = props.strand.modification_3p
          ..font_size = props.font_size
          ..display_connector = props.display_connector
          ..key = "3'")());
      }
    }

    for (var dna_idx_mod in props.strand.modifications_int.keys) {
      // find substrand with modification, and the DNA index of its 5' end
      Substrand ss_with_mod;
      int dna_index_5p_end_of_ss_with_mod = 0;
      for (var ss in props.strand.substrands) {
        int ss_dna_length = ss.dna_length();
        if (dna_index_5p_end_of_ss_with_mod + ss_dna_length > dna_idx_mod) {
          ss_with_mod = ss;
          break;
        }
        dna_index_5p_end_of_ss_with_mod += ss_dna_length;
      }

      if (ss_with_mod is Domain) {
        if (!props.only_display_selected_helices ||
            props.side_selected_helix_idxs.contains(ss_with_mod.helix)) {
          int ss_dna_idx = dna_idx_mod - dna_index_5p_end_of_ss_with_mod;
          int offset = ss_with_mod.substrand_dna_idx_to_substrand_offset(ss_dna_idx, ss_with_mod.forward);
          Helix helix = props.helices[ss_with_mod.helix];
          modifications.add((DesignMainStrandModificationDomain()
            ..address = Address(helix_idx: helix.idx, offset: offset, forward: ss_with_mod.forward)
            ..helix = helix
            ..modification = props.strand.modifications_int[dna_idx_mod]
            ..font_size = props.font_size
            ..display_connector = props.display_connector
            ..key = "internal-${dna_idx_mod}")());
        }
      } else if (ss_with_mod is Loopout) {
        throw IllegalDNADesignError('currently unsupported to draw modification on Loopout');
      }
    }

    return modifications.isEmpty ? null : (Dom.g()..className = 'modifications')(modifications);
  }
}
