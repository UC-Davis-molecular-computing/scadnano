import 'dart:html';

import 'package:over_react/over_react.dart';
import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/state/dna_end.dart';
import 'package:scadnano/src/state/modification_type.dart';
import 'package:scadnano/src/state/substrand.dart';

import '../state/domain.dart';
import '../state/extension.dart';
import '../state/context_menu.dart';
import '../state/dialog.dart';
import '../state/geometry.dart';
import '../state/selectable.dart';
import '../state/address.dart';
import '../state/modification.dart';
import '../app.dart';
import '../actions/actions.dart' as actions;
import '../util.dart' as util;
import '../state/strand.dart';
import '../state/helix.dart';
import '../constants.dart' as constants;
import 'design_main_strand.dart';

part 'design_main_strand_modification.over_react.g.dart';

UiFactory<DesignMainStrandModificationProps> DesignMainStrandModification = _$DesignMainStrandModification;

mixin DesignMainStrandModificationProps on UiProps {
  late SelectableModification selectable_modification;
  late Helix helix;
  Extension? ext; // optional; used if mod is on extension
  late String transform;
  late double font_size;
  late bool display_connector;
  late bool selected;
  late Geometry geometry;
  late double helix_svg_position_y;
  late bool retain_strand_color_on_selection;

  int? dna_idx_mod;
}

class DesignMainStrandModificationComponent extends UiComponent2<DesignMainStrandModificationProps> {
  Strand get strand => props.selectable_modification.strand;

  Modification get modification => props.selectable_modification.modification;

  Address get address => props.selectable_modification.address;

  @override
  render() {
    Point<double> pos;
    if (props.ext == null) {
      pos = props.helix.svg_base_pos(
        this.address.offset,
        this.address.forward,
        props.helix_svg_position_y,
        props.geometry,
      );
      // if internal modification that goes between bases, adjust x offset to be after the given base,
      // instead of on it
      if (this.modification is ModificationInternal) {
        var mod = (this.modification as ModificationInternal);
        if (!mod.attached_to_base) {
          var delta = props.geometry.base_width_svg / 2;
          pos = Point<double>(pos.x + delta, pos.y);
        }
      }
    } else {
      var ext = props.ext!;
      var adj_dom = ext.adjacent_domain;
      var adj_helix = props.helix;
      var adj_helix_svg_y = props.helix_svg_position_y;
      Point<double> extension_attached_end_svg = util.compute_extension_attached_end_svg(
        ext,
        adj_dom,
        adj_helix,
        adj_helix_svg_y,
        props.geometry,
      );
      pos = util.compute_extension_free_end_svg(extension_attached_end_svg, ext, adj_dom, props.geometry);
    }
    bool display_connector = props.display_connector;

    String classname = constants.css_selector_modification;
    if (this.modification is Modification5Prime) {
      classname += " 5'";
    } else if (this.modification is Modification3Prime) {
      classname += " 3'";
    } else {
      classname += " internal";
    }

    if (props.selected) {
      if (props.retain_strand_color_on_selection) {
        classname += ' ' + constants.css_selector_selected;
      } else {
        classname += ' ' + constants.css_selector_selected_pink;
      }
    }
    if (this.strand.is_scaffold) {
      classname += ' ' + constants.css_selector_scaffold;
    }

    var elements = [
      if (display_connector) _end_connector(pos, this.address.forward, this.modification.connector_length),
      _modification_svg(pos, this.address.forward, display_connector, this.modification.connector_length),
    ];

    // String id = props.modification.html_id(props.address);
    String id = props.selectable_modification.id;

    return (Dom.g()
      ..onPointerDown = ((ev) {
        if (modification_selectable(props.selectable_modification)) {
          props.selectable_modification.handle_selection_mouse_down(ev.nativeEvent);
        }
      })
      ..onPointerUp = ((ev) {
        if (modification_selectable(props.selectable_modification)) {
          props.selectable_modification.handle_selection_mouse_up(ev.nativeEvent);
        }
      })
      ..className = classname
      ..id = id
      ..transform = props.transform)(elements);
  }

