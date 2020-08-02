import 'package:color/color.dart';
import 'package:over_react/over_react.dart';
import 'package:built_collection/built_collection.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:scadnano/src/state/domain.dart';
import 'package:scadnano/src/state/domains_move.dart';

import '../state/group.dart';
import '../state/geometry.dart';
import '../state/helix.dart';
import '../state/app_state.dart';
import '../util.dart' as util;
import 'design_main_domain_moving.dart';

part 'design_main_domains_moving.over_react.g.dart';

UiFactory<DesignMainDomainsMovingProps> ConnectedDesignMainDomainsMoving =
    connect<AppState, DesignMainDomainsMovingProps>(mapStateToProps: (state) {
  var original_group, current_group;
  if (state.ui_state.domains_move != null) {
    original_group = util.original_group_from_domains_move(state.design, state.ui_state.domains_move);
    current_group = util.current_group_from_domains_move(state.design, state.ui_state.domains_move);
  }
  // Need to check this here, because we need to allow the middleware to let through the strands_move
  // object so that view/design.dart can issue a warning to the user on a mousemove event when the
  // left-click is depressed. But if we allow the strands_move to propagate to the view it throws
  // an exception since it assumes they are in the same group.
  bool selected_domains_on_multiple_groups = false;
  if (state.ui_state.domains_move != null) {
    var group_names = state.design.group_names_of_domains(state.ui_state.domains_move.domains_moving);
    selected_domains_on_multiple_groups = group_names.length > 1;
  }
  return DesignMainDomainsMoving()
    ..domains_move = selected_domains_on_multiple_groups ? null : state.ui_state.domains_move
    ..color_of_domain = state.design.color_of_domain
    ..groups = state.design.groups
    ..original_group = original_group
    ..current_group = current_group
    ..helices = state.design.helices
    ..side_selected_helix_idxs = state.ui_state.side_selected_helix_idxs
    ..geometry = state.design.geometry;
})(DesignMainDomainsMoving);

UiFactory<DesignMainDomainsMovingProps> DesignMainDomainsMoving = _$DesignMainDomainsMoving;

mixin DesignMainDomainsMovingProps on UiProps {
  DomainsMove domains_move;
  BuiltMap<Domain, Color> color_of_domain;
  HelixGroup original_group;
  HelixGroup current_group;
  BuiltMap<int, Helix> helices;
  BuiltMap<String, HelixGroup> groups;
  BuiltSet<int> side_selected_helix_idxs;
  Geometry geometry;
}

class DesignMainDomainsMovingComponent extends UiComponent2<DesignMainDomainsMovingProps> {
  @override
  render() {
    if (props.domains_move == null) {
      return null;
    }
    return (Dom.g()
      ..className = 'strands-moving-main-view' + (props.domains_move.allowable ? '' : ' disallowed'))([
      for (var domain in props.domains_move.domains_moving)
        (DesignMainDomainMoving()
          ..domain = domain
          ..color = props.color_of_domain[domain]
          ..delta_view_order = props.domains_move.delta_view_order
          ..original_group = props.original_group
          ..current_group = props.current_group
          ..delta_offset = props.domains_move.delta_offset
          ..delta_forward = props.domains_move.delta_forward
          ..side_selected_helix_idxs = props.side_selected_helix_idxs
          ..helices = props.helices
          ..groups = props.groups
          ..allowable = props.domains_move.allowable
          ..geometry = props.geometry
          ..key = domain.toString())()
    ]);
  }
}
