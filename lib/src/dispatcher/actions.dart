@JS()
library actions;

import 'package:js/js.dart';
import 'package:scadnano/src/model/helix.dart';
import 'package:scadnano/src/model/strand.dart';
import 'package:tuple/tuple.dart';
import 'package:w_flux/w_flux.dart';

import '../model/model.dart';

import '../app.dart';
import '../util.dart' as util;
import '../constants.dart' as constants;

/// An ActionPack has all the data needed to apply an Action. It serves as a layer of abstraction between an
/// Action in w_flux and the Undo/Redo stack.
/// P: payload type for the Action
/// A: type of the Action
class ActionPack<A extends Action<P>, P> {
  final A action;
  final P payload;

  ActionPack(this.action, this.payload);

  apply() {
    this.action.call(this.payload);
  }
}

/// A ReversibleActionPack is added to the undo stack. Its reverse is applied as it is popped.
abstract class ReversibleActionPack<A extends Action<P>, P> extends ActionPack<A, P> {
  ReversibleActionPack(A action, P payload) : super(action, payload);

  ReversibleActionPack<A, P> reverse();
}

/// Represents Actions to do in a batch. Useful for having a single action to undo/redo that is a composite of many
/// small ones, so the user doesn't have to press ctrl+z multiple times to undo them all.
class BatchActionPack extends ReversibleActionPack {
  List<ReversibleActionPack> action_packs;

  BatchActionPack(this.action_packs) : super(null, null);

  apply() {
    for (var action_pack in this.action_packs) {
      action_pack.apply();
    }
  }

  BatchActionPack reverse() {
    List<ReversibleActionPack> reverse = [for (var action_pack in this.action_packs.reversed) action_pack.reverse()];
    return BatchActionPack(reverse);
  }
}

class Actions {
  static final strand_remove = Action<Strand>();
  static final strand_add = Action<Strand>();
  static final use_helix = Action<HelixUseActionParameters>();
  static final set_helices = Action<List<Helix>>();
  static final set_potential_helices = Action<List<PotentialHelix>>();
  static final set_all_helices = Action<Tuple2<List<Helix>, List<PotentialHelix>>>();
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
