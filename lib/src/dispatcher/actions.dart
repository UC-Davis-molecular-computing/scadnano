@JS()
library actions;

import 'package:js/js.dart';
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
class ActionPack<A extends Action<P>, P> {
  final A action;
  final P payload;

  ActionPack(this.action, this.payload);

  apply() {
    // for some react this.action(this.payload) does not compile, but we can call the method "call" explicitly
    this.action.call(this.payload);
  }
}

/// A ReversibleActionPack is added to the undo stack. Its reverse is applied as it is popped.
/// Often a ReversibleActionPack will contain more information than is needed simply to apply the Action,
/// in order also to have enough information to construct its reverse.
abstract class ReversibleActionPack<A extends Action<P>, P> extends ActionPack<A, P> {
  ReversibleActionPack(A action, P payload) : super(action, payload);

  ReversibleActionPack<A, P> reverse();
}

/// Represents Actions to do in a batch. Useful for having a single action to undo/redo that is a composite of many
/// small ones, so the user doesn't have to press ctrl+z multiple times to undo them all.
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
  // Mouseover data
  static final Action<MouseoverParameters> update_mouseover_data = Action<MouseoverParameters>();
  static final Action<Null> remove_mouseover_data = Action<Null>();

  // Helix
  static final helix_use = Action<HelixUseActionParameters>();
  static final set_helices = Action<List<Helix>>();
  static final set_potential_helices = Action<List<PotentialHelix>>();
  static final set_all_helices = Action<Tuple2<List<Helix>, List<PotentialHelix>>>();

  // Strand
  static final strand_remove = Action<Strand>();
  static final strand_add = Action<Strand>();

  // Errors (so there's no DNADesign to display, e.g., parsing error reading JSON file)
  static final set_error_message = Action<String>();
}

/*

//////////////////////////////////////////////////////////////////////////////
///XXX: below here is old and should go away eventually as we migrate to OverReact and w_flux Actions

/// A (non-reversible) Action is not added to the undo stack.
abstract class ActionCustom {
  /// Apply this action to model and return the resulting model.
  /// This can mutate the model in place or create a new one, but the resulting
  /// model should be returned in either case.
  /// WARNING: this should not be called directly. Instead, call app.send_action(the_action);
  Model apply(Model model);
}

/// A ReversibleAction is added to the undo stack. Its reverse is executed as it is popped.
abstract class CustomReversibleAction implements ActionCustom {
  /// Get the ReversibleAction that, if applied to the model, undoes this ReversibleAction.
  CustomReversibleAction reverse();
}

//////////////////////////////////////////////////////////////////////////////
/// load new DNADesign

//////////////////////////////////////////////////////////////////////////////
/// Change loaded filename

class LoadedFilenameAction implements ActionCustom {
  final String new_filename;
  final String old_filename;

  LoadedFilenameAction(this.new_filename, this.old_filename);

  @override
  Model apply(Model model) {
    model.menu_view_ui_model.loaded_filename = this.new_filename;
//    app.controller.notifier_loaded_dna_filename.add(this.new_filename);
    return model;
  }
}

//////////////////////////////////////////////////////////////////////////////
/// Update editor contents.
class EditorContentAction implements ActionCustom {
  final String new_content;

  EditorContentAction(this.new_content);

  @override
  Model apply(Model model) {
    model.editor_content = this.new_content;
    util.save_editor_content_to_js_context(this.new_content);
    return model;
  }
}

/// This doesn't actually save the file (that's a side effect). It alerts the model
/// that the file was saved so "model changed since last save" should be false.
class AlertFileSavedAction implements ActionCustom {
  @override
  Model apply(Model model) {
    model.changed_since_last_save = false;
//    app.controller.notifier_model_changed_since_save.add(false);
    return model;
  }
}

@JS(constants.js_function_name_compile)
external js_compile(String code);

class CompileAction implements ActionCustom {
  @override
  Model apply(Model model) {
    print('compile action being applied');
    var python_code = app.model.editor_content;

    js_compile(python_code);

    //TODO: get design from python code and put in model

    return model;
  }
}
 */
