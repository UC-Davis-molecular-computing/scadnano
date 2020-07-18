import 'dart:html';

import 'package:color/color.dart';
import 'package:over_react/over_react.dart';
import 'package:built_collection/built_collection.dart';
import 'package:react/react.dart' as react;

import '../state/dialog.dart';
import '../state/dna_end.dart';
import '../state/helix.dart';
import '../state/selectable.dart';
import '../dna_sequence_constants.dart';
import '../state/context_menu.dart';
import '../state/crossover.dart';
import '../state/loopout.dart';
import '../app.dart';
import '../state/strand.dart';
import '../state/domain.dart';
import 'design_main_strand_deletion.dart';
import 'design_main_strand_insertion.dart';
import 'design_main_strand_modifications.dart';
import 'design_main_strand_paths.dart';
import '../util.dart' as util;
import '../constants.dart' as constants;
import '../actions/actions.dart' as actions;
import 'pure_component.dart';

part 'design_main_strand.over_react.g.dart';

@Factory()
UiFactory<DesignMainStrandProps> DesignMainStrand = _$DesignMainStrand;

@Props()
mixin DesignMainStrandPropsMixin on UiProps {
  Strand strand;

  BuiltSet<int> side_selected_helix_idxs;
  bool only_display_selected_helices;

  BuiltSet<DNAEnd> selected_ends_in_strand;
  BuiltSet<Crossover> selected_crossovers_in_strand;
  BuiltSet<Loopout> selected_loopouts_in_strand;

  bool selected;
  BuiltMap<int, Helix> helices;
  bool drawing_potential_crossover;
  bool show_modifications;
  bool moving_dna_ends;
  bool currently_moving;
  bool assign_complement_to_bound_strands_default;
  bool warn_on_change_strand_dna_assign_default;
  bool modification_display_connector;
  int modification_font_size;
  bool invert_y;
}

class DesignMainStrandProps = UiProps with DesignMainStrandPropsMixin;

@Component2()
class DesignMainStrandComponent extends UiComponent2<DesignMainStrandProps> with PureComponent {
  @override
  render() {
    BuiltSet<int> side_selected_helix_idxs = props.side_selected_helix_idxs;
    bool selected = props.selected;

    if (props.strand.substrands.length == 0) {
      return null;
    }

    var classname = constants.css_selector_strand;
    if (selected) {
      classname += ' ' + constants.css_selector_selected;
    }
    if (props.strand.is_scaffold) {
      classname += ' ' + constants.css_selector_scaffold;
    }

    return (Dom.g()
      ..id = props.strand.id()
      ..onPointerDown = handle_click_down
      ..onPointerUp = handle_click_up
//      ..onContextMenu = strand_content_menu // this is handled when clicking on domain
      ..className = classname)([
      (DesignMainStrandPaths()
        ..strand = props.strand
        ..key = 'strand-paths'
        ..helices = props.helices
        ..selected_ends_in_strand = props.selected_ends_in_strand
        ..selected_crossovers_in_strand = props.selected_crossovers_in_strand
        ..selected_loopouts_in_strand = props.selected_loopouts_in_strand
        ..context_menu_strand = context_menu_strand
        ..side_selected_helix_idxs = props.side_selected_helix_idxs
        ..strand_tooltip = tooltip_text(props.strand)
        ..drawing_potential_crossover = props.drawing_potential_crossover
        ..moving_dna_ends = props.moving_dna_ends
        ..only_display_selected_helices = props.only_display_selected_helices)(),
      _insertions(props.strand, side_selected_helix_idxs, props.strand.color),
      _deletions(props.strand, side_selected_helix_idxs),
      if (props.show_modifications)
        (DesignMainStrandModifications()
          ..strand = props.strand
          ..helices = props.helices
          ..side_selected_helix_idxs = props.side_selected_helix_idxs
          ..only_display_selected_helices = props.only_display_selected_helices
          ..font_size = props.modification_font_size
          ..display_connector = props.modification_display_connector
          ..key = 'modifications')()
    ]);
  }

