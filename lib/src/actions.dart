import 'dart:async';

import 'app.dart';
import 'model.dart';

//////////////////////////////////////////////////////////////////////////////
/// load new DNADesign

//////////////////////////////////////////////////////////////////////////////
/// Change loaded filename

class LoadedFilenameAction implements Action {
  final String new_filename;
  final String old_filename;

  LoadedFilenameAction(this.new_filename, this.old_filename);

  @override
  Model apply(Model model) {
    model.menu_view_ui_model.loaded_filename = this.new_filename;
    app.controller.notifier_loaded_filename.add(this.new_filename);
    return model;
  }

  @override
  Action reverse() {
    return LoadedFilenameAction(this.old_filename, this.new_filename);
  }
}

//////////////////////////////////////////////////////////////////////////////
/// Change whether a Helix is used or not.

class HelixUseAction implements Action {
  final bool use;
  final Helix helix;
  // idx of Helix when it was used (before if use=true, after if use=false)
  final int idx;

  /// use: whether to set the Helix as used
  /// helix: the helix to set
  HelixUseAction(this.use, this.helix, this.idx);

  @override
  Model apply(Model model) {
    var design = model.dna_design;
    if (this.use) {
      var new_idx = this.idx;
      this.helix.idx = new_idx;
      design.used_helices.insert(new_idx, this.helix);
      for (var helix_after_idx_used in design.used_helices.sublist(new_idx + 1)) {
        helix_after_idx_used.idx++;
        app.controller.notifier_helix_change.add(helix_after_idx_used);
      }
    } else {
      int old_idx = this.helix.idx;
      assert(old_idx == this.idx);
      design.used_helices.removeAt(old_idx);
      this.helix.idx = -1;
//      this.helix.used = false;
      app.controller.notifier_helix_change.add(this.helix);
      for (var helix_after_idx_unused in design.used_helices.sublist(old_idx)) {
        helix_after_idx_unused.idx--;
        app.controller.notifier_helix_change.add(helix_after_idx_unused);
      }
    }
    app.controller.notifier_helix_change.add(this.helix);
    return model;
  }

  @override
  Action reverse() {
    return HelixUseAction(!this.use, this.helix, this.idx);
  }
}

//////////////////////////////////////////////////////////////////////////////
/// Change whether to show the DNA sequence of each strand
class ShowDNAAction implements Action {
  final bool show_dna;

  ShowDNAAction(this.show_dna);

  @override
  Model apply(Model model) {
    model.show_dna = this.show_dna;
    app.controller.notifier_show_dna_change.add(this.show_dna);
    return model;
  }

  @override
  Action reverse() {
    return ShowDNAAction(!this.show_dna);
  }
}

//////////////////////////////////////////////////////////////////////////////
/// Update editor contents.
class EditorContentAction implements Action {

  final String new_content;
  final String old_content;

  EditorContentAction(this.new_content, this.old_content);

  @override
  Model apply(Model model) {
    print('editor content before change:\n${model.editor_content}\n');
    model.editor_content = this.new_content;
    print('editor content after change:\n${model.editor_content}\n');
    return model;
  }

  @override
  Action reverse() {
    return EditorContentAction(this.old_content, this.new_content);
  }

}

//TODO: I had trouble thinking about how to incorporate SaveFile as normal action since it
// has this side effect of saving a file, which is doesn't make sense to "undo",
// so I don't know what is the appropriate reverse Action in that case.

/// This doesn't actually save the file (that's a side effect). It alerts the model
/// that the file was saved so "model changed since last save" should be false.
class AlertFileSavedAction implements Action {
  bool changed_since_last_save = false;

  @override
  Model apply(Model model) {
    model.changed_since_last_save = changed_since_last_save;
    app.controller.notifier_model_changed_since_save.add(changed_since_last_save);
    return model;
  }

  @override
  Action reverse() {
    var action = AlertFileSavedAction();
    action.changed_since_last_save = true;
    return action;
  }
}

//////////////////////////////////////////////////////////////////////////////
/// Change the DNA sequence assigned to a Strand.
//TODO: make this more specific just to DNA sequence changing
enum StrandEventType { assign_dna_sequence, remove_dna_sequence }

class SubstrandAction implements Action {
  final StrandEventType type;
  final Strand strand;
  final StreamController<Strand> strand_change_notifier;

  SubstrandAction(this.type, this.strand, this.strand_change_notifier);

  @override
  Model apply(Model model) {
    throw UnimplementedError();
  }

  @override
  Action reverse() {
    throw UnimplementedError();
  }
}
