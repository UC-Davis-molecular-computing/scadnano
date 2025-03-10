import 'dart:html';
import 'dart:math';

import 'package:meta/meta.dart';
import 'package:built_collection/built_collection.dart';
import 'package:redux/redux.dart';
import 'package:scadnano/src/state/grid.dart';
import 'package:scadnano/src/state/group.dart';
import '../state/crossover.dart';
import '../state/design.dart';
import '../state/domain.dart';
import '../state/geometry.dart';
import '../state/helix.dart';
import '../state/position3d.dart';

import '../state/address.dart';
import '../actions/actions.dart' as actions;
import '../app.dart';
import '../util.dart' as util;
import '../constants.dart' as constants;
import '../state/app_state.dart';

/// Set positions of helices based on crossovers, assuming all helices are parallel.
/// Dispatches a normal HelixPositionSet action (many of them batched).
/// Also changes the roll of each Helix to point those crossovers at each other in the new positions.
helix_positions_set_based_on_crossovers_middleware(
    Store<AppState> store, dynamic action, NextDispatcher next) {
  next(action);
  if (action is actions.HelicesPositionsSetBasedOnCrossovers) {
    var all_actions = get_helix_position_and_roll_actions(store.state);
    store.dispatch(actions.BatchAction(all_actions, "set helix coordinates based on crossovers"));
  }
}

List<actions.UndoableAction> get_helix_position_and_roll_actions(AppState state) {
  // figure out which groups to skip and warn user if there are any
  List<String> group_names_to_skip = [];
  for (var group_name in state.design.groups.keys) {
    var group = state.design.groups[group_name]!;
    if (group.grid != Grid.none) {
      group_names_to_skip.add(group_name);
    }
  }
  if (group_names_to_skip.isNotEmpty) {
    window.alert('Skipping helix groups ${group_names_to_skip.join(", ")} '
        'because their grids are not "none".');
  }

  List<actions.UndoableAction> all_actions = [];

  // process remaining groups
  for (var group_name in state.design.groups.keys) {
    if (group_names_to_skip.contains(group_name)) continue;
    var group = state.design.groups[group_name]!;
    var geometry = group.geometry ?? state.design.geometry;
    List<Helix> helices = _get_helices_to_process(state, group);
    List<(Address, Address)>? addresses = _get_addresses_to_process(state, helices);
    if (addresses == null) {
      continue;
    }
    double first_roll = helices[0].roll;
    List<RollXY> rolls_and_positions =
        _calculate_rolls_and_positions(state.design, geometry, helices, addresses, first_roll);
    var all_actions_this_group = set_rolls_and_positions(helices, rolls_and_positions, geometry);
    all_actions.addAll(all_actions_this_group);
  }

  return all_actions;
}

// Gets helices in order of their view order
List<Helix> _get_helices_to_process(AppState state, HelixGroup group) {
  Design design = state.design;
  List<Helix> helices;
  BuiltSet<int> selected_helix_idxs = state.ui_state.side_selected_helix_idxs;
  if (selected_helix_idxs.isEmpty) {
    helices = design.helices.values.toList();
  } else {
    helices = [for (var helix_idx in selected_helix_idxs) design.helices[helix_idx]!];
  }
  helices.sort(
      (h1, h2) => group.helices_view_order_inverse[h1.idx]! - group.helices_view_order_inverse[h2.idx]!);
  return helices;
}

/// gets addresses of crossovers selected by user between helices that are adjacent in [helices]
/// They come in pairs, one pair for each crossover, giving the addresses of those crossovers
/// on the two helices it connects.
/// returns null if two such crossovers are selected
/// if none are selected, finds the first (one with lowest offset on helix earlier in order in [helices])
List<(Address, Address)>? _get_addresses_to_process(AppState state, List<Helix> helices) {
  var design = state.design;
  var selected_crossovers = state.ui_state.selectables_store.selected_crossovers;
  var addresses_of_selected_crossovers_by_prev_helix_idx =
      _get_addresses_of_selected_crossovers_by_prev_helix_idx(selected_crossovers, helices, design);

  List<(Address, Address)> addresses = [];
  for (int i = 0; i < helices.length - 1; i++) {
    var helix_top = helices[i];
    var helix_bot = helices[i + 1];
    (int, int) helix_idx_top_bot = (helix_top.idx, helix_bot.idx);
    var addresses_crossovers_this_helices_pair =
        addresses_of_selected_crossovers_by_prev_helix_idx[helix_idx_top_bot]!;

    Address address_top, address_bot;

    // first try selected crossovers, but ensure there's at most one per pair of helices
    if (addresses_crossovers_this_helices_pair.length > 1) {
      var msg = '''You can select at most one crossover between any pair of adjacent helices.
But you have selected multiple crossovers between helices ${helix_top.idx} and ${helix_bot.idx}.
Please select only one, or select none to default to the first crossover between the helices.
''';
      util.async_alert(msg);
      return null;
    } else if (addresses_crossovers_this_helices_pair.length == 1) {
      // first try selected crossovers between this pair of helices
      address_top = addresses_crossovers_this_helices_pair.first.$1;
      address_bot = addresses_crossovers_this_helices_pair.first.$2;
    } else {
      // otherwise if none are selected, find the addresses of first crossover between this pair of helices
      // using boolean scaffold/staple settings from user to possible ignore one of those types
      (Address, Address)? address_top_bot;
      bool use_scaffold = state.ui_state.default_crossover_type_scaffold_for_setting_helix_rolls;
      bool use_staple = state.ui_state.default_crossover_type_staple_for_setting_helix_rolls;

      if (!state.design.is_origami) {
        use_scaffold = use_staple = true;
      }
      address_top_bot = _first_crossover_addresses_between_helices(helix_top, helix_bot, design,
          use_scaffold: use_scaffold, use_staple: use_staple);

      if (address_top_bot == null) {
        var msg = 'Must have at least one crossover between helices ${helix_top.idx} and ${helix_bot.idx}';
        util.async_alert(msg);
        return null;
      }
      address_top = address_top_bot.$1;
      address_bot = address_top_bot.$2;
    }
    addresses.add((address_top, address_bot));
  }
  return addresses;
}

