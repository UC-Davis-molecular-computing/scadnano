import 'dart:html';

import 'package:color/color.dart';
import 'package:over_react/over_react.dart';
import 'package:built_collection/built_collection.dart';
import 'package:react/react.dart' as react;
import 'package:scadnano/src/state/context_menu.dart';
import 'package:scadnano/src/state/dialog.dart';
import 'package:scadnano/src/state/dna_end.dart';
import 'package:scadnano/src/state/edit_mode.dart';
import 'package:scadnano/src/state/helix.dart';

import 'package:scadnano/src/state/select_mode_state.dart';
import 'package:scadnano/src/state/selectable.dart';
import '../app.dart';
import '../state/strand.dart';
import '../state/bound_substrand.dart';
import 'design_main_strand_deletion.dart';
import 'design_main_strand_insertion.dart';
import 'design_main_strand_paths.dart';
import '../util.dart' as util;
import '../constants.dart' as constants;
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
  bool currently_moving;
  bool origami_type_is_selectable;
  bool assign_complement_to_bound_strands_default;
  bool warn_on_change_strand_dna_assign_default;
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
//      ..onContextMenu = strand_content_menu
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
        ..strand_tooltip = tooltip_text(props.strand)
        ..origami_type_is_selectable = props.origami_type_is_selectable
        ..drawing_potential_crossover = props.drawing_potential_crossover
        ..moving_dna_ends = props.moving_dna_ends)(),
      _insertions(strand, side_selected_helix_idxs, strand.color),
      _deletions(strand, side_selected_helix_idxs),
    ]);
  }

  // needed for capturing right-click events with React:
  // https://medium.com/@ericclemmons/react-event-preventdefault-78c28c950e46
  @override
  componentDidMount() {
    var element = querySelector('#${props.strand.id()}');
    element.addEventListener('contextmenu', on_context_menu);
  }

  @override
  componentWillUnmount() {
    var element = querySelector('#${props.strand.id()}');
    element.removeEventListener('contextmenu', on_context_menu);
  }

  on_context_menu(Event ev) {
    MouseEvent event = ev;
    if (!event.shiftKey) {
      event.preventDefault();
      app.dispatch(actions.ContextMenuShow(
          context_menu: ContextMenu(items: context_menu_strand(props.strand).build(), position: event.page)));
    }
  }

  handle_click_down(react.SyntheticPointerEvent event_syn) {
    if (event_syn.nativeEvent.button == constants.LEFT_CLICK_BUTTON) {
      // select/deselect
      MouseEvent event = event_syn.nativeEvent;
//      if (select_mode && props.selectable && !props.currently_moving) {
      if (select_mode && props.selectable) {
        props.strand.handle_selection_mouse_down(event);
      }

      // set up drag detection for moving DNA ends
//      if (select_mode && props.selectable && !props.currently_moving) {
      if (select_mode && props.selectable) {
        var address = util.get_closest_address(event, props.helices);
        app.dispatch(actions.StrandsMoveStartSelectedStrands(address: address, copy: false));
      }
    }
  }

  handle_click_up(react.SyntheticPointerEvent event_syn) {
    if (event_syn.nativeEvent.button == constants.LEFT_CLICK_BUTTON) {
      //XXX: This is tricky. If we condition on !props.currently_moving, then this achieves something we
      // want, which is that if we are moving a group of strands, and we are in a disallowed position where
      // the pointer itself (so also some strands) are positioned directly over a visible part of a strand,
      // then it would otherwise become selected on mouse up, when really we just want to end the move.
      // But it also achieves something we don't want.
      // See also commented out checks in handle_click_down.
//      if (select_mode && props.selectable && !props.currently_moving) {
      if (select_mode && props.selectable) {
        props.strand.handle_selection_mouse_up(event_syn.nativeEvent);
      }
    }
  }

  assign_dna() => app.disable_keyboard_shortcuts_while(() => ask_for_assign_dna_sequence(
      props.strand, props.assign_complement_to_bound_strands_default, props.warn_on_change_strand_dna_assign_default));

  remove_dna() => app.disable_keyboard_shortcuts_while(() => ask_for_remove_dna_sequence(props.strand));

  set_color() => app.disable_keyboard_shortcuts_while(() => ask_for_color(props.strand));

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

  List<ContextMenuItem> context_menu_strand(Strand strand) => [
        ContextMenuItem(
          title: 'assign DNA',
          on_click: assign_dna,
        ),
        if (strand.dna_sequence != null)
          ContextMenuItem(
            title: 'remove DNA',
            on_click: remove_dna,
          ),
        ContextMenuItem(
          title: strand.is_scaffold ? 'set as non-scaffold' : 'set as scaffold',
          on_click: () => app.dispatch(actions.ScaffoldSet(strand: strand, is_scaffold: !strand.is_scaffold)),
        ),
        ContextMenuItem(
          title: 'set color',
          on_click: set_color,
        ),
      ];
}

