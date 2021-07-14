import 'dart:html';

import 'package:color/color.dart';
import 'package:over_react/over_react.dart';
import 'package:built_collection/built_collection.dart';
import 'package:react/react.dart' as react;
import 'package:scadnano/src/state/modification.dart';

import 'design_main_strand_and_domain_names.dart';
import 'transform_by_helix_group.dart';
import '../state/address.dart';
import '../state/geometry.dart';
import '../state/group.dart';
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

  BuiltSet<int> side_selected_helix_idxs; // null if only_display_selected_helices is false
  bool only_display_selected_helices;

  BuiltSet<DNAEnd> selected_ends_in_strand;
  BuiltSet<Crossover> selected_crossovers_in_strand;
  BuiltSet<Loopout> selected_loopouts_in_strand;
  BuiltSet<Domain> selected_domains_in_strand;
  BuiltSet<SelectableDeletion> selected_deletions_in_strand;
  BuiltSet<SelectableInsertion> selected_insertions_in_strand;
  BuiltSet<SelectableModification> selected_modifications_in_strand;

  BuiltMap<int, Helix> helices;
  BuiltMap<String, HelixGroup> groups;
  Geometry geometry;

  bool selected;
  bool drawing_potential_crossover;
  bool moving_dna_ends;
  bool assign_complement_to_bound_strands_default;
  bool warn_on_change_strand_dna_assign_default;
  bool modification_display_connector;
  bool show_dna;
  bool show_modifications;
  bool show_domain_names;
  bool show_strand_names;
  num domain_name_font_size;
  num strand_name_font_size;
  num modification_font_size;
  bool invert_y;
}

class DesignMainStrandProps = UiProps with DesignMainStrandPropsMixin, TransformByHelixGroupPropsMixin;

