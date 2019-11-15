@JS()
library actions;

import 'dart:async';
import 'dart:math';

import 'package:js/js.dart';
import 'package:tuple/tuple.dart';
import 'package:w_flux/w_flux.dart';

import '../model/dna_design_action_packs.dart';
import '../model/select_mode.dart';
import '../model/selectable.dart';
import '../model/edit_mode.dart';
import '../model/helix.dart';
import '../model/grid_position.dart';
import '../model/mouseover_data.dart';
import '../model/strand.dart';
import '../model/bound_substrand.dart';
import '../model/loopout.dart';

/// An ActionPack has all the data needed to apply an [Action] (the "payload" in the terminology of w_flux).
/// It serves as a layer of abstraction between an Action in w_flux (which is a function called with a payload)
/// and the Undo/Redo stack (which needs the Action and payload packed into one object to put on the stack).
///
/// A [ReversibleActionPack] is added to the undo stack. Its reverse is applied as it is popped.
/// Often a ReversibleActionPack will contain more information than is needed simply to apply the Action,
/// in order also to have enough information to construct its reverse.
///
/// A: type of the [Action]
/// P: payload type for the [Action]
abstract class ReversibleActionPack<A extends Action<P>, P> {
  //}extends ActionPack<A, P> {
  final A action;
  final P payload;

  ReversibleActionPack(this.action, this.payload);

  ReversibleActionPack<A, P> reverse();

  apply() async {
    // for some react this.action(this.payload) does not compile, but we can call the method "call" explicitly
    print('action applied');
    return await this.action.call(this.payload);
  }
}

//abstract class ReversibleActionPack {
//  ReversibleActionPack reverse();
//  apply();
//}

/// Represents [Action]s to do in a batch. Useful for having a single action to undo/redo that is a composite
/// of many small ones, so the user doesn't have to press ctrl+Z multiple times to undo them all.
/// For example, deleting a [Helix] with [Strand]s on it implies the [Strand]s should be deleted first.
class BatchActionPack extends ReversibleActionPack {
  List<ReversibleActionPack> action_packs;

  BatchActionPack(this.action_packs) : super(null, null);

  apply() async {
    for (var action_pack in this.action_packs) {
      await action_pack.apply();
    }
  }

  BatchActionPack reverse() {
    // put Actions in reverse order, and reverse each Action
    List<ReversibleActionPack> reverse = [for (var action_pack in this.action_packs.reversed) action_pack.reverse()];
    return BatchActionPack(reverse);
  }
}

class Actions_OLD {
  // all reversible actions go through this Action
  static final reversible_action = Action<ReversibleActionPack>();

  // Save .dna file
  static final save_dna_file = Action<Null>();

  // Load .dna file
  static final load_dna_file = Action<LoadDNAFileParameters>();

  // Mouseover data (main view)
//  static final update_mouseover_data = Action<MouseoverParameters>();
  static final remove_mouseover_data = Action<Null>();

  // Side view position
  static final update_side_view_mouse_position = Action<Point<num>>();
  static final remove_side_view_mouse_position = Action<Null>();

  // Helix
  static final helix_use = Action<HelixUseActionParameters>();
  static final set_helices = Action<List<Helix>>();
  static final set_helix_rotation = Action<SetHelixRotationActionParameters>();

  // Strand
  static final strand_remove = Action<Strand>();
  static final strand_add = Action<Strand>();
  static final strands_remove = Action<Iterable<Strand>>();
  static final strands_add = Action<Iterable<Strand>>();

  // Strand UI model
  static final strand_select_toggle = Action<Strand>();
  static final five_prime_select_toggle = Action<BoundSubstrand>();
  static final three_prime_select_toggle = Action<BoundSubstrand>();
  static final loopout_select_toggle = Action<Loopout>();
  static final crossover_select_toggle = Action<Tuple2<BoundSubstrand, BoundSubstrand>>();

  static final unselect_all = Action<Null>();
  static final select = Action<Selectable>();
  static final select_all = Action<List<Selectable>>();
  static final unselect = Action<Selectable>();
  static final toggle = Action<Selectable>();
  static final toggle_all = Action<List<Selectable>>();

  static final delete_all = Action<DeleteAllParameters>();

  // Selection rectangle
  static final create_selection_box_toggling = Action<Point<num>>();
  static final create_selection_box_selecting = Action<Point<num>>();
  static final selection_box_size_changed = Action<Point<num>>();
  static final remove_selection_box = Action<Null>();

