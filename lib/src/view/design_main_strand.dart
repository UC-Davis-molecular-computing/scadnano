import 'dart:html';

import 'package:color/color.dart';
import 'package:over_react/over_react.dart';
import 'package:built_collection/built_collection.dart';
import 'package:react/react.dart' as react;
import 'package:scadnano/src/state/context_menu.dart';
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
        ..origami_type_is_selectable = props.origami_type_is_selectable
        ..drawing_potential_crossover = props.drawing_potential_crossover
        ..moving_dna_ends = props.moving_dna_ends)(),
      _insertions(strand, side_selected_helix_idxs, strand.color),
      _deletions(strand, side_selected_helix_idxs),
    ]);
  }

//  context_menu() {
//    return (Dom.foreignObject()
//      ..x = '0'
//      ..y = '0'
//      ..width = '100'
//      ..height = '100'
//      ..key = 'context_menu')();
//  }

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
      if (select_mode && props.selectable) {
        props.strand.handle_selection_mouse_down(event);
      }

      // set up drag detection for moving DNA ends
      if (select_mode && props.selectable) {
        var address = util.get_address(event, props.helices);
        app.dispatch(actions.StrandsMoveStart(address: address, copy: false));
      }

      if (assign_dna_mode) {
        props.strand.dna_sequence == null ? assign_dna() : remove_dna();
      }
    }
  }

  handle_click_up(react.SyntheticPointerEvent event_syn) {
    if (event_syn.nativeEvent.button == constants.LEFT_CLICK_BUTTON) {
      if (select_mode && props.selectable) {
        props.strand.handle_selection_mouse_up(event_syn.nativeEvent);
      }
    }
  }

  assign_dna() async {
    DNAAssignOptions options =
        await app.disable_keyboard_shortcuts_while(() => ask_for_dna_sequence(props.strand.dna_sequence));
    if (options == null) {
      return;
    }
    app.dispatch(actions.AssignDNA(
        strand: props.strand,
        dna_sequence: options.dna_sequence,
        assign_complements: options.assign_complements));
  }

  remove_dna() async {
    DNARemoveOptions options =
        await app.disable_keyboard_shortcuts_while(() => ask_for_remove_dna_sequence());
    if (options == null) {
      return;
    }
    app.dispatch(actions.RemoveDNA(
        strand: props.strand,
        remove_complements: options.remove_complements,
        remove_all: options.remove_all));
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

  List<ContextMenuItem> context_menu_strand(Strand strand) => [
        ContextMenuItem(
          title: strand.is_scaffold ? 'set as non-scaffold' : 'set as scaffold',
          on_click: () => app.dispatch(actions.ScaffoldSet(strand: strand, is_scaffold: !strand.is_scaffold)),
        ),
        ContextMenuItem(
          title: strand.dna_sequence == null ? 'assign DNA' : 'remove DNA',
          on_click: () {
            strand.dna_sequence == null ? assign_dna() : remove_dna();
          },
        ),
      ];
}

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

Future<DNAAssignOptions> ask_for_dna_sequence(String existing_dna) async {
  // https://pub.dev/documentation/smart_dialogs/latest/smart_dialogs/Info/get.html
  String buttontype = DiaAttr.CHECKBOX;
  String htmlTitleText = 'assign DNA sequence';
  List<String> textLabels = ['sequence:', 'assign complement to bound strands'];
  List<List<String>> comboInfo = null;
  List<String> defaultInputTexts = [existing_dna ?? '', null];
  List<int> widths = [100, 0];
  List<String> isChecked = [null, 'true'];
  bool alternateRowColor = false;
  List<String> buttonLabels = ['OK', 'Cancel'];
  UserInput result = await Info.get(buttontype, htmlTitleText, textLabels, comboInfo, defaultInputTexts,
      widths, isChecked, alternateRowColor, buttonLabels);
  if (result.buttonCode != 'DIA_ACT_OK') return null;

  String dna_sequence = result.getUserInput(0)[0];
  bool assign_to_complements = result.getCheckedState(1) == 'true';
  var options = DNAAssignOptions(
    dna_sequence: dna_sequence,
    assign_complements: assign_to_complements,
  );

  try {
    util.check_dna_sequence(dna_sequence);
  } on FormatException catch (e) {
    Info.show(e.message);
    return null;
  }
  return options;
}

Future<DNARemoveOptions> ask_for_remove_dna_sequence() async {
  // https://pub.dev/documentation/smart_dialogs/latest/smart_dialogs/Info/get.html
  String buttontype = DiaAttr.CHECKBOX;
  String htmlTitleText = 'remove DNA sequence';
  List<String> textLabels = ['remove from bound strands', 'remove from all strands'];
  List<List<String>> comboInfo = null;
  List<String> defaultInputTexts = [null, null];
  List<int> widths = [0, 0];
  List<String> isChecked = ['true', 'false'];
  bool alternateRowColor = false;
  List<String> buttonLabels = ['OK', 'Cancel'];
  UserInput result = await Info.get(buttontype, htmlTitleText, textLabels, comboInfo, defaultInputTexts,
      widths, isChecked, alternateRowColor, buttonLabels);
  if (result.buttonCode != 'DIA_ACT_OK') return null;

  bool remove_from_complements = result.getCheckedState(0) == 'true';
  bool remove_from_all = result.getCheckedState(1) == 'true';
  var options = DNARemoveOptions(
    remove_complements: remove_from_complements,
    remove_all: remove_from_all,
  );

  return options;
}
