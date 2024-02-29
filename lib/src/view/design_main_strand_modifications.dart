import 'package:built_collection/built_collection.dart';
import 'package:over_react/over_react.dart';
import 'package:scadnano/src/state/extension.dart';
import 'package:scadnano/src/state/selectable.dart';

import 'transform_by_helix_group.dart';
import '../state/geometry.dart';
import '../state/group.dart';
import '../state/domain.dart';
import '../state/design.dart';
import '../state/loopout.dart';
import '../state/substrand.dart';
import 'design_main_strand_modification.dart';
import 'pure_component.dart';

import '../state/strand.dart';
import '../state/helix.dart';

part 'design_main_strand_modifications.over_react.g.dart';

UiFactory<DesignMainStrandModificationsProps> DesignMainStrandModifications = _$DesignMainStrandModifications;

mixin DesignMainStrandModificationsPropsMixin on UiProps {
  Strand strand;

  BuiltMap<int, Helix> helices;
  BuiltMap<String, HelixGroup> groups;
  Geometry geometry;

  BuiltSet<int> side_selected_helix_idxs;
  bool only_display_selected_helices;
  bool display_connector;
  int font_size;

  BuiltSet<SelectableModification> selected_modifications_in_strand;
  BuiltMap<int, num> helix_idx_to_svg_position_y_map;

  bool retain_strand_color_on_selection;
}

class DesignMainStrandModificationsProps = UiProps
    with DesignMainStrandModificationsPropsMixin, TransformByHelixGroupPropsMixin;

class DesignMainStrandModificationsComponent extends UiComponent2<DesignMainStrandModificationsProps>
    with PureComponent, TransformByHelixGroup<DesignMainStrandModificationsProps> {
  @override
  render() {
    List<ReactElement> modifications = [];

    if (props.strand.modification_5p != null) {
      var domain = props.strand.first_domain;
      if (!props.only_display_selected_helices || props.side_selected_helix_idxs.contains(domain.helix)) {
        Helix helix_5p = props.helices[domain.helix];
        bool selected =
            props.selected_modifications_in_strand.contains(props.strand.selectable_modification_5p);
        Extension ext = null;
        if (props.strand.has_5p_extension) {
          ext = props.strand.substrands.first;
        }
        modifications.add((DesignMainStrandModification()
          ..selectable_modification = props.strand.selectable_modification_5p
          ..helix = helix_5p
          ..transform = transform_of_helix(domain.helix)
          ..font_size = props.font_size
          ..display_connector = props.display_connector
          ..selected = selected
          ..helix_svg_position_y = props.helix_idx_to_svg_position_y_map[helix_5p.idx]
          ..ext = ext
          ..geometry = props.geometry
          ..retain_strand_color_on_selection = props.retain_strand_color_on_selection
          ..key = "5'")());
      }
    }

    if (props.strand.modification_3p != null) {
      var domain = props.strand.last_domain;
      if (!props.only_display_selected_helices || props.side_selected_helix_idxs.contains(domain.helix)) {
        Helix helix_3p = props.helices[domain.helix];
        Extension ext = null;
        if (props.strand.has_3p_extension) {
          ext = props.strand.substrands.last;
        }
        modifications.add((DesignMainStrandModification()
          ..selectable_modification = props.strand.selectable_modification_3p
          ..helix = helix_3p
          ..transform = transform_of_helix(domain.helix)
          ..font_size = props.font_size
          ..display_connector = props.display_connector
          ..selected =
              props.selected_modifications_in_strand.contains(props.strand.selectable_modification_3p)
          ..helix_svg_position_y = props.helix_idx_to_svg_position_y_map[helix_3p.idx]
          ..ext = ext
          ..geometry = props.geometry
          ..retain_strand_color_on_selection = props.retain_strand_color_on_selection
          ..key = "3'")());
      }
    }

    var sel_mod = props.strand.selectable_modifications_int_by_dna_idx;

    // for (int dna_idx_mod in props.strand.modifications_int.keys) {
    for (int dna_idx_mod in props.strand.selectable_modifications_int_by_dna_idx.keys) {
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
          // int ss_dna_idx = dna_idx_mod - dna_index_5p_end_of_ss_with_mod;
          // int offset = ss_with_mod.substrand_dna_idx_to_substrand_offset(ss_dna_idx, ss_with_mod.forward);
          Helix helix = props.helices[ss_with_mod.helix];
          var selectable_mod_int = props.strand.selectable_modifications_int_by_dna_idx[dna_idx_mod];
          modifications.add((DesignMainStrandModification()
            ..selectable_modification = selectable_mod_int
            ..helix = helix
            ..transform = transform_of_helix(ss_with_mod.helix)
            ..font_size = props.font_size
            ..display_connector = props.display_connector
            ..selected = props.selected_modifications_in_strand.contains(selectable_mod_int)
            ..dna_idx_mod = dna_idx_mod
            ..helix_svg_position_y = props.helix_idx_to_svg_position_y_map[helix.idx]
            ..geometry = props.geometry
            ..retain_strand_color_on_selection = props.retain_strand_color_on_selection
            ..key = "internal-${dna_idx_mod}")());
        }
      } else if (ss_with_mod is Loopout) {
        throw IllegalDesignError('currently unsupported to draw internal modification on Loopout');
      } else if (ss_with_mod is Extension) {
        throw IllegalDesignError('currently unsupported to draw internal modification on Extension');
      }
    }

    return modifications.isEmpty ? null : (Dom.g()..className = 'modifications')(modifications);
  }
}

bool mod_5p_is_in_extension(Strand strand) {}