// "First" refers to having the lowest offset on helix h1.
(Address, Address)? _first_crossover_addresses_between_helices(
    Helix helix_top, Helix helix_bot, Design design,
    {required bool use_scaffold, required bool use_staple}) {
  BuiltList<(Address, Crossover)> address_crossovers_on_top =
      design.address_crossover_pairs_by_helix_idx[helix_top.idx]!;
  BuiltList<(Address, Crossover)> address_crossovers_on_bot =
      design.address_crossover_pairs_by_helix_idx[helix_bot.idx]!;

  // if not using scaffold or crossovers when finding leftmost, filter those out
  if (!use_scaffold) {
    address_crossovers_on_bot = address_crossovers_on_bot
        .where((address_crossover) => !address_crossover.$2.is_scaffold)
        .toBuiltList();
  }
  if (!use_staple) {
    address_crossovers_on_bot = address_crossovers_on_bot
        .where((address_crossover) => address_crossover.$2.is_scaffold)
        .toBuiltList();
  }

  // find first crossover on h1 that also goes to h2
  for ((Address, Crossover) address_crossover_top in address_crossovers_on_top) {
    Crossover crossover_top = address_crossover_top.$2;
    for (var address_crossover_bot in address_crossovers_on_bot) {
      var crossover_bot = address_crossover_bot.$2;
      if (crossover_bot == crossover_top) {
        Address address_top = address_crossover_top.$1;
        Address address_bot = address_crossover_bot.$1;
        return (address_top, address_bot);
      }
    }
  }

  // maybe none on helix_top go to helix_bot
  return null;
}

// Return map mapping (prev,next) helix idx to list of (offset,crossover) pairs
// between helices prev and next, only for values of prev,next that are adjacent in helices.
// The offset is where the crossover connects to the first helix
// e.g., if indices of helices are 3,2,7,5 (in that order in argument helices), returns map
// {
//   (3,2): [... (offset,crossover) pairs between 2 and 3, offset is where crossover touches helix 3],
//   (2,7): [... (offset,crossover) pairs between 2 and 7, offset is where crossover touches helix 2],
//   (7,5): [... (offset,crossover) pairs between 5 and 7, offset is where crossover touches helix 7]
// }
// Sorts each list by the offset on its first helix (first meaning first in order in helices)
Map<(int, int), List<(Address, Address)>> _get_addresses_of_selected_crossovers_by_prev_helix_idx(
    BuiltSet<Crossover> selected_crossovers, List<Helix> helices, Design design) {
  // this is essentially what we return, but each crossover also carries with it the start offset of
  // the helix earlier in the ordering, which helps to sort the lists of crossovers before returning
  Map<(int, int), List<(Address, Address)>> addresses_top_bot_crossovers = {};

  // initialize internal map to have empty lists
  for (int i = 0; i < helices.length - 1; i++) {
    int idx1 = helices[i].idx;
    int idx2 = helices[i + 1].idx;
    (int, int) pair_idxs = (idx1, idx2);
    addresses_top_bot_crossovers[pair_idxs] = [];
  }

  // populate internal map with start offsets along with lists
  for (var crossover in selected_crossovers) {
    // below, prev and next refer to the crossover;
    // which helix is prev or next in the 5' --> 3' direction of the strand
    // This could be out of order with the relative order of those two helices in the helices parameter
    var strand = design.crossover_to_strand[crossover]!;
    var prev_dom = strand.substrands[crossover.prev_domain_idx] as Domain;
    var next_dom = strand.substrands[crossover.next_domain_idx] as Domain;
    var prev_idx = prev_dom.helix;
    var next_idx = next_dom.helix;
    (int, int) pair_idxs = (prev_idx, next_idx);
    (int, int) pair_idxs_rev = (next_idx, prev_idx);

    if (addresses_top_bot_crossovers.containsKey(pair_idxs) ||
        addresses_top_bot_crossovers.containsKey(pair_idxs_rev)) {
      var dom_top = prev_dom;
      var dom_bot = next_dom;
      bool prev_is_top = true;
      if (addresses_top_bot_crossovers.containsKey(pair_idxs_rev)) {
        dom_top = next_dom;
        dom_bot = prev_dom;
        pair_idxs = pair_idxs_rev;
        prev_is_top = false;
      }
      int offset_top, offset_bot;
      // ugg, this logic is ugly. Here's the various possibilities
      /*
      !prev_is_top       prev_is_top        prev_is_top        !prev_is_top
      !dom_top.forward   dom_top.forward    !dom_top.forward   dom_top.forward
      <----+             [----+             +----]             +---->
           |                  |             |                  |
       */
      if ((prev_is_top && dom_top.forward) || (!prev_is_top && !dom_top.forward)) {
        offset_top = dom_top.end - 1;
      } else {
        offset_top = dom_top.start;
      }
      /*
      !prev_is_top       prev_is_top        prev_is_top        !prev_is_top
      dom_bot.forward    !dom_bot.forward   dom_bot.forward    !dom_bot.forward
           |                  |             |                  |
      [----+             <----+             +---->             +----]
       */
      if ((prev_is_top && dom_bot.forward) || (!prev_is_top && !dom_bot.forward)) {
        offset_bot = dom_bot.start;
      } else {
        offset_bot = dom_bot.end - 1;
      }
      var address_top = Address(helix_idx: dom_top.helix, offset: offset_top, forward: dom_top.forward);
      var address_bot = Address(helix_idx: dom_bot.helix, offset: offset_bot, forward: dom_bot.forward);
      addresses_top_bot_crossovers[pair_idxs]!.add((address_top, address_bot));
    }
  }

  return addresses_top_bot_crossovers;
}

