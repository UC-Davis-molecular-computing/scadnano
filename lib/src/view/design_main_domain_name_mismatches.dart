// @dart=2.9
import 'dart:html';

import 'package:over_react/over_react.dart';
import 'package:built_collection/built_collection.dart';
import 'package:tuple/tuple.dart';

import '../state/domain_name_mismatch.dart';
import '../state/design.dart';
import '../state/domain.dart';
import 'pure_component.dart';
import 'design_main_warning_star.dart';
import '../util.dart' as util;

part 'design_main_domain_name_mismatches.over_react.g.dart';

UiFactory<DesignMainDomainNameMismatchesProps> DesignMainDomainNameMismatches =
    _$DesignMainDomainNameMismatches;

mixin DesignMainDomainNameMismatchesProps on UiProps {
  Design design;
  bool only_display_selected_helices;
  BuiltSet<int> side_selected_helix_idxs;
  BuiltMap<int, Point<num>> helix_idx_to_svg_position_map;
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

    for (var helix in props.design.helices.values) {
      if (props.only_display_selected_helices && !props.side_selected_helix_idxs.contains(helix.idx)) {
        continue;
      }

      BuiltList<DomainNameMismatch> domain_name_mismatches = props.design.domain_name_mismatches[helix.idx];

      for (var domain_name_mismatch in domain_name_mismatches) {
        Domain forward_domain = domain_name_mismatch.forward_domain;
        Domain reverse_domain = domain_name_mismatch.reverse_domain;
        Tuple2<int, int> overlap = forward_domain.compute_overlap(reverse_domain);
        assert(overlap != null);
        // draw mismatch stars at midpoint of overlap of domains
        int mid = (overlap.item1 + overlap.item2) ~/ 2;
        for (Domain domain in [forward_domain, reverse_domain]) {
          var base_svg_pos =
              helix.svg_base_pos(mid, domain.forward, props.helix_idx_to_svg_position_map[helix.idx].y);
          String key = '${domain.helix};${domain.forward};${domain.start};${mid};${domain.end}';
          var mismatch_component = (DesignMainWarningStar()
            ..base_svg_pos = base_svg_pos
            ..geometry = props.design.geometry
            ..forward = domain.forward
            ..color = 'blue'
            ..key = key)();
          mismatch_components.add(mismatch_component);
        }
      }
    }
    return mismatch_components;
  }
}