@Component2()
class DesignMainStrandComponent extends UiComponent2<DesignMainStrandProps>
    with PureComponent, TransformByHelixGroup<DesignMainStrandProps> {
  @override
  render() {
    if (props.strand.substrands.length == 0) {
      return null;
    }

    var classname = constants.css_selector_strand;
    if (props.selected) {
      classname += ' ' + constants.css_selector_selected;
    }
    if (props.strand.is_scaffold) {
      classname += ' ' + constants.css_selector_scaffold;
    }

    return (Dom.g()
      ..id = props.strand.id
      ..onPointerDown = handle_click_down
      ..onPointerUp = handle_click_up
//      ..onContextMenu = strand_content_menu // this is handled when clicking on domain
      ..className = classname)([
      (DesignMainStrandPaths()
        ..strand = props.strand
        ..key = 'strand-paths'
        ..show_domain_names = props.show_domain_names
        ..helices = props.helices
        ..groups = props.groups
        ..selected_ends_in_strand = props.selected_ends_in_strand
        ..selected_crossovers_in_strand = props.selected_crossovers_in_strand
        ..selected_loopouts_in_strand = props.selected_loopouts_in_strand
        ..selected_domains_in_strand = props.selected_domains_in_strand
        ..context_menu_strand = context_menu_strand
        ..side_selected_helix_idxs = props.side_selected_helix_idxs
        ..strand_tooltip = tooltip_text(props.strand)
        ..drawing_potential_crossover = props.drawing_potential_crossover
        ..moving_dna_ends = props.moving_dna_ends
        ..geometry = props.geometry
        ..only_display_selected_helices = props.only_display_selected_helices)(),
      _insertions(),
      _deletions(),
      if (props.show_domain_names || props.show_strand_names)
        (DesignMainStrandAndDomainNames() // shows both domain and strand names
          ..strand = props.strand
          ..helices = props.helices
          ..groups = props.groups
          ..geometry = props.geometry
          ..show_dna = props.show_dna
          ..side_selected_helix_idxs = props.side_selected_helix_idxs
          ..only_display_selected_helices = props.only_display_selected_helices
          ..show_domain_names = props.show_domain_names
          ..show_strand_names = props.show_strand_names
          ..domain_name_font_size = props.domain_name_font_size
          ..strand_name_font_size = props.strand_name_font_size
          ..key = 'domain-names')(),
      if (props.show_modifications)
        (DesignMainStrandModifications()
          ..strand = props.strand
          ..helices = props.helices
          ..groups = props.groups
          ..geometry = props.geometry
          ..side_selected_helix_idxs = props.side_selected_helix_idxs
          ..only_display_selected_helices = props.only_display_selected_helices
          ..selected_modifications_in_strand = props.selected_modifications_in_strand
          ..font_size = props.modification_font_size
          ..display_connector = props.modification_display_connector
          ..key = 'modifications')(),
    ]);
  }

  handle_click_down(react.SyntheticPointerEvent event_syn) {
    MouseEvent event = event_syn.nativeEvent;
    if (event.button == constants.LEFT_CLICK_BUTTON) {
      if (strand_selectable(props.strand)) {
        // select/deselect
        props.strand.handle_selection_mouse_down(event);
        // set up drag detection for moving DNA ends
        var address = util.find_closest_address(event, props.helices.values, props.groups, props.geometry);
        HelixGroup group = app.state.design.group_of_strand(props.strand);
        var helices_view_order_inverse = group.helices_view_order_inverse;
        app.dispatch(actions.StrandsMoveStartSelectedStrands(
            address: address, copy: false, original_helices_view_order_inverse: helices_view_order_inverse));
      }
    }
  }

  handle_click_up(react.SyntheticPointerEvent event_syn) {
    if (event_syn.nativeEvent.button == constants.LEFT_CLICK_BUTTON) {
      //XXX: This is tricky. If we condition on !props.currently_moving, then this achieves something we
      // want, which is that if we are moving a group of strands, and we are in a disallowed position where
      // the pointer itself (so also some strands) are positioned directly over a visible part of a strand,
      // then it would otherwise become selected on mouse up, when really we just want to end the move.
      bool currently_moving = app.state.ui_state.strands_move != null ||
          app.state.ui_state.domains_move != null ||
          app.state.ui_state.dna_ends_are_moving;
      if (strand_selectable(props.strand) && !currently_moving) {
        props.strand.handle_selection_mouse_up(event_syn.nativeEvent);
      }
    }
  }

  assign_dna() => app.disable_keyboard_shortcuts_while(() => ask_for_assign_dna_sequence(props.strand,
      props.assign_complement_to_bound_strands_default, props.warn_on_change_strand_dna_assign_default));

  assign_dna_complement_from_bound_strands() {
    List<Strand> strands_selected = app.state.ui_state.selectables_store.selected_strands.toList();

    if (!strands_selected.contains(props.strand)) {
      strands_selected.add(props.strand);
    }

    var action = actions.AssignDNAComplementFromBoundStrands(strands_selected);
    app.dispatch(action);
  }

  assign_domain_name_complement_from_bound_strands() {
    List<Strand> strands_selected = app.state.ui_state.selectables_store.selected_strands.toList();

    if (!strands_selected.contains(props.strand)) {
      strands_selected.add(props.strand);
    }

    var action = actions.AssignDomainNameComplementFromBoundStrands(strands_selected);
    app.dispatch(action);
  }

  add_modification(Domain domain, Address address, bool is_5p) =>
      app.disable_keyboard_shortcuts_while(() => ask_for_add_modification(domain, address, is_5p));

  set_strand_name() => app.disable_keyboard_shortcuts_while(ask_for_strand_name);

  set_domain_name(Domain domain) => app.disable_keyboard_shortcuts_while(() => ask_for_domain_name(domain));

  ReactElement _insertions() {
    List<ReactElement> paths = [];
    for (Domain domain in props.strand.domains) {
      Helix helix = props.helices[domain.helix];
      if (should_draw_domain(domain, props.side_selected_helix_idxs, props.only_display_selected_helices)) {
        for (var selectable_insertion in domain.selectable_insertions) {
          paths.add((DesignMainStrandInsertion()
            ..selectable_insertion = selectable_insertion
            ..selected = props.selected_insertions_in_strand.contains(selectable_insertion)
            ..helix = helix
            ..color = props.strand.color
            ..transform = transform_of_helix(domain.helix)
            ..key = util.id_insertion(domain, selectable_insertion.insertion.offset))());
        }
      }
    }
    return paths.isEmpty
        ? null
        : (Dom.g()
          ..key = 'insertions'
          ..className = 'insertions')(paths);
  }

  /// Assuming props contain helices mapping idx to Helix, groups mapping group names to groups,
  /// returns CSS transform String that can be passed to SVG components that need to be transformed
  /// specific to a HelixGroup.
  String compute_helix_transform(int helix_idx) {
    Helix helix = props.helices[helix_idx];
    var group = props.groups[helix.group];
    var transform_str = group.transform_str(props.geometry);
    return transform_str;
  }

  ReactElement _deletions() {
    List<ReactElement> paths = [];
    for (Domain domain in props.strand.domains) {
      Helix helix = props.helices[domain.helix];
      if (should_draw_domain(domain, props.side_selected_helix_idxs, props.only_display_selected_helices)) {
        for (var selectable_deletion in domain.selectable_deletions) {
          String id = util.id_deletion(domain, selectable_deletion.offset);
          paths.add((DesignMainStrandDeletion()
            ..selectable_deletion = selectable_deletion
            ..helix = helix
            ..selected = props.selected_deletions_in_strand.contains(selectable_deletion)
            ..transform = transform_of_helix(domain.helix)
            ..key = id)());
        }
      }
    }
    return paths.isEmpty
        ? null
        : (Dom.g()
          ..key = 'deletions'
          ..className = 'deletions')(paths);
  }

  remove_dna() {
    app.disable_keyboard_shortcuts_while(() =>
        ask_for_remove_dna_sequence(props.strand, app.state.ui_state.selectables_store.selected_strands));
  }

  set_color() {
    app.disable_keyboard_shortcuts_while(
        () => ask_for_color(props.strand, app.state.ui_state.selectables_store.selected_strands));
  }

  reflect(bool horizontal, bool reverse_polarity) {
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
    app.dispatch(actions.StrandsReflect(
        strands: strands.build(), horizontal: horizontal, reverse_polarity: reverse_polarity));
  }

  set_scaffold() {
    Strand strand = props.strand;
    var selected_strands = app.state.ui_state.selectables_store.selected_strands;
    actions.Action action = batch_if_multiple_selected(
        scaffold_set_strand_action_creator(!strand.is_scaffold), strand, selected_strands);
    app.dispatch(action);
  }

  List<ContextMenuItem> context_menu_strand(Strand strand, {Domain domain, Address address, bool is_5p}) => [
        ContextMenuItem(
          title: 'assign DNA',
          tooltip: '''\
Assign a specific DNA sequence to this strand (and optionally assign complementary
sequence to strands bound to it).
''',
          on_click: assign_dna,
        ),
        ContextMenuItem(
          title: 'assign DNA complement from bound strands',
          tooltip: '''\
If other strands bound to this strand (or the selected strands) have DNA already 
assigned, assign the complementary DNA sequence to this strand.
''',
          on_click: assign_dna_complement_from_bound_strands,
        ),
        ContextMenuItem(
          title: 'assign domain name complement from bound strands',
          tooltip: '''\
If other strands bound to this strand (or the selected strands) have domain names already 
assigned, assign the complementary domain names sequence to this strand.
''',
          on_click: assign_domain_name_complement_from_bound_strands,
        ),
        if (strand.dna_sequence != null)
          ContextMenuItem(
            title: 'remove DNA',
            on_click: remove_dna,
          ),
        ContextMenuItem(
          title: 'add modification',
          on_click: () => add_modification(domain, address, is_5p),
        ),
        ContextMenuItem(
          title: strand.is_scaffold ? 'set as non-scaffold' : 'set as scaffold',
          on_click: set_scaffold,
        ),
        ContextMenuItem(
            title: 'set color',
            on_click: () => app.dispatch(actions.StrandColorPickerShow(strand: props.strand))),
        ContextMenuItem(
          title: 'set strand name',
          on_click: set_strand_name,
        ),
        if (props.strand.name != null)
          ContextMenuItem(
              title: 'remove strand name',
              on_click: () => app.dispatch(actions.StrandNameSet(name: null, strand: props.strand))),
        ContextMenuItem(
          title: 'set domain name',
          on_click: () => set_domain_name(domain),
        ),
        if (domain?.name != null)
          ContextMenuItem(
              title: 'remove domain name',
              on_click: () => app.dispatch(actions.SubstrandNameSet(name: null, substrand: domain))),
        ContextMenuItem(
          title: 'reflect horizontally',
          on_click: () => reflect(true, false),
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
          on_click: () => reflect(true, true),
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
          on_click: () => reflect(false, false),
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
          on_click: () => reflect(false, true),
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

  Future<void> ask_for_add_modification(
      [Domain domain = null, Address address = null, bool is_5p = null]) async {
    assert((is_5p == null && domain != null && address != null) ||
        (is_5p != null && domain == null && address == null));
    bool is_end = is_5p != null;
    int strand_dna_idx = null;
    int selected_index = 2;
    if (!is_end) {
      strand_dna_idx = clicked_strand_dna_idx(domain, address, props.strand);
    } else {
      if (is_5p) {
        selected_index = 1;
      } else {
        selected_index = 0;
      }
    }

    int modification_type_idx = 0;
    int display_text_idx = 1;
    int idt_text_idx = 2;
    int index_of_dna_base_idx = 3;
    // int id_idx = 4;
    var items = List<DialogItem>(4);
    items[modification_type_idx] = DialogRadio(
        label: 'modification type', options: {"3'", "5'", "internal"}, selected_idx: selected_index);

    String initial_display_text = "";
    String initial_idt_text = "";
    // String initial_id = "";

    // if there is a last mod of this type, it auto-populates the dialog inputs
    Modification last_mod;
    if (selected_index == 0) {
      // 3' mod
      last_mod = app.state.ui_state.last_mod_3p;
    } else if (selected_index == 1) {
      // 5' mod
      last_mod = app.state.ui_state.last_mod_5p;
    } else if (selected_index == 2) {
      // internal mod
      last_mod = app.state.ui_state.last_mod_int;
    } else {
      throw AssertionError('should be unreachable');
    }
    if (last_mod != null) {
      initial_display_text = last_mod.display_text;
      initial_idt_text = last_mod.idt_text;
      // initial_id = last_mod.id;
    }

    items[display_text_idx] = DialogText(label: 'display text', value: initial_display_text);
    items[idt_text_idx] = DialogText(label: 'idt text', value: initial_idt_text);
    // items[id_idx] = DialogText(label: 'id', value: initial_id);

    items[index_of_dna_base_idx] =
        DialogInteger(label: 'index of DNA base', value: is_end ? 0 : strand_dna_idx);

    // don't allow to modify index of DNA base when 3' or 5' is selected
    var dialog = Dialog(title: 'add modification', items: items, disable_when_any_radio_button_selected: {
      index_of_dna_base_idx: {
        modification_type_idx: ["3'", "5'"]
      },
    });

    List<DialogItem> results = await util.dialog(dialog);
    if (results == null) return;
    String modification_type = (results[modification_type_idx] as DialogRadio).value;
    String display_text = (results[display_text_idx] as DialogText).value;
    // String id = (results[id_idx] as DialogText).value;
    String idt_text = (results[idt_text_idx] as DialogText).value;
    int index_of_dna_base = (results[index_of_dna_base_idx] as DialogInteger).value;

    Modification mod;
    if (modification_type == "3'") {
      mod = Modification3Prime(
          //id: id,
          display_text: display_text,
          idt_text: idt_text);
    } else if (modification_type == "5'") {
      mod = Modification5Prime(
          //id: id,
          display_text: display_text,
          idt_text: idt_text);
    } else {
      mod = ModificationInternal(
        // id: id,
        display_text: display_text,
        idt_text: idt_text,
      );
    }

    // if modification type is 5' or 3' and many such ends are selected, add modifications to all of them
    actions.UndoableAction action;
    if (mod is ModificationInternal) {
      action =
          actions.ModificationAdd(strand: props.strand, modification: mod, strand_dna_idx: index_of_dna_base);
    } else {
      List<DNAEnd> ends_selected = app.state.ui_state.selectables_store.selected_dna_ends.toList();

      if (is_5p && !ends_selected.contains(props.strand.dnaend_5p)) {
        ends_selected.add(props.strand.dnaend_5p);
      } else if (!is_5p && !ends_selected.contains(props.strand.dnaend_3p)) {
        ends_selected.add(props.strand.dnaend_3p);
      }

      if (ends_selected.length == 1) {
        action = actions.ModificationAdd(
            strand: props.strand, modification: mod, strand_dna_idx: index_of_dna_base);
      } else if (ends_selected.length > 1) {
        // safe to batch this action since it's only for 5' or 3', so each strand will only be modified once
        List<actions.ModificationAdd> all_actions = [];
        for (var end_selected in ends_selected) {
          var strand_of_end_selected = app.state.design.end_to_strand(end_selected);
          var new_action = actions.ModificationAdd(
              strand: strand_of_end_selected, modification: mod, strand_dna_idx: null);
          all_actions.add(new_action);
        }
        action = actions.BatchAction(all_actions);
      } else {
        print('WARNING: selectable_mods should have at least one element in it by this line');
        return;
      }
    }

    app.dispatch(action);
  }

  Future<void> ask_for_strand_name() async {
    int name_idx = 0;
    var items = List<DialogItem>(1);
    items[name_idx] = DialogText(label: 'name', value: props.strand.name ?? '');
    var dialog = Dialog(title: 'set strand name', items: items);

    List<DialogItem> results = await util.dialog(dialog);
    if (results == null) return;

    String name = (results[name_idx] as DialogText).value;
    actions.UndoableAction action = actions.StrandNameSet(name: name, strand: props.strand);
    app.dispatch(action);
  }

  Future<void> ask_for_domain_name(Domain domain) async {
    int name_idx = 0;
    var items = List<DialogItem>(1);
    items[name_idx] = DialogText(label: 'name', value: domain.name ?? '');
    var dialog = Dialog(title: 'set domain name', items: items);

    List<DialogItem> results = await util.dialog(dialog);
    if (results == null) return;

    String name = (results[name_idx] as DialogText).value;
    actions.UndoableAction action = actions.SubstrandNameSet(name: name, substrand: domain);
    app.dispatch(action);
  }
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
    (strand.name == null ? "" : "    name=${strand.name}\n") +
    "    length=${strand.dna_length}\n" +
    (!strand.circular ? "" : "    circular\n") +
    "    5' end=${tooltip_end(strand.first_domain, strand.dnaend_5p)}\n" +
    "    3' end=${tooltip_end(strand.last_domain, strand.dnaend_3p)}\n" +
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

int clicked_strand_dna_idx(Domain domain, Address address, Strand strand) {
  int strand_dna_idx = 0;
  int domain_dna_idx = domain.substrand_offset_to_substrand_dna_idx(address.offset, address.forward);
  int index_of_domain_in_strand = strand.substrands.indexOf(domain);
  for (int i = 0; i < index_of_domain_in_strand; i++) {
    strand_dna_idx += strand.substrands[i].dna_length();
  }
  strand_dna_idx += domain_dna_idx;
  return strand_dna_idx;
}

Future<void> ask_for_assign_dna_sequence(
    Strand strand, bool assign_complement_to_bound_strands_default, bool warn_on_change_default) async {
  int idx_sequence = 0;
  int idx_use_predefined_dna_sequence = 1;
  int idx_predefine_sequence_link = 2;
  int idx_predefined_sequence_name = 3;
  int idx_rotation = 4;
  int idx_assign_complements = 5;
  int idx_warn_on_change = 6;

  List<DialogItem> items = [null, null, null, null, null, null, null];

  items[idx_sequence] =
      DialogTextArea(label: 'sequence', value: strand.dna_sequence ?? '', rows: 10, cols: 80);
  items[idx_use_predefined_dna_sequence] = DialogCheckbox(label: 'use predefined DNA sequence');
  items[idx_predefined_sequence_name] =
      DialogRadio(label: 'predefined DNA sequence', options: DNASequencePredefined.display_names);
  items[idx_rotation] = DialogInteger(label: 'rotation of predefined DNA sequence', value: 5587);
  items[idx_assign_complements] = DialogCheckbox(
      label: 'assign complement to bound strands', value: assign_complement_to_bound_strands_default);
  items[idx_warn_on_change] = DialogCheckbox(
      label: 'warn if assigning different sequence to bound strand', value: warn_on_change_default);
  items[idx_predefine_sequence_link] = DialogLink(
      label: 'Information about sequence variants',
      link: 'https://scadnano-python-package.readthedocs.io/en/latest/#scadnano.M13Variant');

  var dialog = Dialog(title: 'assign DNA sequence', items: items, disable_when_any_checkboxes_on: {
    idx_sequence: [idx_use_predefined_dna_sequence]
  }, disable_when_any_checkboxes_off: {
    idx_predefined_sequence_name: [idx_use_predefined_dna_sequence],
    idx_rotation: [idx_use_predefined_dna_sequence],
  });
  List<DialogItem> results = await util.dialog(dialog);
  if (results == null) return;

  String dna_sequence;

  bool use_predefined_dna_sequence = (results[idx_use_predefined_dna_sequence] as DialogCheckbox).value;
  if (use_predefined_dna_sequence) {
    String predefined_sequence_display_name = (results[idx_predefined_sequence_name] as DialogRadio).value;
    int rotation = (results[idx_rotation] as DialogInteger).value;
    dna_sequence =
        DNASequencePredefined.dna_sequence_by_name(predefined_sequence_display_name, true, rotation);
  } else {
    dna_sequence = (results[idx_sequence] as DialogTextArea).value;
  }

  bool assign_complements = (results[idx_assign_complements] as DialogCheckbox).value;
  bool warn_on_change = (results[idx_warn_on_change] as DialogCheckbox).value;

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