  @override
  componentDidMount() {
    var element = querySelector('#${props.selectable_modification.id}')!;
    element.addEventListener('contextmenu', on_context_menu);
  }

  @override
  componentWillUnmount() {
    super.componentWillUnmount();
    var element = querySelector('#${props.selectable_modification.id}')!;
    element.removeEventListener('contextmenu', on_context_menu);
  }

  on_context_menu(Event ev) {
    MouseEvent event = ev as MouseEvent;
    if (!event.shiftKey) {
      event.preventDefault();
      event.stopPropagation(); // needed to prevent strand context menu from popping up
      app.dispatch(
        actions.ContextMenuShow(
          context_menu: ContextMenu(
            items: context_menu_modification(this.strand).build(),
            position: util.from_point_num(event.page),
          ),
        ),
      );
    }
  }

  List<ContextMenuItem> context_menu_modification(Strand strand) => [
    ContextMenuItem(title: 'remove modification', on_click: remove_modification),
    ContextMenuItem(
      title: 'edit modification',
      on_click:
          () => edit_modification(
            this.modification,
            props.selectable_modification,
            this.strand,
            props.dna_idx_mod,
          ),
    ),
  ];

  remove_modification() {
    List<SelectableModification> selectable_mods =
        app.state.ui_state.selectables_store.selected_modifications.toList();
    if (!selectable_mods.contains(props.selectable_modification)) {
      selectable_mods.add(props.selectable_modification);
    }

    actions.UndoableAction action;
    if (selectable_mods.length == 1) {
      action = actions.ModificationRemove(
        strand: this.strand,
        modification: this.modification,
        strand_dna_idx: props.dna_idx_mod,
      );
    } else if (selectable_mods.length > 1) {
      action = actions.DeleteAllSelected();
    } else {
      print('WARNING: selectable_mods should have at least one element in it by this line');
      return;
    }

    app.dispatch(action);
  }

  ReactElement _end_connector(Point<double> pos, bool forward, int connector_length) {
    double y_delta = y_delta_mod();
    double y_del_small = (forward ? -y_delta : y_delta);
    double x = -x_delta_mod();

    List<String> points = [];
    for (int i = 0; i < connector_length + 1; i++) {
      num x_pos = pos.x + (i % 2 == 1 ? x : 0);
      points.add('${x_pos},${pos.y + i * y_del_small} ');
    }
    var points_str = points.join('');

    return (Dom.polyline()
      ..fill = 'none'
      ..stroke = 'black'
      ..strokeWidth = 2
      ..points = points_str
      ..key = 'connector')();
  }

  ReactElement _modification_svg(
    Point<double> pos,
    bool forward,
    bool display_connector,
    int connector_length,
  ) {
    num y_delta = y_delta_mod();
    double y_del_small = (forward ? -y_delta : y_delta).toDouble();
    double font_size = props.font_size;
    String baseline = forward ? 'baseline' : 'hanging';
    if (!display_connector) {
      baseline = 'middle';
    }

    double translation = y_del_small * connector_length;

    return (Dom.text()
      ..className = 'modification-text'
      ..fontSize = font_size
      ..x = pos.x
      ..y = display_connector ? pos.y + translation : pos.y
      ..dominantBaseline = baseline
      ..key = 'mod')(this.modification.display_text);
  }

  double y_delta_mod() => props.geometry.base_height_svg * 0.45;

  double x_delta_mod() => props.geometry.base_width_svg / 3.0;
}

