@JS()
library actions;

import 'package:js/js.dart';
import 'package:scadnano/src/model/edit_mode.dart';
import 'package:scadnano/src/model/helix.dart';
import 'package:scadnano/src/model/mouseover_data.dart';
import 'package:scadnano/src/model/strand.dart';
import 'package:tuple/tuple.dart';
import 'package:w_flux/w_flux.dart';


/// An ActionPack has all the data needed to apply an Action (the "payload" in the terminology of w_flux).
/// It serves as a layer of abstraction between an Action in w_flux (which is a function called with a payload)
/// and the Undo/Redo stack (which needs the Action and payload packed into one object to put on the stack).
/// A: type of the Action
/// P: payload type for the Action
//class ActionPack<A extends Action<P>, P> {
//  final A action;
//  final P payload;
//
//  ActionPack(this.action, this.payload);
//
//  apply() {
//    // for some react this.action(this.payload) does not compile, but we can call the method "call" explicitly
//    this.action.call(this.payload);
//  }
//}

/// An ActionPack has all the data needed to apply an Action (the "payload" in the terminology of w_flux).
/// It serves as a layer of abstraction between an Action in w_flux (which is a function called with a payload)
/// and the Undo/Redo stack (which needs the Action and payload packed into one object to put on the stack).
///
/// A ReversibleActionPack is added to the undo stack. Its reverse is applied as it is popped.
/// Often a ReversibleActionPack will contain more information than is needed simply to apply the Action,
/// in order also to have enough information to construct its reverse.
///
/// A: type of the Action
/// P: payload type for the Action
abstract class ReversibleActionPack<A extends Action<P>, P> { //}extends ActionPack<A, P> {
  final A action;
  final P payload;

  ReversibleActionPack(this.action, this.payload);

  ReversibleActionPack<A, P> reverse();

  apply() {
    // for some react this.action(this.payload) does not compile, but we can call the method "call" explicitly
    this.action.call(this.payload);
  }
}

/// Represents Actions to do in a batch. Useful for having a single action to undo/redo that is a composite
/// of many small ones, so the user doesn't have to press ctrl+z multiple times to undo them all.
/// For example, deleting a Helix with Strands on it implies the Strands should be deleted first.
class BatchActionPack extends ReversibleActionPack {
  List<ReversibleActionPack> action_packs;

  BatchActionPack(this.action_packs) : super(null, null);

  apply() {
    for (var action_pack in this.action_packs) {
      action_pack.apply();
    }
  }

  BatchActionPack reverse() {
    // put Actions in reverse order, and reverse each Action
    List<ReversibleActionPack> reverse = [for (var action_pack in this.action_packs.reversed) action_pack.reverse()];
    return BatchActionPack(reverse);
  }
}

class Actions {
  // Save .dna file
  static final save_dna_file = Action<Null>();

  // Load .dna file
  static final load_dna_file = Action<LoadDNAFileParameters>();

  // Mouseover data
  static final update_mouseover_data = Action<MouseoverParameters>();
  static final remove_mouseover_data = Action<Null>();

  // Helix
  static final helix_use = Action<HelixUseActionParameters>();
  static final set_helices = Action<List<Helix>>();
  static final set_potential_helices = Action<List<PotentialHelix>>();
  static final set_all_helices = Action<Tuple2<List<Helix>, List<PotentialHelix>>>();
  static final set_helix_rotation = Action<SetHelixRotationActionParameters>();

  // Strand
  static final strand_remove = Action<Strand>();
  static final strand_add = Action<Strand>();

  // Strand UI model
  static final add_strand_hover = Action<Strand>();
  static final remove_strand_hover = Action<Strand>();

  // Errors (so there's no DNADesign to display, e.g., parsing error reading JSON file)
  static final set_error_message = Action<String>();

  // Edit mode
  static final set_edit_mode = Action<EditModeChoice>();

  // Menu actions
  static final Action<bool> set_show_dna = Action<bool>();
  static final Action<bool> set_show_mismatches = Action<bool>();
  static final Action<bool> set_show_editor = Action<bool>();
}


//////////////////////////////////////////////////////////////////
// Load .dna file
class LoadDNAFileParameters {
  final String content;
  final String filename;

  LoadDNAFileParameters(this.content, this.filename);
}

//class LoadDNAFileActionPack extends ActionPack {
//  LoadDNAFileActionPack(LoadDNAFileParameters params) : super(Actions.load_dna_file, params);
//}


