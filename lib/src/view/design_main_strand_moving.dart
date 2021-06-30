import 'package:built_collection/built_collection.dart';
import 'package:over_react/over_react.dart';

import 'pure_component.dart';
import 'design_main_strand_loopout.dart';
import 'transform_by_helix_group.dart';
import '../state/loopout.dart';
import '../state/group.dart';
import '../reducers/strands_reducer.dart';
import '../state/domain.dart';
import '../state/dna_end.dart';
import '../state/geometry.dart';
import '../state/helix.dart';
import '../state/strand.dart';
import '../view/design_main_strand_dna_end_moving.dart';
import '../constants.dart' as constants;

import 'design_main_strand_paths.dart';

part 'design_main_strand_moving.over_react.g.dart';

UiFactory<DesignMainStrandMovingProps> DesignMainStrandMoving = _$DesignMainStrandMoving;

mixin DesignMainStrandMovingPropsMixin on UiProps {
  Strand strand;
  BuiltMap<int, int> original_helices_view_order_inverse;
  HelixGroup current_group;
  BuiltSet<int> side_selected_helix_idxs;
  int delta_view_order;
  int delta_offset;
  bool delta_forward;
  bool allowable;

  BuiltMap<int, Helix> helices;
  BuiltMap<String, HelixGroup> groups;
  Geometry geometry;
}

class DesignMainStrandMovingProps = UiProps
    with DesignMainStrandMovingPropsMixin, TransformByHelixGroupPropsMixin;

class DesignMainStrandMovingComponent extends UiComponent2<DesignMainStrandMovingProps>
    with PureComponent, TransformByHelixGroup<DesignMainStrandMovingProps> {
  @override
  render() {
    if (props.strand.substrands.length == 0) {
      return null;
    }

    Strand strand_moved = move_strand(
        strand: props.strand,
        original_helices_view_order_inverse: props.original_helices_view_order_inverse,
        current_group: props.current_group,
        delta_view_order: props.delta_view_order,
        delta_offset: props.delta_offset,
        delta_forward: props.delta_forward);

    Domain first_domain_moved = strand_moved.first_domain;
    Domain last_domain_moved = strand_moved.last_domain;
    DNAEnd end_5p_moved = first_domain_moved.dnaend_5p;
    DNAEnd end_3p_moved = last_domain_moved.dnaend_3p;
    Helix first_helix_moved = props.helices[first_domain_moved.helix];
    Helix last_helix_moved = props.helices[last_domain_moved.helix];
    //XXX: need to switch 3' and 5' if delta_forward is true
    return (Dom.g()
      ..className = 'strand-moving'
      ..transform = transform_of_helix(first_domain_moved.helix))([
      _draw_strand_lines_single_path(strand_moved),
      if (!strand_moved.circular)
        (EndMoving()
          ..helix = first_helix_moved
          ..dna_end = end_5p_moved
          ..color = props.strand.color
          ..forward = first_domain_moved.forward //first_domain_moved.forward != props.delta_forward
          ..is_5p = true //true != props.delta_forward
          ..allowable = props.allowable
          ..current_offset = end_5p_moved.offset_inclusive // + props.delta_offset
          ..key = 'end-5p')(),
      if (!strand_moved.circular)
        (EndMoving()
          ..helix = last_helix_moved
          ..dna_end = end_3p_moved
          ..color = props.strand.color
          ..forward = last_domain_moved.forward //props.delta_forward != last_domain_moved.forward
          ..is_5p = false //false != props.delta_forward
          ..allowable = props.allowable
          ..current_offset = end_3p_moved.offset_inclusive // + props.delta_offset
          ..key = 'end-3p')(),
    ]);
  }

  ReactElement _draw_strand_lines_single_path(Strand strand_moved) {
    Domain domain_first = strand_moved.domains.first;

    var helix = props.helices[domain_first.helix];
    var start_svg = helix.svg_base_pos(domain_first.offset_5p, domain_first.forward);
    var path_cmds = ['M ${start_svg.x} ${start_svg.y}'];

    var substrands = strand_moved.substrands;
    for (int i = 0; i < substrands.length; i++) {
      var substrand = substrands[i];
      if (substrand is Domain) {
        Domain domain = substrand;
        // substrand line
        var end_svg = helix.svg_base_pos(domain.offset_3p, domain.forward);
        path_cmds.add('L ${end_svg.x} ${end_svg.y}');

        // crossover/loopout line/arc
        int idx_next = (i + 1) % substrands.length;
        if (substrands[idx_next] is Domain && (i < substrands.length - 1 || strand_moved.circular)) {
          var old_domain = domain;
          domain = substrands[idx_next];
          helix = props.helices[domain.helix];
          start_svg = helix.svg_base_pos(domain.offset_5p, domain.forward);
          var control = control_point_for_crossover_bezier_curve(old_domain, domain, props.helices,
              geometry: props.geometry);
          var crossover_path_desc = 'Q ${control.x} ${control.y} ${start_svg.x} ${start_svg.y}';
          path_cmds.add(crossover_path_desc);
        }
      } else if (substrand is Loopout && i > 0 && i < substrands.length - 1) {
        // bounds check i just in case we support loopouts on end some day
        var loopout = substrand;
        var prev_domain = substrands[i - 1] as Domain;
        var next_domain = substrands[i + 1] as Domain;
        var prev_helix = props.helices[prev_domain.helix];
        var next_helix = props.helices[next_domain.helix];
        var loopout_path_desc = loopout_path_description_within_group(
            prev_helix, next_helix, prev_domain, next_domain, loopout, false, false);
        path_cmds.add(loopout_path_desc);
        helix = props.helices[next_domain.helix]; // need to update this for next domain line to be draw
      }
    }

    var classname = constants.css_selector_domain;
    if (!props.allowable) {
      classname += ' ' + constants.css_selector_disallowed;
    }

    int key = 0;
    var path = (Dom.path()
      ..className = classname
      ..stroke = props.strand.color.toHexColor().toCssString()
      ..fill = 'none'
      ..d = path_cmds.join(' ')
      ..key = key++)();

    return path;
  }
}