Future<void> ask_for_add_modification(
  Strand strand,
  Substrand substrand,
  Address address, [
  ModificationType type = ModificationType.internal,
]) async {
  /*
    substrand -  selected substrand (domain or extension)
    address - address of DNA base (nullable if substrand is an extension)
    type - type of modification: five_prime, three_prime, internal (default)
    */
  int selected_index = 2;

  if (type == ModificationType.five_prime) {
    selected_index = 1;
  } else if (type == ModificationType.three_prime) {
    selected_index = 0;
  }

  // if they clicked on a domain, get the address; if an extension, just default to 0
  int strand_dna_idx = substrand is Domain ? clicked_strand_dna_idx(substrand, address, strand) : 0;

  int modification_type_idx = 0;
  int display_text_idx = 1;
  int vendor_code_idx = 2;
  int connector_length_idx = 3;
  int index_of_dna_base_idx = 4;
  int attached_to_base_idx = 5;
  int allowed_bases_idx = 6;
  var items = util.FixedList<DialogItem>(7);
  items[modification_type_idx] = DialogRadio(
    label: 'modification type',
    options: {"3'", "5'", "internal"},
    selected_idx: selected_index,
  );

  String initial_display_text = "";
  String initial_vendor_code = "";
  int initial_connector_length = constants.default_modification_connector_length;
  // String initial_id = "";

  // if there is a last mod of this type, it auto-populates the dialog inputs
  Modification? last_mod;
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
    initial_vendor_code = last_mod.vendor_code;
    initial_connector_length = last_mod.connector_length;
  }

  items[display_text_idx] = DialogText(
    label: 'display text',
    value: initial_display_text,
    tooltip: tooltip_display_text_textfield,
  );
  items[vendor_code_idx] = DialogText(
    label: 'vendor code',
    value: initial_vendor_code,
    tooltip: tooltip_vendor_code_textfield,
  );
  items[connector_length_idx] = DialogInteger(
    label: 'connector length',
    value: initial_connector_length,
    tooltip: tooltip_connector_length_textfield,
  );

  items[index_of_dna_base_idx] = DialogInteger(
    label: 'index of DNA base',
    value: strand_dna_idx,
    tooltip: tooltip_index_of_dna_base_textfield,
  );

  items[attached_to_base_idx] = DialogCheckbox(
    label: 'attached to base?',
    value: true,
    tooltip: tooltip_attached_to_base_checkbox,
  );

  items[allowed_bases_idx] = DialogText(
    label: 'allowed bases',
    value: 'ACGT',
    tooltip: tooltip_allowed_bases_textfield,
  );

  // don't allow to modify index of DNA base when 3' or 5' is selected
  var dialog = Dialog(
    title: 'add modification',
    type: DialogType.add_modification,
    items: items,
    // so that where they click influences which type of modification (5'/3'/internal) is automatically
    // selected for them instead of being whatever the previous dialog used
    use_saved_response: false,
    disable_when_any_radio_button_selected: {
      index_of_dna_base_idx: {
        modification_type_idx: ["3'", "5'"],
      },
      attached_to_base_idx: {
        modification_type_idx: ["3'", "5'"],
      },
      allowed_bases_idx: {
        modification_type_idx: ["3'", "5'"],
      },
    },
    disable_when_any_checkboxes_off: {
      allowed_bases_idx: [attached_to_base_idx],
    },
  );

  List<DialogItem>? results = await util.dialog(dialog);
  if (results == null) return;
  String modification_type = (results[modification_type_idx] as DialogRadio).value;
  String display_text = (results[display_text_idx] as DialogText).value;
  String vendor_code = (results[vendor_code_idx] as DialogText).value;
  int connector_length = (results[connector_length_idx] as DialogInteger).value;
  int index_of_dna_base = (results[index_of_dna_base_idx] as DialogInteger).value;
  bool attached_to_base = (results[attached_to_base_idx] as DialogCheckbox).value;
  String allowed_bases_str = (results[allowed_bases_idx] as DialogText).value;

  Modification mod;
  if (modification_type == "3'") {
    mod = Modification3Prime(
      display_text: display_text,
      vendor_code: vendor_code,
      connector_length: connector_length,
    );
  } else if (modification_type == "5'") {
    mod = Modification5Prime(
      display_text: display_text,
      vendor_code: vendor_code,
      connector_length: connector_length,
    );
  } else {
    var allowed_bases = null;
    if (attached_to_base) {
      allowed_bases_str = allowed_bases_str.replaceAll(RegExp(r'[^(ACGTacgt)]'), '');
      allowed_bases =
          {for (int i = 0; i < allowed_bases_str.length; i++) allowed_bases_str[i].toUpperCase()}.build();
    }
    mod = ModificationInternal(
      display_text: display_text,
      vendor_code: vendor_code,
      connector_length: connector_length,
      allowed_bases: allowed_bases,
    );
  }

  // if modification type is 5' or 3' and many such ends are selected, add modifications to all of them
  actions.UndoableAction action;
  if (mod is ModificationInternal) {
    action = actions.ModificationAdd(strand: strand, modification: mod, strand_dna_idx: index_of_dna_base);
  } else {
    List<DNAEnd> ends_selected = app.state.ui_state.selectables_store.selected_dna_ends.toList();

    if (mod is Modification5Prime && !ends_selected.contains(strand.dnaend_5p)) {
      ends_selected.add(strand.dnaend_5p);
    } else if (mod is Modification3Prime && !ends_selected.contains(strand.dnaend_3p)) {
      ends_selected.add(strand.dnaend_3p);
    }

    if (ends_selected.length == 1) {
      action = actions.ModificationAdd(strand: strand, modification: mod, strand_dna_idx: index_of_dna_base);
    } else if (ends_selected.length > 1) {
      // safe to batch this action since it's only for 5' or 3', so each strand will only be modified once
      List<actions.ModificationAdd> all_actions = [];
      for (var end_selected in ends_selected) {
        var strand_of_end_selected = app.state.design.end_to_strand(end_selected);
        var new_action = actions.ModificationAdd(
          strand: strand_of_end_selected,
          modification: mod,
          strand_dna_idx: null,
        );
        all_actions.add(new_action);
      }
      action = actions.BatchAction(all_actions, "add modifications");
    } else {
      print('WARNING: selectable_mods should have at least one element in it by this line');
      return;
    }
  }

  app.dispatch(action);
}

