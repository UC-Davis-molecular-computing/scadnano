import 'dart:html';

import 'package:over_react/over_react.dart';
import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/state/group.dart';
import 'package:scadnano/src/state/helix.dart';

import '../state/design.dart';
import '../state/strand.dart';
import '../state/domain.dart';
import 'pure_component.dart';
import 'design_main_mismatch.dart';
import '../util.dart' as util;

part 'design_main_dna_mismatches.over_react.g.dart';

UiFactory<DesignMainDNAMismatchesProps> DesignMainDNAMismatches = _$DesignMainDNAMismatches;

mixin DesignMainDNAMismatchesProps on UiProps {
  Design design;
  bool only_display_selected_helices;
  BuiltSet<int> side_selected_helix_idxs;
  BuiltMap<int, num> helix_idx_to_svg_position_y_map;
}

class DesignMainDNAMismatchesComponent extends UiComponent2<DesignMainDNAMismatchesProps> with PureComponent {
  @override
  render() {
    List<ReactElement> mismatch_components = this._create_mismatch_components();
    return (Dom.g()..className = 'mismatches-main-view')(mismatch_components);
  }

  List<ReactElement> _create_mismatch_components() {
    List<ReactElement> mismatch_components = [];
    Set<String> keys = {};
    for (Strand strand in props.design.strands) {
      for (Domain domain in strand.domains) {
        BuiltList<Mismatch> mismatches = props.design.dna_mismatches_on_domain(domain);

        List<ReactElement> domain_components = [];
        for (Mismatch mismatch in mismatches) {
          var helix = props.design.helices[domain.helix];
          if (!props.only_display_selected_helices || props.side_selected_helix_idxs.contains(helix.idx)) {
            var base_svg_pos = helix.svg_base_pos(mismatch.offset, domain.forward, props.helix_idx_to_svg_position_y_map[helix.idx]);
            // For now, if there is a mismatch in an insertion we simply display it for the whole insertion,
            // not for a specific base. We maintain React keys to agree on any mismatches in the same
            // insertion, and we only render one of them.
            String key = '${base_svg_pos};${domain.forward}';
            if (!keys.contains(key)) {
              // otherwise, already rendered mismatch for this insertion
              keys.add(key);
              var mismatch_component = (DesignMainMismatch()
                ..base_svg_pos = base_svg_pos
                ..geometry = props.design.geometry
                ..forward = domain.forward
                ..key = key)();
              domain_components.add(mismatch_component);
            }
          }
        }

        Helix helix = props.design.helices[domain.helix];
        HelixGroup group = props.design.groups[helix.group];
        String transform_str = group.transform_str(props.design.geometry);

        if (domain_components.isNotEmpty) {
          mismatch_components.add((Dom.g()
            ..transform = transform_str
            ..className = 'mismatch-components-in-domain'
            ..key = util.id_domain(domain))(domain_components));
        }
      }
    }

    return mismatch_components;
  }
}
