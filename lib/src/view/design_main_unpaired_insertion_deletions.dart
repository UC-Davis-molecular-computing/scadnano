import 'package:web/web.dart';

import 'package:over_react/over_react.dart';
import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/state/address.dart';
import 'package:scadnano/src/state/group.dart';
import 'package:scadnano/src/state/helix.dart';
import 'dart:math';
import '../state/design.dart';
import '../state/strand.dart';
import '../state/domain.dart';
import 'pure_component.dart';
import 'design_main_warning_star.dart';
import '../util.dart' as util;

part 'design_main_unpaired_insertion_deletions.over_react.g.dart';

UiFactory<DesignMainUnpairedInsertionDeletionsProps> DesignMainUnpairedInsertionDeletions =
    _$DesignMainUnpairedInsertionDeletions;

mixin DesignMainUnpairedInsertionDeletionsProps on UiProps {
  late Design design;
  late bool only_display_selected_helices;
  late BuiltSet<int> side_selected_helix_idxs;
  late BuiltMap<int, num> helix_idx_to_svg_position_y_map;
}

class DesignMainUnpairedInsertionDeletionsComponent
    extends UiComponent2<DesignMainUnpairedInsertionDeletionsProps> with PureComponent {
  @override
  render() {
    List<ReactElement> unpaired_components = [];
    Set<String> keys = {};
    for (Strand strand in props.design.strands) {
      for (Domain domain in strand.domains) {
        BuiltList<Address> unpaireds = props.design.unpaired_insertion_deletion_on_domain(domain);

        List<ReactElement> domain_components = [];
        for (Address unpaired in unpaireds) {
          var helix = props.design.helices[domain.helix]!;
          if (!props.only_display_selected_helices || props.side_selected_helix_idxs.contains(helix.idx)) {
            var group = props.design.groups[helix.group]!;
            var geometry = group.geometry ?? props.design.geometry;
            var svg_position_y = props.helix_idx_to_svg_position_y_map[helix.idx]!;
            var base_svg_pos = helix.svg_base_pos(unpaired.offset, domain.forward, svg_position_y, geometry);

            bool is_insertion = domain.insertion_offset_to_length[unpaired.offset] != null;

            String key = '${base_svg_pos};${domain.forward}';

            if (!keys.contains(key)) {
              // otherwise, already rendered mismatch for this insertion
              keys.add(key);
              var mismatch_component = (DesignMainWarningStar()
                ..base_svg_pos = base_svg_pos +
                    Point(0, is_insertion ? geometry.base_height_svg * 2 * (unpaired.forward ? 1 : -1) : 0)
                ..geometry = geometry
                ..forward = domain.forward
                ..color = 'green'
                ..key = key)();
              domain_components.add(mismatch_component);
            }
          }
        }

        Helix helix = props.design.helices[domain.helix]!;
        HelixGroup group = props.design.groups[helix.group]!;
        String transform_str = group.transform_str(props.design.geometry);

        if (domain_components.isNotEmpty) {
          unpaired_components.add((Dom.g()
            ..transform = transform_str
            ..className = 'mismatch-components-in-domain'
            ..key = util.id_domain(domain))(domain_components));
        }
      }
    }

    return (Dom.g()..className = 'mismatches-main-view')(unpaired_components);
  }
}
