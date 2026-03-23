import 'dart:html';

import 'package:over_react/over_react.dart';
import 'package:built_collection/built_collection.dart';

import '../state/domain_name_mismatch.dart';
import '../state/design.dart';
import '../state/domain.dart';
import '../state/helix.dart';
import '../state/group.dart';
import 'pure_component.dart';
import 'design_main_warning_star.dart';
import '../util.dart' as util;

part 'design_main_domain_name_mismatches.over_react.g.dart';

UiFactory<DesignMainDomainNameMismatchesProps> DesignMainDomainNameMismatches =
    _$DesignMainDomainNameMismatches;

mixin DesignMainDomainNameMismatchesProps on UiProps {
  late Design design;
  late bool only_display_selected_helices;
  late BuiltSet<int> side_selected_helix_idxs;
  late BuiltMap<int, num> helix_idx_to_svg_position_y_map;
}

class DesignMainDomainNameMismatchesComponent extends UiComponent2<DesignMainDomainNameMismatchesProps>
    with PureComponent {
  @override
  render() {
    List<ReactElement> mismatch_components = this._create_mismatch_components();
    return (Dom.g()..className = 'domain-name-mismatches-main-view')(mismatch_components);
  }

  List<ReactElement> _create_mismatch_components() {
    List<ReactElement> mismatch_components = [];

    for (Helix helix in props.design.helices.values) {
      if (props.only_display_selected_helices && !props.side_selected_helix_idxs.contains(helix.idx)) {
        continue;
      }

      BuiltList<DomainNameMismatch> domain_name_mismatches = props.design.domain_name_mismatches[helix.idx]!;

      List<ReactElement> untransformed_mismatch_components = [];
      for (var domain_name_mismatch in domain_name_mismatches) {
        Domain forward_domain = domain_name_mismatch.forward_domain;
        Domain reverse_domain = domain_name_mismatch.reverse_domain;
        (int, int)? overlap = forward_domain.compute_overlap(reverse_domain);
        if (overlap == null) throw AssertionError('overlap should not be null');

        // draw mismatch stars at midpoint of overlap of domains
        int mid = (overlap.$1 + overlap.$2) ~/ 2;
        for (Domain domain in [forward_domain, reverse_domain]) {
          var helix = props.design.helices[domain.helix]!;
          var group = props.design.groups[helix.group]!;
          var geometry = group.geometry ?? props.design.geometry;
          var svg_position_y = props.helix_idx_to_svg_position_y_map[helix.idx]!;
          var base_svg_pos = helix.svg_base_pos(mid, domain.forward, svg_position_y, geometry);
          String key = '${domain.helix};${domain.forward};${domain.start};${mid};${domain.end}';
          var mismatch_component =
              (DesignMainWarningStar()
                ..base_svg_pos = base_svg_pos
                ..geometry = geometry
                ..forward = domain.forward
                ..color = 'blue'
                ..domain_name_mismatch = domain_name_mismatch
                ..key = key)();
          untransformed_mismatch_components.add(mismatch_component);
        }
      }

      HelixGroup group = props.design.groups[helix.group]!;
      String transform_str = group.transform_str(props.design.geometry);

      if (untransformed_mismatch_components.isNotEmpty) {
        mismatch_components.add(
          (Dom.g()
            ..transform = transform_str
            ..className = 'mismatch-domain-names-group'
            ..key = util.id_helix(helix))(untransformed_mismatch_components),
        );
      }
    }
    return mismatch_components;
  }
}
