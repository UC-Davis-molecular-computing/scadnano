import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:redux/redux.dart';
import 'package:scadnano/src/state/crossover.dart';
import 'package:scadnano/src/state/dna_design.dart';
import 'package:scadnano/src/state/domain.dart';
import 'package:scadnano/src/state/helix.dart';
import 'package:scadnano/src/state/position3d.dart';
import 'package:tuple/tuple.dart';

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
    _async_helix_positions_set_based_on_crossovers_middleware(store.state);
  }
}

_async_helix_positions_set_based_on_crossovers_middleware(AppState state) async {
  List<Helix> helices = _get_helices_to_process(state);
  List<Tuple2<Address,Address>> addresses = _get_addresses_to_process(state, helices);
  if (addresses == null) return;
  List<RollXY> rolls_and_positions = _calculate_rolls_and_positions(state.dna_design, helices, addresses, 0);
  print('rolls_and_positions = \n${rolls_and_positions.map((r) => r.toString()).join("\n")}');
  _set_rolls_and_positions(helices, rolls_and_positions);
}

// Gets helices in order of their view order
List<Helix> _get_helices_to_process(AppState state) {
  DNADesign design = state.dna_design;
  List<Helix> helices;
  BuiltSet<int> selected_helix_idxs = state.ui_state.side_selected_helix_idxs;
  if (selected_helix_idxs.isEmpty) {
    helices = design.helices.values.toList();
  } else {
    helices = [for (var helix_idx in selected_helix_idxs) design.helices[helix_idx]];
  }
  helices.sort((h1, h2) => h1.view_order - h2.view_order);
  return helices;
}

/// gets addresses of crossovers selected by user between helices that are adjacent in [helices]
/// They come in pairs, one pair for each crossover, giving the addresses of those crossovers
/// on the two helices it connects.
/// returns null if two such crossovers are selected
/// if none are selected, finds the first (one with lowest offset on helix earlier in order in [helices])
List<Tuple2<Address, Address>> _get_addresses_to_process(AppState state, List<Helix> helices) {
  var dna_design = state.dna_design;
  var selected_crossovers = state.ui_state.selectables_store.selected_crossovers;
  var selected_crossovers_by_prev_helix_idx =
      _get_selected_crossovers_by_prev_helix_idx(selected_crossovers, helices, dna_design);

  List<Tuple2<Address, Address>> addresses = [];
  for (int i = 0; i < helices.length - 1; i++) {
    var helix_top = helices[i];
    var helix_bot = helices[i + 1];
    var helix_idx_top_bot = Tuple2<int, int>(helix_top.idx, helix_bot.idx);
    var crossovers_this_helices_pair = selected_crossovers_by_prev_helix_idx[helix_idx_top_bot];

    Address address_top, address_bot;

    // first try selected crossovers, but ensure there's at most one per pair of helices
    if (crossovers_this_helices_pair.length > 1) {
      var msg = '''You can select at most one crossover between any pair of adjacent helices.
But you have selected multiple crossovers between helices ${helix_top.idx} and ${helix_bot.idx}.
Please select only one, or select none to default to the first crossover between the helices.
''';
      util.async_alert(msg);
      return null;
    } else if (crossovers_this_helices_pair.length == 1) {
      // first try selected crossovers between this pair of helices
      address_top = crossovers_this_helices_pair.first.item1;
      //TODO: set address_bot in this case
    } else {
      // otherwise if none are selected, find the addresses of first crossover between this pair of helices
      var address_top_bot = _first_crossover_addresses_between_helices(helix_top, helix_bot, dna_design);
      address_top = address_top_bot.item1;
      address_bot = address_top_bot.item2;
      if (address_top == null) {
        var msg = 'Must have at least one crossover between helices ${helix_top.idx} and ${helix_bot.idx}';
        util.async_alert(msg);
        return null;
      }
    }
    addresses.add(Tuple2<Address, Address>(address_top, address_bot));
  }
  return addresses;
}

