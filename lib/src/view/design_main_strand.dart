import 'dart:html';

import 'package:color/color.dart';
import 'package:over_react/over_react.dart';
import 'package:built_collection/built_collection.dart';
import 'package:react/react.dart' as react;
import 'package:scadnano/src/state/edit_mode.dart';
import 'package:scadnano/src/state/helix.dart';

import 'package:scadnano/src/state/select_mode_state.dart';
import 'package:scadnano/src/state/selectable.dart';
import 'package:smart_dialogs/smart_dialogs.dart';
import '../app.dart';
import '../state/strand.dart';
import '../state/bound_substrand.dart';
import 'design_main_strand_deletion.dart';
import 'design_main_strand_insertion.dart';
import 'design_main_strand_paths.dart';
import '../util.dart' as util;
import '../actions/actions.dart' as actions;
import 'edit_mode_queryable.dart';
import 'pure_component.dart';

part 'design_main_strand.over_react.g.dart';

//UiFactory<_$DesignMainStrandProps> ConnectedDesignMainStrand = connect<AppState, DesignMainStrandProps>(
//  mapStateToPropsWithOwnProps: (state, props) {
//    bool selected = state.ui_state.selectables_store.selected(props.strand);
//    bool selectable = state.ui_state.select_mode_state.modes.contains(SelectModeChoice.strand);
//    return DesignMainStrand()
//      ..selected = selected
//      ..selectable = selectable
//      ..select_mode = state.ui_state.edit_modes.contains(EditModeChoice.select)
//      ..side_selected_helix_idxs = state.ui_state.side_selected_helix_idxs
//      ..assign_dna_mode_enabled = state.ui_state.edit_modes.contains(EditModeChoice.assign_dna);
//  },
//)(DesignMainStrand);

@Factory()
UiFactory<DesignMainStrandProps> DesignMainStrand = _$DesignMainStrand;

@Props()
class _$DesignMainStrandProps extends EditModePropsAbstract {
  Strand strand;
  BuiltSet<int> side_selected_helix_idxs;

  bool selected;
  bool selectable;
  BuiltList<Helix> helices;
  SelectablesStore selectables_store;
  SelectModeState select_mode_state;
  BuiltSet<EditModeChoice> edit_modes;
  bool drawing_potential_crossover;
  bool moving_dna_ends;
  bool origami_type_is_selectable;
}

