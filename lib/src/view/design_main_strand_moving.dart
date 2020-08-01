import 'package:built_collection/built_collection.dart';
import 'package:over_react/over_react.dart';
import 'package:scadnano/src/view/pure_component.dart';

import 'transform_by_helix_group.dart';
import '../state/group.dart';
import '../reducers/strands_reducer.dart';
import '../state/domain.dart';
import '../state/dna_end.dart';
import '../state/geometry.dart';
import '../state/helix.dart';
import '../state/strand.dart';
import '../view/design_main_strand_dna_end_moving.dart';

import 'design_main_strand_paths.dart';

part 'design_main_strand_moving.over_react.g.dart';

UiFactory<DesignMainStrandMovingProps> DesignMainStrandMoving = _$DesignMainStrandMoving;

mixin DesignMainStrandMovingPropsMixin on UiProps {
  Strand strand;
  HelixGroup original_group;
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

    Strand strand_moved = moved_strand(
        strand: props.strand,
        original_group: props.original_group,
        current_group: props.current_group,
        delta_view_order: props.delta_view_order,
        delta_offset: props.delta_offset,
        delta_forward: props.delta_forward);

    Domain first_domain_moved = strand_moved.first_domain();
    Domain last_domain_moved = strand_moved.last_domain();
    DNAEnd end_5p_moved = first_domain_moved.dnaend_5p;
    DNAEnd end_3p_moved = last_domain_moved.dnaend_3p;
    Helix first_helix_moved = props.helices[first_domain_moved.helix];
    Helix last_helix_moved = props.helices[last_domain_moved.helix];
    //XXX: need to switch 3' and 5' if delta_forward is true
    return (Dom.g()
      ..className = 'strand-moving'
      ..transform = transform_of_helix(first_domain_moved.helix))(
      _draw_strand_lines_single_path(strand_moved),
      (EndMoving()
        ..helix = first_helix_moved
        ..dna_end = end_5p_moved
        ..color = props.strand.color
        ..forward = first_domain_moved.forward //first_domain_moved.forward != props.delta_forward
        ..is_5p = true //true != props.delta_forward
        ..allowable = props.allowable
        ..current_offset = end_5p_moved.offset_inclusive // + props.delta_offset
        ..key = 'end-5p')(),
      (EndMoving()
        ..helix = last_helix_moved
        ..dna_end = end_3p_moved
        ..color = props.strand.color
        ..forward = last_domain_moved.forward //props.delta_forward != last_domain_moved.forward
        ..is_5p = false //false != props.delta_forward
        ..allowable = props.allowable
        ..current_offset = end_3p_moved.offset_inclusive // + props.delta_offset
        ..key = 'end-3p')(),
    );
  }

  ReactElement _draw_strand_lines_single_path(Strand strand_moved) {
    List<Domain> domains = strand_moved.domains();
    Domain domain = domains.first;

    var helix = props.helices[domain.helix];
    var start_svg = helix.svg_base_pos(domain.offset_5p, domain.forward);
    var path_cmds = ['M ${start_svg.x} ${start_svg.y}'];

    for (int i = 0; i < domains.length; i++) {
      // substrand line
      var end_svg = helix.svg_base_pos(domain.offset_3p, domain.forward);
      path_cmds.add('L ${end_svg.x} ${end_svg.y}');

      // crossover/loopout line/arc
      if (i < domains.length - 1) {
        var old_substrand = domain;
        domain = domains[i + 1];
        helix = props.helices[domain.helix];
        start_svg = helix.svg_base_pos(domain.offset_5p, domain.forward);
        var control = control_point_for_crossover_bezier_curve(old_substrand, domain, props.helices,
            geometry: props.geometry);
        path_cmds.add('Q ${control.x} ${control.y} ${start_svg.x} ${start_svg.y}');
      }
    }

    int key = 0;
    var path = (Dom.path()
//      ..id= substrand_line_id(substrand),
      ..className = 'domain-line' + (props.allowable ? '' : ' disallowed')
      ..stroke = props.strand.color.toHexColor().toCssString()
      ..fill = 'none'
      ..d = path_cmds.join(' ')
      ..key = key++)();

    return path;
  }
}
