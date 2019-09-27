@JS()
library actions;

import 'package:js/js.dart';
import 'package:w_flux/w_flux.dart';

import 'model/model.dart';

import 'model/strand.dart';
import 'app.dart';
import 'model/helix.dart';
import 'util.dart' as util;
import 'constants.dart' as constants;

//////////////////////////////////////////////////////////////////////////////
/// A ReversibleAction is added to the undo stack. Its reverse is executed as it is popped.
abstract class ReversibleAction<T> extends Action<T> {
  /// Get the ReversibleAction that, if applied to the model, undoes this ReversibleAction.
  ReversibleAction<T> reverse();

  ReversibleAction() : super();
}

abstract class ActionParameters {}

abstract class ReversibleActionParameters extends ActionParameters {
  /// Get the ReversibleActionParameters that, if applied to the model, undoes this Action represented
  /// by the original parameters.
  ReversibleActionParameters reverse();
}

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
    app.controller.notifier_loaded_dna_filename.add(this.new_filename);
    return model;
  }
}

//////////////////////////////////////////////////////////////////////////////
/// Change whether a Helix is used or not.

//class HelixUseAction implements ReversibleAction {
//  final bool use;
//  final Helix helix;
//  final PotentialHelix potential_helix;
//
//  // idx of Helix when it was used (before if use=true, after if use=false)
//  final int idx;
//
//  /// use: whether to set the Helix as used
//  /// helix: the helix to set
//  HelixUseAction(this.use, this.helix, this.potential_helix, this.idx);
//
//  @override
//  Model apply(Model model) {
//    var design = model.dna_design;
//    if (this.use) {
//      var new_idx = this.idx;
//      this.helix.set_idx(new_idx);
//      design.helices.insert(new_idx, this.helix);
//      for (var helix_after_idx_used in design.helices.sublist(new_idx + 1)) {
//        helix_after_idx_used.idx++;
////        app.controller.notifier_helix_change_used.add(helix_after_idx_used);
////        helix_after_idx_used.notify_changed();
//      }
//    } else {
//      int old_idx = this.helix.idx;
//      assert(old_idx == this.idx);
//      design.helices.removeAt(old_idx);
//      this.helix.set_idx(-1);
////      app.controller.notifier_helix_change_used.add(this.helix);
//      for (var helix_after_idx_unused in design.helices.sublist(old_idx)) {
//        helix_after_idx_unused.idx--;
////        app.controller.notifier_helix_change_used.add(helix_after_idx_unused);
//      }
//    }
////    app.controller.notifier_helix_change_used.add(this.helix);
//    return model;
//  }
//
//  @override
//  ReversibleAction reverse() {
//    return HelixUseAction(!this.use, this.helix, this.potential_helix, this.idx);
//  }
//}

//////////////////////////////////////////////////////////////////////////////
/// Change whether to show the DNA sequence of each strand
class ShowDNAAction implements ActionCustom {
  final bool show_dna;

  ShowDNAAction(this.show_dna);

  @override
  Model apply(Model model) {
    model.show_dna = this.show_dna;
    return model;
  }
}

//////////////////////////////////////////////////////////////////////////////
/// Change whether to show mismatches on overlapping strands
class ShowMismatchesAction implements ActionCustom {
  final bool show_mismatches;

  ShowMismatchesAction(this.show_mismatches);

  @override
  Model apply(Model model) {
    model.show_mismatches = this.show_mismatches;
    return model;
  }
}

//////////////////////////////////////////////////////////////////////////////
/// Change whether to show the DNA sequence of each strand
class ShowEditorAction implements ActionCustom {
  final bool show_editor;

  ShowEditorAction(this.show_editor);

  @override
  Model apply(Model model) {
    model.show_editor = this.show_editor;
    app.controller.notifier_show_editor_change.add(this.show_editor);
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
    app.controller.notifier_model_changed_since_save.add(false);
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

//class UpdateMouseOverDataAction implements ActionCustom {
//  final int helix_idx;
//  final int offset;
//  final bool forward;
//
//  UpdateMouseOverDataAction(this.helix_idx, this.offset, this.forward);
//
//  @override
//  Model apply(Model model) {
//    BoundSubstrand substrand = null;
//    for (Substrand ss in app.model.dna_design.substrands_on_helix(this.helix_idx)) {
//      if (ss.is_bound_substrand()) {
//        var bound_ss = ss as BoundSubstrand;
//        if (bound_ss.contains_offset(this.offset) && bound_ss.forward == this.forward) {
//          substrand = ss;
//          break;
//        }
//      }
//    }
//    model.main_view_ui_model.mouse_over_store.give_data(this.helix_idx, this.offset, substrand);
//    return model;
//  }
//}
//
//class RemoveMouseOverDataAction implements ActionCustom {
//  @override
//  Model apply(Model model) {
//    model.main_view_ui_model.mouse_over_store.remove_data();
//    return model;
//  }
//}