@Component2()
class DesignMainStrandComponent extends UiComponent2<DesignMainStrandProps>
    with PureComponent, EditModeQueryable<DesignMainStrandProps> {
  @override
  render() {
    Strand strand = props.strand;
    BuiltSet<int> side_selected_helix_idxs = props.side_selected_helix_idxs;
    bool selected = props.selected;
    bool selectable = props.selectable;

    if (strand.substrands.length == 0) {
      return null;
    }

    var classname = 'strand';
    if (selectable) {
      classname += ' selectable';
    }
    if (selectable && selected) {
      classname += ' selected';
    }

    return (Dom.g()
      ..id = strand.id()
      ..onPointerDown = handle_click_down
      ..onPointerUp = handle_click_up
      ..className = classname)([
//        (ConnectedDesignMainStrandPaths()
      (DesignMainStrandPaths()
        ..strand = strand
        ..key = 'strand-paths'
        ..helices = props.helices
        ..side_selected_helix_idxs = props.side_selected_helix_idxs
        ..selectables_store = props.selectables_store
        ..select_mode_state = props.select_mode_state
        ..edit_modes = props.edit_modes
        ..origami_type_is_selectable = props.origami_type_is_selectable
        ..drawing_potential_crossover = props.drawing_potential_crossover
        ..moving_dna_ends = props.moving_dna_ends)(),
      _insertions(strand, side_selected_helix_idxs, strand.color),
      _deletions(strand, side_selected_helix_idxs),
    ]);
  }

  handle_click_down(react.SyntheticPointerEvent event_syn) {
    MouseEvent event = event_syn.nativeEvent;
    if (select_mode && props.selectable) {
      props.strand.handle_selection_mouse_down(event);
    }

    // set up drag detection for moving DNA ends
    if (select_mode && props.selectable) {
      Helix helix = util.get_helix(event, props.helices);
      var offset_forward = util.get_offset_forward(event, helix);
      int offset = offset_forward.offset;
      app.dispatch(actions.StrandsMoveStart(offset: offset, helix: helix, copy: false));
    }

    if (assign_dna_mode) {
      assign_dna();
    }
  }

  handle_click_up(react.SyntheticPointerEvent event) {
    if (select_mode && props.selectable) {
      props.strand.handle_selection_mouse_up(event.nativeEvent);
    }
  }

  assign_dna() async {
    String dna_sequence = await app.disable_keyboard_shortcuts_while(ask_for_dna_sequence);
    if (dna_sequence != null) {
      app.dispatch(actions.AssignDNA(strand: props.strand, dna_sequence: dna_sequence));
    }
  }

  ReactElement _insertions(Strand strand, BuiltSet<int> side_selected_helix_idxs, Color color) {
    List<ReactElement> paths = [];
    for (BoundSubstrand substrand in strand.bound_substrands()) {
      Helix helix = props.helices[substrand.helix];
      if (should_draw_bound_ss(substrand, side_selected_helix_idxs)) {
        for (var insertion in substrand.insertions) {
          String id = util.id_insertion(substrand, insertion.offset);
          paths.add((DesignMainStrandInsertion()
            ..insertion = insertion
            ..substrand = substrand
            ..helix = helix
            ..color = color
            ..edit_modes = props.edit_modes
            ..id = id
            ..key = id)());
        }
      }
    }
    return (Dom.g()
      ..key = 'insertions'
      ..className = 'insertions')(paths);
  }

  ReactElement _deletions(Strand strand, BuiltSet<int> side_selected_helix_idxs) {
    List<ReactElement> deletions = [];
    for (BoundSubstrand substrand in strand.bound_substrands()) {
      Helix helix = props.helices[substrand.helix];
      if (should_draw_bound_ss(substrand, side_selected_helix_idxs)) {
        for (var deletion in substrand.deletions) {
          String id = util.id_deletion(substrand, deletion);
          deletions.add((DesignMainStrandDeletion()
            ..substrand = substrand
            ..deletion = deletion
            ..edit_modes = props.edit_modes
            ..helix = helix
            ..key = id)());
        }
      }
    }
    return (Dom.g()
      ..key = 'deletions'
      ..className = 'deletions')(deletions);
  }
}

Future<String> ask_for_dna_sequence() async {
  // https://pub.dev/documentation/smart_dialogs/latest/smart_dialogs/Info/get.html
  String buttontype = DiaAttr.CHECKBOX;
  String htmlTitleText = 'assign DNA sequence';
  List<String> textLabels = ['sequence:'];
  List<List<String>> comboInfo = null;
  List<String> defaultInputTexts = [''];
  List<int> widths = [100];
  List<String> isChecked = null;
  bool alternateRowColor = false;
  List<String> buttonLabels = ['OK', 'Cancel'];

  UserInput result = await Info.get(buttontype, htmlTitleText, textLabels, comboInfo, defaultInputTexts,
      widths, isChecked, alternateRowColor, buttonLabels);

  if (result.buttonCode != 'DIA_ACT_OK') {
    return null;
  }

  String dna_sequence = result.getUserInput(0)[0];
  try {
    util.check_dna_sequence(dna_sequence);
  } on FormatException catch (e) {
    Info.show(e.message);
    return null;
  }

  return dna_sequence;
}

bool should_draw_bound_ss(BoundSubstrand ss, BuiltSet<int> side_selected_helix_idxs) =>
    side_selected_helix_idxs.isEmpty || side_selected_helix_idxs.contains(ss.helix);