  // Errors (so there's no DNADesign to display, e.g., parsing error reading JSON file)
  static final set_error_message = Action<String>();

  // Edit mode
  static final set_edit_mode = Action<EditModeChoice>();

  // Menu
  static final set_show_dna = Action<bool>();
  static final set_show_mismatches = Action<bool>();
  static final set_show_editor = Action<bool>();

  // Select modes
  static final toggle_select_mode = Action<SelectModeChoice>();
  static final set_select_modes = Action<List<SelectModeChoice>>();
}


///////////////////////////////////////////////////////////////////////////////////////////////////////
// Load .dna file
class LoadDNAFileParameters {
  final String content;
  final String filename;

  LoadDNAFileParameters(this.content, this.filename);
}

///////////////////////////////////////////////////////////////////////////////////////////////////////
// Strand actions
class StrandRemoveActionPack extends ReversibleActionPack<Action<Strand>, Strand> {
  Strand strand;

  StrandRemoveActionPack(this.strand) : super(Actions_OLD.strand_remove, strand);

  @override
  ReversibleActionPack<Action<Strand>, Strand> reverse() {
    return StrandAddActionPack(this.strand);
  }
}

class StrandAddActionPack extends ReversibleActionPack<Action<Strand>, Strand> {
  Strand strand;

  StrandAddActionPack(this.strand) : super(Actions_OLD.strand_add, strand);

  @override
  ReversibleActionPack<Action<Strand>, Strand> reverse() {
    return StrandRemoveActionPack(this.strand);
  }
}

class StrandsRemoveActionPack extends ReversibleActionPack<Action<Iterable<Strand>>, Iterable<Strand>> {
  Iterable<Strand> strands;

  StrandsRemoveActionPack(this.strands) : super(Actions_OLD.strands_remove, strands);

  @override
  ReversibleActionPack<Action<Iterable<Strand>>, Iterable<Strand>> reverse() {
    return StrandsAddActionPack(this.strands);
  }
}

class StrandsAddActionPack extends ReversibleActionPack<Action<Iterable<Strand>>, Iterable<Strand>> {
  Iterable<Strand> strands;

  StrandsAddActionPack(this.strands) : super(Actions_OLD.strands_add, strands);

  @override
  ReversibleActionPack<Action<Iterable<Strand>>, Iterable<Strand>> reverse() {
    return StrandsRemoveActionPack(this.strands);
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////////////
// Helix actions

class SetHelixRotationActionParameters {
  final int idx;
  final int anchor;
  final num rotation;

  final int old_anchor;
  final num old_rotation;

  SetHelixRotationActionParameters(this.idx, this.anchor, this.rotation, this.old_anchor, this.old_rotation);

  SetHelixRotationActionParameters reverse() =>
      SetHelixRotationActionParameters(this.idx, this.old_anchor, this.old_rotation, this.anchor, this.rotation);
}

class SetHelixRotationActionPack
    extends ReversibleActionPack<Action<SetHelixRotationActionParameters>, SetHelixRotationActionParameters> {
  SetHelixRotationActionParameters params;

  SetHelixRotationActionPack(this.params) : super(Actions_OLD.set_helix_rotation, params);

  @override
  SetHelixRotationActionPack reverse() => SetHelixRotationActionPack(this.params.reverse());
}

class HelixUseActionParameters {
  final bool create;
  final GridPosition grid_position;
  final int idx;
  final int max_offset;
  final int min_offset;
  final int major_tick_distance;
  final List<int> major_ticks;

  HelixUseActionParameters(this.create, this.grid_position, this.idx, this.max_offset,
      {this.min_offset = 0, this.major_tick_distance = -1, this.major_ticks = null});

  HelixUseActionParameters reverse() =>
      HelixUseActionParameters(!this.create, this.grid_position, this.idx, this.max_offset,
          min_offset: this.min_offset, major_tick_distance: this.major_tick_distance, major_ticks: this.major_ticks);
}

class HelixUseActionPack extends ReversibleActionPack<Action<HelixUseActionParameters>, HelixUseActionParameters> {
  HelixUseActionParameters params;

  HelixUseActionPack(this.params) : super(Actions_OLD.helix_use, params);

  @override
  HelixUseActionPack reverse() => HelixUseActionPack(this.params.reverse());
}
