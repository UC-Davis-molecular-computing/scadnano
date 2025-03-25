import 'package:color/color.dart';
import 'package:over_react/over_react.dart';
import 'package:built_collection/built_collection.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:scadnano/src/reducers/domains_move_reducer.dart';
import 'package:scadnano/src/state/domain.dart';
import 'package:scadnano/src/state/domains_move.dart';
import 'package:scadnano/src/view/pure_component.dart';

import '../state/group.dart';
import '../state/geometry.dart';
import '../state/helix.dart';
import '../state/app_state.dart';
import '../util.dart' as util;
import 'design_main_domain_moving.dart';

part 'design_main_domains_moving.over_react.g.dart';

DesignMainDomainsMovingProps set_design_main_domains_moving_props(
    DesignMainDomainsMovingProps elt, AppState state) {
  if (state.ui_state.domains_move == null) {
    return elt
      ..domains_move = null
      ..color_of_domain = BuiltMap<Domain, Color>()
      ..groups = BuiltMap<String, HelixGroup>()
      ..original_group = HelixGroup(helices_view_order: [])
      ..current_group = HelixGroup(helices_view_order: [])
      ..helices = BuiltMap<int, Helix>()
      ..side_selected_helix_idxs = BuiltSet<int>()
      ..helix_idx_to_svg_position_y_map = BuiltMap<int, num>()
      ..geometry = Geometry();
  }

  HelixGroup original_group =
      util.original_group_from_domains_move(state.design, state.ui_state.domains_move!);
  HelixGroup current_group = util.current_group_from_domains_move(state.design, state.ui_state.domains_move!);

  // Need to check this here, because we need to allow the middleware to let through the domains_move
  // object so that view/design.dart can issue a warning to the user on a mousemove event when the
  // left-click is depressed. But if we allow the domains_move to propagate to the view it throws
  // an exception since it assumes they are in the same group.
  bool selected_domains_on_multiple_groups = false;
  if (state.ui_state.domains_move != null) {
    var group_names = state.design.group_names_of_domains(state.ui_state.domains_move!.domains_moving);
    selected_domains_on_multiple_groups = group_names.length > 1;
  }

  var geometry = current_group.geometry ?? state.design.geometry;

  return elt
    ..domains_move = selected_domains_on_multiple_groups ? null : state.ui_state.domains_move
    ..color_of_domain = state.design.color_of_domain
    ..groups = state.design.groups
    ..original_group = original_group
    ..current_group = current_group
    ..helices = state.design.helices
    ..side_selected_helix_idxs = state.ui_state.side_selected_helix_idxs
    ..helix_idx_to_svg_position_y_map = state.helix_idx_to_svg_position_map.map((i, p) => MapEntry(i, p.y))
    ..geometry = geometry;
}

UiFactory<DesignMainDomainsMovingProps> ConnectedDesignMainDomainsMoving =
    connect<AppState, DesignMainDomainsMovingProps>(
        mapStateToProps: (state) =>
            set_design_main_domains_moving_props(DesignMainDomainsMoving(), state))(DesignMainDomainsMoving);

UiFactory<DesignMainDomainsMovingProps> DesignMainDomainsMoving = _$DesignMainDomainsMoving;

mixin DesignMainDomainsMovingProps on UiProps {
  DomainsMove? domains_move;
  late BuiltMap<Domain, Color> color_of_domain;
  late HelixGroup original_group;
  late HelixGroup current_group;
  late BuiltMap<int, Helix> helices;
  late BuiltMap<String, HelixGroup> groups;
  late BuiltSet<int> side_selected_helix_idxs;
  late Geometry geometry;
  late BuiltMap<int, num> helix_idx_to_svg_position_y_map;
}

class DesignMainDomainsMovingComponent extends UiComponent2<DesignMainDomainsMovingProps> with PureComponent {
  @override
  render() {
    var domains_move = props.domains_move;
    if (domains_move == null) {
      return null;
    }

    List<ReactElement> domains_moving = [];
    int key = 0;
    for (var domain in domains_move.domains_moving) {
      Domain domain_moved = move_domain(
        domain: domain,
        original_group: props.original_group,
        current_group: props.current_group,
        delta_view_order: domains_move.delta_view_order,
        delta_offset: domains_move.delta_offset,
        delta_forward: domains_move.delta_forward,
        set_first_last_false: true, // don't want to display 5'/3' ends while moving
      );
      int moved_helix_idx = domain_moved.helix;
      var domain_helix_svg_position_y = props.helix_idx_to_svg_position_y_map[moved_helix_idx]!;

      var helix = props.helices[moved_helix_idx]!;
      var group = props.groups[helix.group]!;
      var geometry = group.geometry ?? props.geometry;

      domains_moving.add((DesignMainDomainMoving()
        ..domain_moved = domain_moved
        ..color = props.color_of_domain[domain]!
        ..delta_view_order = domains_move.delta_view_order
        ..original_group = props.original_group
        ..current_group = props.current_group
        ..delta_offset = domains_move.delta_offset
        ..delta_forward = domains_move.delta_forward
        ..side_selected_helix_idxs = props.side_selected_helix_idxs
        ..helices = props.helices
        ..groups = props.groups
        ..allowable = domains_move.allowable
        ..geometry = geometry
        ..domain_helix_svg_position_y = domain_helix_svg_position_y
        ..key = key++)());
    }

    return (Dom.g()
      ..className =
          'domains-moving-main-view' + (domains_move.allowable ? '' : ' disallowed'))(domains_moving);
  }
}