String tooltip_text(Strand strand) => "Strand:\n"
    "    length=${strand.dna_length()}\n"
    "    5' end=${tooltip_end(strand.first_bound_substrand(), strand.dnaend_5p)}\n"
    "    3' end=${tooltip_end(strand.last_bound_substrand(), strand.dnaend_3p)}";

String tooltip_end(BoundSubstrand ss, DNAEnd end) => "(helix=${ss.helix}, offset=${end.offset_inclusive})";

bool should_draw_bound_ss(BoundSubstrand ss, BuiltSet<int> side_selected_helix_idxs) =>
    side_selected_helix_idxs.isEmpty || side_selected_helix_idxs.contains(ss.helix);

class DNAAssignOptions {
  String dna_sequence; // sequence to assign to this strand
  bool assign_complements; // assign complementary sequences to strands bound to this one

  DNAAssignOptions({this.dna_sequence = null, this.assign_complements = true});
}

class DNARemoveOptions {
  bool remove_complements; // remove from this strand and all strands bound to it
  bool remove_all; // remove from all strands in design

  DNARemoveOptions({this.remove_complements = false, this.remove_all = false});
}

Future<void> ask_for_assign_dna_sequence(
    Strand strand, bool assign_complement_to_bound_strands_default, bool warn_on_change_default) async {
  var dialog = Dialog(title: 'assign DNA sequence', items: [
    DialogText(label: 'sequence', value: strand.dna_sequence ?? ''),
//    DialogTextArea(label: 'sequence', value: existing_dna ?? ''),
    DialogCheckbox(
        label: 'assign complement to bound strands', value: assign_complement_to_bound_strands_default),
    DialogCheckbox(
        label: 'warn if assigning different sequence to bound strand', value: warn_on_change_default),
  ]);
  List<DialogItem> results = await util.dialog(dialog);
  if (results == null) return;

  String dna_sequence = (results[0] as DialogText).value;
  bool assign_complements = (results[1] as DialogCheckbox).value;
  bool warn_on_change = (results[2] as DialogCheckbox).value;

  try {
    util.check_dna_sequence(dna_sequence);
  } on FormatException catch (e) {
    window.alert(e.message);
    return;
  }

  app.dispatch(actions.AssignDNA(
      strand: strand,
      dna_sequence: dna_sequence,
      assign_complements: assign_complements,
      warn_on_change: warn_on_change));
}

Future<void> ask_for_remove_dna_sequence(Strand strand) async {
  var dialog = Dialog(title: 'remove DNA sequence', items: [
    DialogCheckbox(label: 'remove from bound strands', value: true),
    DialogCheckbox(label: 'remove from all strands', value: false),
  ]);
  List<DialogItem> results = await util.dialog(dialog);
  if (results == null) return;

  bool remove_complements = (results[0] as DialogCheckbox).value;
  bool remove_all = (results[1] as DialogCheckbox).value;

  app.dispatch(
      actions.RemoveDNA(strand: strand, remove_complements: remove_complements, remove_all: remove_all));
}

Future<void> ask_for_color(Strand strand) async {
  var dialog = Dialog(title: 'set color', items: [
    DialogText(
      label: 'color',
//      label: 'color (hex rgb, e.g., "#00ff00")',
      value: strand.color.toHexColor().toCssString(),
    ),
  ]);
  List<DialogItem> results = await util.dialog(dialog);
  if (results == null) return;

  String color_hex = (results[0] as DialogText).value;
  app.dispatch(actions.StrandColorSet(strand: strand, color: Color.hex(color_hex)));
}