// "First" refers to having the lowest offset on helix h1.
Tuple2<Address, Address> _first_crossover_addresses_between_helices(
    Helix helix_top, Helix helix_bot, DNADesign dna_design) {
  BuiltList<Tuple2<Address, Crossover>> address_crossovers_on_top =
      dna_design.address_crossover_pairs_by_helix_idx[helix_top.idx];
  BuiltList<Tuple2<Address, Crossover>> address_crossovers_on_bot =
      dna_design.address_crossover_pairs_by_helix_idx[helix_bot.idx];

  // find first crossover on h1 that also goes to h2
  for (Tuple2<Address, Crossover> address_crossover_top in address_crossovers_on_top) {
    Crossover crossover_top = address_crossover_top.item2;
    for (var address_crossover_bot in address_crossovers_on_bot) {
      var crossover_bot = address_crossover_bot.item2;
      if (crossover_bot == crossover_top) {
        Address address_top = address_crossover_top.item1;
        Address address_bot = address_crossover_bot.item1;
        return Tuple2<Address, Address>(address_top, address_bot);
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
Map<Tuple2<int, int>, List<Tuple2<Address, Crossover>>> _get_selected_crossovers_by_prev_helix_idx(
    BuiltSet<Crossover> selected_crossovers, List<Helix> helices, DNADesign dna_design) {
  // this is essentially what we return, but each crossover also carries with it the start offset of
  // the helix earlier in the ordering, which helps to sort the lists of crossovers before returning
  Map<Tuple2<int, int>, List<Tuple2<Address, Crossover>>> address_crossover_pairs = {};

  // initialize internal map to have empty lists
  for (int i = 0; i < helices.length - 1; i++) {
    int idx1 = helices[i].idx;
    int idx2 = helices[i + 1].idx;
    var pair_idxs = Tuple2<int, int>(idx1, idx2);
    address_crossover_pairs[pair_idxs] = [];
  }

  // populate internal map with start offsets along with lists
  for (var crossover in selected_crossovers) {
    // below, prev and next refer to the crossover;
    // which helix is prev or next in the 5' --> 3' direction of the strand
    // This could be out of order with the relative order of those two helices in the helices parameter
    var strand = dna_design.crossover_to_strand[crossover];
    var prev_dom = strand.substrands[crossover.prev_domain_idx] as Domain;
    var next_dom = strand.substrands[crossover.next_domain_idx] as Domain;
    var prev_idx = prev_dom.helix;
    var next_idx = next_dom.helix;
    var pair_idxs = Tuple2<int, int>(prev_idx, next_idx);
    var pair_idxs_rev = Tuple2<int, int>(next_idx, prev_idx);

    if (address_crossover_pairs.containsKey(pair_idxs) ||
        address_crossover_pairs.containsKey(pair_idxs_rev)) {
      var top_dom = prev_dom;
      bool prev_is_top = true;
      if (address_crossover_pairs.containsKey(pair_idxs_rev)) {
        top_dom = next_dom;
        pair_idxs = pair_idxs_rev;
        prev_is_top = false;
      }
      int offset;
      // ugg, this logic is ugly. Here's the various possibilities
      /*
      !prev_is_top       prev_is_top        prev_is_top        !prev_is_top
      !top_dom.forward   top_dom.forward    !top_dom.forward   top_dom.forward
      <----+             [----+             +----]             +---->
           |                  |             |                  |
      [----+             <----+             +---->             +----]
       */
      if ((prev_is_top && top_dom.forward) || (!prev_is_top && !top_dom.forward)) {
        offset = top_dom.end - 1;
      } else {
        offset = top_dom.start;
      }
      var address = Address(helix_idx: top_dom.helix, offset: offset, forward: top_dom.forward);
      address_crossover_pairs[pair_idxs].add(Tuple2<Address, Crossover>(address, crossover));
    }
  }

  return address_crossover_pairs;
}

/// Represents a roll and 2D (x,y) position. The roll and position are both assigned to helices
/// after gather what these should be by examining crossovers.
class RollXY {
  double roll;
  double x;
  double y;

  RollXY({this.roll, this.x, this.y});

  String toString() => 'RollXY(roll=$roll, x=$x, y=$y)';
}

/// Return list of rolls, same length as [helices], giving the roll that each should be to point
/// each pair of helix backbones at each other through the given [addresses].
/// The first roll is [first_roll].
List<RollXY> _calculate_rolls_and_positions(
    DNADesign dna_design, List<Helix> helices, List<Tuple2<Address,Address>> addresses, double first_roll) {
  assert(helices.length == addresses.length + 1);
  double x = helices[0].position3d().x;
  double y = helices[0].position3d().y;
  List<RollXY> rollxys = [RollXY(roll: first_roll, x: x, y: y)];
  for (int i = 0; i < addresses.length; i++) {
    var address_top = addresses[i].item1;
    var address_bot = addresses[i].item2;
    var roll = rollxys[i].roll;
    var x = rollxys[i].x;
    var y = rollxys[i].y;
    double degrees_top = dna_design.helix_rotation_at(address_top, roll) - 90; // 0 is straight up, not right
    double radians_top = util.to_radians(degrees_top);
    var next_x = x + cos(radians_top) * constants.SIDE_HELIX_RADIUS * 2;
    var next_y = y + sin(radians_top) * constants.SIDE_HELIX_RADIUS * 2;

    double degrees_bot = dna_design.helix_rotation_at(address_bot, roll) - 90; // 0 is straight up, not right
    var next_roll = (degrees_top - degrees_bot + 180) % 360;
    rollxys.add(RollXY(roll: next_roll, x: next_x, y: next_y));
  }

  return rollxys;
}

_set_rolls_and_positions(List<Helix> helices, List<RollXY> rolls_and_positions) {
  List<actions.UndoableAction> all_actions = [];
  for (int i=0; i<helices.length; i++) {
    var helix = helices[i];
    var rollxy = rolls_and_positions[i];
    var roll_action = actions.HelixRollSet(helix_idx: helix.idx, roll: rollxy.roll);
    var position = Position3D(x: rollxy.x, y: rollxy.y, z: helix.position3d().z);
    var pos_action = actions.HelixPositionSet(helix_idx: helix.idx, position: position);
    all_actions.add(roll_action);
    all_actions.add(pos_action);
  }
  app.dispatch(actions.BatchAction(all_actions));
}