/// Represents a roll and 2D (x,y) position. The roll and position are both assigned to helices
/// after gather what these should be by examining crossovers.
class RollXY {
  double roll;
  double x;
  double y;

  RollXY({required this.roll, required this.x, required this.y});

  String toString() => 'RollZY(roll=$roll, x=$x, y=$y)';
}

//XXX: be careful editing this function; this logic was very tricky to get correct
/// Return list of rolls, same length as [helices], giving the roll that each should be to point
/// each pair of helix backbones at each other through the given [addresses].
/// The first roll is [first_roll].
List<RollXY> _calculate_rolls_and_positions(Design design, Geometry geometry, List<Helix> helices,
    List<(Address, Address)> addresses, double first_roll) {
  assert(helices.length == addresses.length + 1);

  double x = helices[0].position3d(geometry).z;
  double y = helices[0].position3d(geometry).y;
  List<RollXY> rollxys = [RollXY(roll: first_roll, x: x, y: y)];

  for (int i = 0; i < addresses.length; i++) {
    var address_top = addresses[i].$1;
    var address_bot = addresses[i].$2;
    var roll = rollxys[i].roll;
    var x = rollxys[i].x;
    var y = rollxys[i].y;

    var degrees_top = design.helix_rotation_at(address_top, roll);
    // 0 is straight up, not right as in Cartesian rotation, so we have to convert
    var radians_top_cartesian = util.to_radians(degrees_top - 90);
    var next_x = x + cos(radians_top_cartesian) * geometry.distance_between_helices_nm;
    var next_y = y + sin(radians_top_cartesian) * geometry.distance_between_helices_nm;

    // now back to using our "0 is straight up" rotation coordinate system
    // first calculate angle that strand on bottom helix, at crossover's offset on bottom helix,
    // should have after we are done
    var angle_strand_bot = (degrees_top + 180) % 360;
    if (!address_bot.forward) {
      // translate to the angle of the forward strand
      angle_strand_bot = (angle_strand_bot - 150) % 360;
    }
    // then find out *current* angle at that offset (of forward strand, since that defines roll by convention)
    var address_bot_forward = address_bot.rebuild((b) => b..forward = true);
    var current_roll_at_address_bot = design.helix_rotation_at(address_bot_forward);
    // now calculate difference between what we want (angle_strand_bot)
    // and what we have now (current_roll_at_address_bot)
    var delta_roll = (angle_strand_bot - current_roll_at_address_bot) % 360;
    Helix helix_bot = helices[i + 1];
    // add this difference to the roll (which is defined at offset min_offset)
    var new_roll = (helix_bot.roll + delta_roll) % 360;
    rollxys.add(RollXY(roll: new_roll, x: next_x, y: next_y));
  }

  return rollxys;
}

List<actions.UndoableAction> set_rolls_and_positions(
    List<Helix> helices, List<RollXY> rolls_and_positions, Geometry geometry) {
  List<actions.UndoableAction> all_actions = [];
  for (int i = 0; i < helices.length; i++) {
    var helix = helices[i];
    var rollxy = rolls_and_positions[i];
    var roll_action = actions.HelixRollSet(helix_idx: helix.idx, roll: rollxy.roll);
    var position = Position3D(x: rollxy.x, y: rollxy.y, z: helix.position3d(geometry).z);
    var pos_action = actions.HelixPositionSet(helix_idx: helix.idx, position: position);
    all_actions.add(roll_action);
    all_actions.add(pos_action);
  }
  return all_actions;
//  store.dispatch(actions.BatchAction(all_actions));
}
