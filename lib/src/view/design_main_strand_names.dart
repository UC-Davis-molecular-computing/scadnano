import 'package:built_collection/built_collection.dart';
import 'package:over_react/over_react.dart';

import 'transform_by_helix_group.dart';
import '../state/geometry.dart';
import '../state/group.dart';
import '../state/domain.dart';
import '../state/loopout.dart';
import 'design_main_strand_paths.dart';
import 'design_main_strand_domain_name.dart';
import 'design_main_strand_loopout_name.dart';
import 'pure_component.dart';
import '../state/strand.dart';
import '../state/helix.dart';
import '../constants.dart' as constants;

part 'design_main_strand_names.over_react.g.dart';

UiFactory<DesignMainStrandNamesProps> DesignMainStrandNames = _$DesignMainStrandNames;

mixin DesignMainStrandNamesPropsMixin on UiProps {
  Strand strand;

  BuiltMap<int, Helix> helices;
  BuiltMap<String, HelixGroup> groups;
  Geometry geometry;

  BuiltSet<int> side_selected_helix_idxs;
  bool only_display_selected_helices;
  int font_size;
  bool show_dna;
}

class DesignMainStrandNamesProps = UiProps
    with DesignMainStrandNamesPropsMixin, TransformByHelixGroupPropsMixin;

class DesignMainStrandNamesComponent extends UiComponent2<DesignMainStrandNamesProps>
    with PureComponent, TransformByHelixGroup<DesignMainStrandNamesProps> {
  @override
  render() {
    List<ReactElement> names = [];

    int i = 0;
    for (var substrand in props.strand.substrands) {
      if (substrand is Domain) {
        Domain domain = substrand;
        bool draw_domain = should_draw_domain(
            domain.helix, props.side_selected_helix_idxs, props.only_display_selected_helices);
        if (draw_domain && domain.name != null) {
          Helix helix = props.helices[substrand.helix];
          names.add((DesignMainStrandDomainName()
            ..domain = substrand
            ..helix = helix
            ..geometry = props.geometry
            ..font_size = props.font_size
            ..transform = transform_of_helix(domain.helix)
            ..show_dna = props.show_dna
            ..className = constants.css_selector_domain_name
            ..key = "domain-name-$i")());
        }
      } else if (substrand is Loopout) {
        Loopout loopout = substrand;
        Domain prev_domain = (props.strand.substrands[i - 1] as Domain);
        Domain next_domain = (props.strand.substrands[i + 1] as Domain);
        int prev_helix_idx = prev_domain.helix;
        int next_helix_idx = next_domain.helix;
        bool draw_loopout = should_draw_loopout(prev_helix_idx, next_helix_idx,
            props.side_selected_helix_idxs, props.only_display_selected_helices);
        if (draw_loopout && loopout.name != null) {
          names.add((DesignMainStrandLoopoutName()
            ..loopout = loopout
            ..prev_domain = prev_domain
            ..next_domain = next_domain
            ..geometry = props.geometry
            ..font_size = props.font_size
            ..show_dna = props.show_dna
            ..className = constants.css_selector_loopout_name
            ..key = "loopout-name-$i")());
        }
      } else {
        throw AssertionError('substrand must be Domain or Loopout');
      }
      i++;
    }

    return names.isEmpty ? null : (Dom.g()
      ..className = 'domain-names')(names);
  }
}