  handle_click_down(react.SyntheticPointerEvent event_syn) {
    MouseEvent event = event_syn.nativeEvent;
    if (event.button == constants.LEFT_CLICK_BUTTON) {
      if (strand_selectable(props.strand)) {
        // select/deselect
        props.strand.handle_selection_mouse_down(event);
        // set up drag detection for moving DNA ends
        var address = util.get_closest_address(event, props.helices.values);
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
      if (strand_selectable(props.strand) && !props.currently_moving) {
        props.strand.handle_selection_mouse_up(event_syn.nativeEvent);
      }
    }
  }

  assign_dna() => app.disable_keyboard_shortcuts_while(() => ask_for_assign_dna_sequence(props.strand,
      props.assign_complement_to_bound_strands_default, props.warn_on_change_strand_dna_assign_default));

  ReactElement _insertions(Strand strand, BuiltSet<int> side_selected_helix_idxs, Color color) {
    List<ReactElement> paths = [];
    for (Domain domain in strand.domains()) {
      Helix helix = props.helices[domain.helix];
      if (should_draw_domain(domain, side_selected_helix_idxs, props.only_display_selected_helices)) {
        for (var insertion in domain.insertions) {
          String id = util.id_insertion(domain, insertion.offset);
          paths.add((DesignMainStrandInsertion()
            ..insertion = insertion
            ..substrand = domain
            ..helix = helix
            ..color = color
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
    for (Domain substrand in strand.domains()) {
      Helix helix = props.helices[substrand.helix];
      if (should_draw_domain(substrand, side_selected_helix_idxs, props.only_display_selected_helices)) {
        for (var deletion in substrand.deletions) {
          String id = util.id_deletion(substrand, deletion);
          deletions.add((DesignMainStrandDeletion()
            ..domain = substrand
            ..deletion = deletion
            ..helix = helix
            ..key = id)());
        }
      }
    }
    return (Dom.g()
      ..key = 'deletions'
      ..className = 'deletions')(deletions);
  }

  remove_dna() {
    app.disable_keyboard_shortcuts_while(() =>
        ask_for_remove_dna_sequence(props.strand, app.state.ui_state.selectables_store.selected_strands));
  }

  set_color() {
    app.disable_keyboard_shortcuts_while(
        () => ask_for_color(props.strand, app.state.ui_state.selectables_store.selected_strands));
  }

  mirror(bool horizontal, bool reverse_polarity) {
    var selected_strands = app.state.ui_state.selectables_store.selected_strands;
    List<Strand> strands;
    if (selected_strands.isEmpty || selected_strands.length == 1 && selected_strands.first == props.strand) {
      // set for single strand if nothing is selected, or exactly this strand is selected
      strands = [props.strand];
    } else {
      // if this strand is not selected, change it anyway along with all selected strands
      if (!selected_strands.contains(props.strand)) {
        strands = selected_strands.rebuild((b) => b.add(props.strand)).toList();
      } else {
        strands = selected_strands.toList();
      }
    }
    app.dispatch(actions.StrandsMirror(
        strands: strands.build(), horizontal: horizontal, reverse_polarity: reverse_polarity));
  }

  set_scaffold() {
    Strand strand = props.strand;
    var selected_strands = app.state.ui_state.selectables_store.selected_strands;
    actions.Action action = batch_if_multiple_selected(
        scaffold_set_strand_action_creator(!strand.is_scaffold), strand, selected_strands);
    app.dispatch(action);
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
          on_click: set_scaffold,
        ),
        ContextMenuItem(
          title: 'set color',
          on_click: set_color,
        ),
        ContextMenuItem(
          title: 'reflect horizontally',
          on_click: () => mirror(true, false),
          tooltip: '''\
replace strand(s) with horizontal mirror image, 
without reversing polarity "vertically"

For example,
before:
  strand's 5' end on helix 0
  strand's 3' end on helix 1
after:
  strand's 5' end on helix 0
  strand's 3' end on helix 1\
''',
        ),
        ContextMenuItem(
          title: 'reflect horizontally (reverse vertical polarity)',
          on_click: () => mirror(true, true),
          tooltip: '''\
replace strand(s) with horizontal mirror image, 
with polarity reversed "vertically"

For example,
before:
  strand's 5' end on helix 0
  strand's 3' end on helix 1
after:
  strand's 5' end on helix 1
  strand's 3' end on helix 0\
''',
        ),
        ContextMenuItem(
          title: 'reflect vertically',
          on_click: () => mirror(false, false),
          tooltip: '''\
replace strand(s) with vertical mirror image, 
without reversing polarity "vertically"

For example,
before:
  strand's 5' end is on a helix below that of the strand's 3' end
after:
  strand's 5' end is still on a helix below that of the strand's 3' end\
''',
        ),
        ContextMenuItem(
          title: 'reflect vertically (reverse vertical polarity)',
          on_click: () => mirror(false, true),
          tooltip: '''\
replace strand(s) with vertical mirror image, 
with polarity reversed "vertically"

For example,
before:
  strand's 5' end is on a helix below that of the strand's 3' end
after:
  strand's 5' end is now on a helix above that of the strand's 3' end\
''',
        ),
      ];
}

actions.UndoableAction batch_if_multiple_selected(
    ActionCreator action_creator, Strand strand, BuiltSet<Strand> selected_strands) {
  actions.Action action;
  if (selected_strands.isEmpty || selected_strands.length == 1 && selected_strands.first == strand) {
    // set for single strand if nothing is selected, or exactly this strand is selected
    action = action_creator(strand);
  } else {
    // if this strand is not selected, change it anyway along with all selected strands
    if (!selected_strands.contains(strand)) {
      selected_strands = selected_strands.rebuild((b) => b.add(strand));
    }
    action = actions.BatchAction([for (var strand in selected_strands) action_creator(strand)]);
  }
  return action;
}

typedef ActionCreator = actions.UndoableAction Function(Strand strand);

ActionCreator scaffold_set_strand_action_creator(bool is_scaffold) =>
    ((Strand strand) => actions.ScaffoldSet(strand: strand, is_scaffold: is_scaffold));

ActionCreator remove_dna_strand_action_creator(bool remove_complements, bool remove_all) =>
    ((Strand strand) =>
        actions.RemoveDNA(strand: strand, remove_complements: remove_complements, remove_all: remove_all));

ActionCreator color_set_strand_action_creator(String color_hex) =>
    ((Strand strand) => actions.StrandColorSet(strand: strand, color: Color.hex(color_hex)));

String tooltip_text(Strand strand) =>
    "Strand:\n" +
    "    length=${strand.dna_length()}\n" +
    "    5' end=${tooltip_end(strand.first_domain(), strand.dnaend_5p)}\n" +
    "    3' end=${tooltip_end(strand.last_domain(), strand.dnaend_3p)}\n" +
    (strand.label == null ? "" : "    label: ${strand.label.toString()}\n") +
    (strand.idt == null ? "" : "    idt info=\n${strand.idt.tooltip()}");

String tooltip_end(Domain ss, DNAEnd end) => "(helix=${ss.helix}, offset=${end.offset_inclusive})";

bool should_draw_domain(
        Domain ss, BuiltSet<int> side_selected_helix_idxs, bool only_display_selected_helices) =>
    !only_display_selected_helices || side_selected_helix_idxs.contains(ss.helix);

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
    DialogTextArea(label: 'sequence', value: strand.dna_sequence ?? '', rows: 10, cols: 80),
    DialogCheckbox(label: 'use predefined DNA sequence'),
    DialogRadio(label: 'predefined DNA sequence', options: DNASequencePredefined.names),
    DialogNumber(label: 'rotation of predefined DNA sequence', value: 5587),
    DialogCheckbox(
        label: 'assign complement to bound strands', value: assign_complement_to_bound_strands_default),
    DialogCheckbox(
        label: 'warn if assigning different sequence to bound strand', value: warn_on_change_default),
  ], disable_when_on: {
    0: [1]
  }, disable_when_off: {
    2: [1],
    3: [1],
  });
  List<DialogItem> results = await util.dialog(dialog);
  if (results == null) return;

  String dna_sequence;

  bool use_predefined_dna_sequence = (results[1] as DialogCheckbox).value;
  if (use_predefined_dna_sequence) {
    String predefined_sequence_name = (results[2] as DialogRadio).value;
    int rotation = (results[3] as DialogNumber).value;
    dna_sequence = DNASequencePredefined.dna_sequence_by_name(predefined_sequence_name, rotation);
  } else {
    dna_sequence = (results[0] as DialogTextArea).value;
  }

  bool assign_complements = (results[4] as DialogCheckbox).value;
  bool warn_on_change = (results[5] as DialogCheckbox).value;

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

Future<void> ask_for_remove_dna_sequence(Strand strand, BuiltSet<Strand> selected_strands) async {
  var dialog = Dialog(title: 'remove DNA sequence', items: [
    DialogCheckbox(label: 'remove from bound strands', value: true),
    DialogCheckbox(label: 'remove from all strands', value: false),
  ]);
  List<DialogItem> results = await util.dialog(dialog);
  if (results == null) return;

  bool remove_complements = (results[0] as DialogCheckbox).value;
  bool remove_all = (results[1] as DialogCheckbox).value;

  actions.Action action = batch_if_multiple_selected(
      remove_dna_strand_action_creator(remove_complements, remove_all), strand, selected_strands);
  app.dispatch(action);
}

Future<void> ask_for_color(Strand strand, BuiltSet<Strand> selected_strands) async {
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

  actions.Action action =
      batch_if_multiple_selected(color_set_strand_action_creator(color_hex), strand, selected_strands);
  app.dispatch(action);
}
