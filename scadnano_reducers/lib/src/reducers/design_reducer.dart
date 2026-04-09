import 'package:redux/redux.dart';

import 'package:scadnano_state_actions/src/state/app_state.dart';
import 'util_reducer.dart';
import 'package:scadnano_state_actions/src/state/design.dart';
import 'package:scadnano_state_actions/src/actions/actions.dart' as actions;
import 'groups_reducer.dart';
import 'helices_reducer.dart';
import 'helix_group_move_reducer.dart';
import 'inline_insertions_deletions_reducer.dart';
import 'strands_reducer.dart';
import 'package:scadnano_state_actions/src/util_state.dart' as util;
import 'package:scadnano_state_actions/src/state/extension.dart';
import 'package:scadnano_state_actions/src/state/helix.dart';
import 'package:scadnano_state_actions/src/state/group.dart';
import 'package:scadnano_state_actions/src/state/domain.dart';
import 'package:scadnano_state_actions/src/state/strand.dart';
import 'package:scadnano_state_actions/src/state/grid_position.dart';
import 'package:scadnano_state_actions/src/state/grid.dart';
import 'package:scadnano_state_actions/src/constants.dart' as constants;
import 'package:scadnano_state_actions/src/state/position3d.dart';
import 'package:scadnano_state_actions/src/state/geometry.dart';
import 'dart:math';

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// reducer composition

Design? design_reducer(Design? design, action) {
  if (design != null) {
    design = design_composed_local_reducer(design, action);
    design = design_whole_local_reducer(design, action);
  }
  return design;
}