edit_modification(
  Modification modification,
  SelectableModification selectable_modification,
  Strand strand,
  int? dna_idx_mod,
) async {
  int display_text_idx = 0;
  int vendor_code_idx = 1;
  int connector_length_idx = 2;
  int attached_to_base_idx = 3;
  int allowed_bases_idx = 4;

  bool is_internal = modification is ModificationInternal;
  int num_items = is_internal ? 5 : 3;
  var items = util.FixedList<DialogItem>(num_items);
  items[display_text_idx] = DialogText(
    label: 'display text',
    value: modification.display_text,
    tooltip: tooltip_display_text_textfield,
  );
  items[vendor_code_idx] = DialogText(
    label: 'vendor code',
    value: modification.vendor_code,
    tooltip: tooltip_vendor_code_textfield,
  );
  items[connector_length_idx] = DialogInteger(
    label: 'connector length',
    value: modification.connector_length,
    tooltip: tooltip_connector_length_textfield,
  );

  if (is_internal) {
    bool attached_to_base_old = modification.allowed_bases != null;
    items[attached_to_base_idx] = DialogCheckbox(
      label: 'attached to base?',
      value: attached_to_base_old,
      tooltip: tooltip_attached_to_base_checkbox,
    );

    var allowed_bases_old =
        modification.allowed_bases != null ? modification.allowed_bases!.join('') : 'ACGT';
    items[allowed_bases_idx] = DialogText(
      label: 'allowed bases',
      value: allowed_bases_old,
      tooltip: tooltip_allowed_bases_textfield,
    );
  }

  var dialog = Dialog(
    title: 'edit modification',
    type: DialogType.edit_modification,
    items: items,
    use_saved_response: false,
    disable_when_any_checkboxes_off:
        is_internal
            ? {
              allowed_bases_idx: [attached_to_base_idx],
            }
            : {},
  );
  List<DialogItem>? results = await util.dialog(dialog);
  if (results == null) return;

  String display_text = (results[display_text_idx] as DialogText).value;
  String vendor_code = (results[vendor_code_idx] as DialogText).value;
  int connector_length = (results[connector_length_idx] as DialogInteger).value;

  Modification new_mod;
  if (modification is Modification3Prime) {
    new_mod = Modification3Prime(
      display_text: display_text,
      vendor_code: vendor_code,
      connector_length: connector_length,
    );
  } else if (modification is Modification5Prime) {
    new_mod = Modification5Prime(
      display_text: display_text,
      vendor_code: vendor_code,
      connector_length: connector_length,
    );
  } else {
    bool attached_to_base = (results[attached_to_base_idx] as DialogCheckbox).value;
    String allowed_bases_str = (results[allowed_bases_idx] as DialogText).value;
    var allowed_bases = null;
    if (attached_to_base) {
      // remove all symbols other than ACGTacgt
      allowed_bases_str = allowed_bases_str.replaceAll(RegExp(r'[^(ACGTacgt)]'), '');
      allowed_bases =
          {for (int i = 0; i < allowed_bases_str.length; i++) allowed_bases_str[i].toUpperCase()}.build();
    }
    new_mod = ModificationInternal(
      display_text: display_text,
      vendor_code: vendor_code,
      connector_length: connector_length,
      allowed_bases: allowed_bases,
    );
  }

  var selectable_mods = app.state.ui_state.selectables_store.selected_modifications.toList();
  if (!selectable_mods.contains(selectable_modification)) {
    selectable_mods.add(selectable_modification);
  }

  actions.UndoableAction action;
  if (selectable_mods.length == 1) {
    action = actions.ModificationEdit(strand: strand, modification: new_mod, strand_dna_idx: dna_idx_mod);
  } else if (selectable_mods.length > 1) {
    if (new_mod is Modification5Prime) {
      var selectable_mods_5p = List<SelectableModification5Prime>.from(
        selectable_mods.where((mod) => mod is SelectableModification5Prime),
      );
      action = actions.Modifications5PrimeEdit(modifications: selectable_mods_5p, new_modification: new_mod);
    } else if (new_mod is Modification3Prime) {
      var selectable_mods_3p = List<SelectableModification3Prime>.from(
        selectable_mods.where((mod) => mod is SelectableModification3Prime),
      );
      action = actions.Modifications3PrimeEdit(modifications: selectable_mods_3p, new_modification: new_mod);
    } else if (new_mod is ModificationInternal) {
      var selectable_mods_int = List<SelectableModificationInternal>.from(
        selectable_mods.where((mod) => mod is SelectableModificationInternal),
      );
      action = actions.ModificationsInternalEdit(
        modifications: selectable_mods_int,
        new_modification: new_mod,
      );
    } else {
      throw AssertionError('should be unreachable');
    }
  } else {
    print('WARNING: selectable_mods should have at least one element in it by this line');
    return;
  }

  app.dispatch(action);
}

String tooltip_display_text_textfield = '''\
This is the text displayed in the scadnano web interface to depict the modification.''';

String tooltip_vendor_code_textfield = '''\
This is the "vendor code" of the modification, for instance /5Biosg/ for 5' biotin when ordering
from the vendor IDT DNA.''';

String tooltip_connector_length_textfield = '''\
The number of lines in the "connector" displayed to separate the modification "display text" 
from the strand.''';

String tooltip_index_of_dna_base_textfield = '''\
The index of the DNA base at which to attach an internal modification.''';