Design? design_global_reducer(Design? design, AppState state, action) {
  design = design_composed_global_reducer(design, state, action);
  design = design_whole_global_reducer(design, state, action);
  return design;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// composed/whole and local/global distinctions explained below

// composed: operate on slices of the DNADesign
// local: don't need the whole AppState
Design? design_composed_local_reducer(Design? design, action) => design?.rebuild(
  (d) =>
      d
        ..groups.replace(groups_local_reducer(design.groups, action))
        ..helices.replace(helices_local_reducer(design.helices, action))
        ..strands.replace(strands_local_reducer(design.strands, action)),
);

// composed: operate on slices of the DNADesign
// global: need the whole AppState
Design? design_composed_global_reducer(Design? design, AppState state, action) => design?.rebuild(
  (d) =>
      d
        ..groups.replace(groups_global_reducer(design.groups, state, action))
        ..helices.replace(helices_global_reducer(design.helices, state, action))
        ..strands.replace(strands_global_reducer(design.strands, state, action)),
);

// whole: operate on the whole DNADesign
// local: don't need the whole AppState
Reducer<Design?> design_whole_local_reducer = combineReducers([
  TypedReducer<Design?, actions.ErrorMessageSet>(design_error_message_set_reducer),
  TypedReducer<Design?, actions.InlineInsertionsDeletions>(inline_insertions_deletions_reducer),
  TypedReducer<Design?, actions.NewDesignSet>(new_design_set_reducer),
]);

// This isn't strictly necessary, but it would be nice for debugging if, whenever there is an error,
// the DNADesign in the Model is null.
Design? design_error_message_set_reducer(Design? design, actions.ErrorMessageSet action) =>
    action.error_message == null || action.error_message!.length == 0 ? design : null;

// whole: operate on the whole DNADesign
// global: need the whole AppState
GlobalReducer<Design?, AppState> design_whole_global_reducer = combineGlobalReducers([
  TypedGlobalReducer<Design?, AppState, actions.GeometrySet>(design_geometry_set_reducer),
  TypedGlobalReducer<Design?, AppState, actions.HelixIdxsChange>(helix_idx_change_reducer),
  TypedGlobalReducer<Design?, AppState, actions.HelixAdd>(helix_add_design_reducer),
  TypedGlobalReducer<Design?, AppState, actions.HelixRemove>(helix_remove_design_global_reducer),
  TypedGlobalReducer<Design?, AppState, actions.HelixRemoveAllSelected>(
    helix_remove_all_selected_design_global_reducer,
  ),
  TypedGlobalReducer<Design?, AppState, actions.HelixGroupMoveCommit>(helix_group_move_commit_global_reducer),
  TypedGlobalReducer<Design?, AppState, actions.ConvertExtensionsToBoundDomains>(
    convert_extensions_to_bound_domains_reducer,
  ),
]);

// need to operate on Design so we can re-set helix svg coordinates
Design? design_geometry_set_reducer(Design? design, AppState state, actions.GeometrySet action) {
  if (design == null) {
    return null;
  }
  var new_helices = design.helices.toMap();

  return design.rebuild(
    (b) =>
        b
          ..helices.replace(new_helices)
          ..geometry.replace(action.geometry),
  );
}

Design? new_design_set_reducer(Design? design, actions.NewDesignSet action) => action.design;

Design? convert_extensions_to_bound_domains_reducer(
  Design? design,
  AppState state,
  actions.ConvertExtensionsToBoundDomains action,
) {
  if (design == null) {
    return null;
  }

  return _convert_extensions_to_bound_domains(design, action.extension1, action.extension2);
}

Design _convert_extensions_to_bound_domains(Design design, Extension extension1, Extension? extension2) {
  // Step 1: Find the strands containing these extensions
  var strand1 = design.strands.firstWhere((s) => s.extensions.contains(extension1));
  Strand? strand2 =
      extension2 != null ? design.strands.firstWhere((s) => s.extensions.contains(extension2)) : null;

  // Step 2: Calculate the new helix group position and pitch angle
  var new_helix_idx = _get_next_helix_idx(design);
  var new_group_name = _get_unique_group_name(design, new_helix_idx);

  // Get geometry from the source helix group (where the neighboring domain is)
  var source_helix = design.helices[extension1.adjacent_domain.helix]!;
  var source_group = design.groups[source_helix.group]!;
  var source_geometry = source_group.geometry ?? design.geometry;

  // Step 3: Calculate the correct group position and pitch angle
  var group_positioning = _calculate_group_positioning(design, extension1, source_geometry);

  var new_group = HelixGroup(
    helices_view_order: [new_helix_idx],
    position: group_positioning.group_position,
    pitch: group_positioning.pitch_angle,
    yaw: 0,
    roll: 0,
    geometry: source_geometry, // Use the same geometry as the source group
  );

  // Step 4: Create the new helix positioned to coincide with extension1
  // Calculate the required helix length - should be the maximum of the two extensions
  // since they overlap at the connection point
  int total_length =
      extension2 != null
          ? [extension1.num_bases, extension2.num_bases].reduce((a, b) => a > b ? a : b)
          : extension1.num_bases;

  var new_helix = Helix(
    idx: new_helix_idx,
    grid: Grid.none,
    position: Position3D.origin, // Helix is at origin within its group
    group: new_group_name,
    min_offset: 0,
    max_offset: total_length,
    major_tick_start: 0,
  );

  // Step 5: Convert extensions to domains and update strands
  var updated_strands = design.strands.toList();

  // Replace extension1 with a forward domain
  // Both domains start at offset 0 and overlap at the connection point
  int domain1_start = 0;
  int domain1_end = extension1.num_bases;

  var new_domain1 = Domain(
    helix: new_helix_idx,
    forward: true,
    start: domain1_start,
    end: domain1_end,
    dna_sequence: extension1.dna_sequence, // Copy DNA sequence from extension
  );

  var updated_strand1 = _replace_extension_with_domain(strand1, extension1, new_domain1);
  // Call initialize() after modifying the strand to ensure proper setup
  updated_strand1 = updated_strand1.initialize();
  var strand1_idx = design.strands.indexOf(strand1);
  updated_strands[strand1_idx] = updated_strand1;

  // If there's a second extension, replace it with a reverse domain
  if (extension2 != null && strand2 != null) {
    // The second domain also starts at offset 0 and overlaps with the first domain
    int domain2_start = 0;
    int domain2_end = extension2.num_bases;

    var new_domain2 = Domain(
      helix: new_helix_idx,
      forward: false,
      start: domain2_start,
      end: domain2_end,
      dna_sequence: extension2.dna_sequence, // Copy DNA sequence from extension
    );

    var updated_strand2 = _replace_extension_with_domain(strand2, extension2, new_domain2);
    // Call initialize() after modifying the strand to ensure proper setup
    updated_strand2 = updated_strand2.initialize();
    var strand2_idx = design.strands.indexOf(strand2);
    updated_strands[strand2_idx] = updated_strand2;
  }

  // Step 6: Build the updated design
  var result = design.rebuild(
    (b) =>
        b
          ..groups.replace({...design.groups.asMap(), new_group_name: new_group})
          ..helices.replace({...design.helices.asMap(), new_helix_idx: new_helix})
          ..strands.replace(updated_strands),
  );

  return result;
}

class _GroupPositioning {
  final Position3D group_position;
  final double pitch_angle;

  _GroupPositioning(this.group_position, this.pitch_angle);
}

double _calculate_extension_world_angle(Extension extension, HelixGroup group) {
  // Use the same logic as compute_end_rotation from util.dart
  var adjacent_domain = extension.adjacent_domain;
  double display_angle = extension.display_angle;

  // Apply the same transformations as compute_end_rotation
  var radians = display_angle * 2 * pi / 360.0;
  num x = cos(radians);
  num y = sin(radians);

  // Apply the reflections from util.dart compute_end_rotation
  y = -y;
  if (!adjacent_domain.forward) {
    x = -x;
  }
  if ((adjacent_domain.forward && extension.is_5p) || (!adjacent_domain.forward && !extension.is_5p)) {
    x = -x;
  }

  // Convert back to degrees
  var reflected_radians = atan2(y, x);
  var degrees = reflected_radians * 360.0 / (2 * pi);

  // Account for the current group's pitch rotation
  double current_visual_angle = degrees + group.pitch;

  return current_visual_angle;
}

_GroupPositioning _calculate_group_positioning(Design design, Extension extension, Geometry geometry) {
  // Find the helix and group containing the adjacent domain
  var adjacent_domain = extension.adjacent_domain;
  var helix = design.helices[adjacent_domain.helix]!;
  var group = design.groups[helix.group]!;

  // Calculate the 3D position where the extension attaches to the domain
  var helix_position = helix.position3d(geometry);

  // Calculate the offset position on the helix
  int end_offset = extension.is_5p ? adjacent_domain.offset_5p : adjacent_domain.offset_3p;
  double offset_along_helix = end_offset * geometry.rise_per_base_pair;

  var attached_position = Position3D(
    x: helix_position.x,
    y: helix_position.y,
    z: helix_position.z + offset_along_helix,
  );

  // Transform by group position
  attached_position = attached_position + group.position;

  // If the adjacent domain is reverse, we need to adjust for the vertical offset
  // since reverse domains are drawn on the bottom half of the helix
  // Convert from SVG pixels to nanometers using geometry.svg_pixels_to_nm
  if (!adjacent_domain.forward) {
    double y_offset_nm = 2 * geometry.base_height_svg * geometry.svg_pixels_to_nm;
    attached_position = Position3D(
      x: attached_position.x,
      y: attached_position.y + y_offset_nm,
      z: attached_position.z,
    );
  }

  // Calculate the world angle of the extension
  double world_angle = _calculate_extension_world_angle(extension, group);

  // Calculate target visual angle for the new forward domain
  double target_visual_angle = world_angle;

  // For 5' extensions, the new domain should appear pointing in the opposite direction
  // because the extension was pointing towards the 5' end, but the new forward domain
  // starts from the 5' end and goes towards the 3' end
  if (extension.is_5p) {
    target_visual_angle += 180;
  }

  // For extensions next to reverse domains, the display angle interpretation is inverted
  // compared to forward domains, so we need to add 180 degrees to compensate
  if (!adjacent_domain.forward) {
    target_visual_angle += 180;
  }

  // The pitch angle should be set so that the forward domain at angle 0 appears
  // with the target visual angle: 0 + group_pitch = target_visual_angle
  double pitch_angle = target_visual_angle;

  // Calculate the group position based on where we want the connection to happen
  Position3D group_position;

  if (extension.is_5p) {
    // For 5' extensions: we want the 3' end of the new domain (at offset extension.num_bases)
    // to be positioned at the attached_position
    // The 3' end is at offset extension.num_bases along the helix, which after rotation by pitch_angle
    // becomes a vector in the pitched direction
    double connection_offset = extension.num_bases * geometry.rise_per_base_pair;

    // Convert the offset to world coordinates using the pitch angle
    // The helix runs along the Z axis (left/right), and the pitch angle rotates
    // the helix in the Y-Z plane (up/down and left/right in main view)
    double pitch_radians = pitch_angle * pi / 180.0;
    double offset_y = -connection_offset * sin(pitch_radians); // Y is up/down in main view
    double offset_z = -connection_offset * cos(pitch_radians); // Z is left/right in main view

    group_position = Position3D(
      x: attached_position.x, // X position stays the same (into/out of screen)
      y: attached_position.y + offset_y,
      z: attached_position.z + offset_z,
    );
  } else {
    // For 3' extensions: we want the 5' end of the new domain (at offset 0)
    // to be positioned at the attached_position
    // Since the helix is at origin in the group, the 5' end is at z = 0
    // So: group_position + (0, 0, 0) = attached_position
    // Therefore: group_position = attached_position
    group_position = attached_position;
  }

  return _GroupPositioning(group_position, pitch_angle);
}

int _get_next_helix_idx(Design design) {
  if (design.helices.isEmpty) {
    return 0;
  }
  return design.helices.keys.fold(0, (max, idx) => idx > max ? idx : max) + 1;
}

String _get_unique_group_name(Design design, int helix_idx) {
  String candidate = 'group_${helix_idx}';
  int counter = 0;
  while (design.groups.containsKey(candidate)) {
    counter++;
    candidate = 'group_${helix_idx}_${counter}';
  }
  return candidate;
}

Strand _replace_extension_with_domain(Strand strand, Extension extension, Domain new_domain) {
  var substrands = strand.substrands.toList();
  var extension_index = substrands.indexOf(extension);

  if (extension_index == -1) {
    throw ArgumentError('Extension not found in strand');
  }

  substrands[extension_index] = new_domain;

  return strand.rebuild((b) => b..substrands.replace(substrands));
}
