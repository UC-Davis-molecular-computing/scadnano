import 'dart:html';
import 'dart:math';

import 'package:over_react/over_react.dart';
import 'package:built_collection/built_collection.dart';

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

part 'design_main_strand_modification.over_react.g.dart';

UiFactory<DesignMainStrandModificationProps> DesignMainStrandModification = _$DesignMainStrandModification;

mixin DesignMainStrandModificationProps on UiProps {
  int dna_idx_mod;
  Helix helix;
  bool display_connector;
  int font_size;
  bool invert_y;
  String transform;

  Geometry geometry;

  SelectableModification selectable_modification;

  Strand get strand => selectable_modification.strand;

  Modification get modification => selectable_modification.modification;

  Address get address => selectable_modification.address;

  bool selected;

  num helix_svg_position_y;

  Extension ext; // optional; used if mod is on extension
}

class DesignMainStrandModificationComponent extends UiComponent2<DesignMainStrandModificationProps> {
  @override
  render() {
    Point<num> pos;
    if (props.ext == null) {
      pos = props.helix.svg_base_pos(props.address.offset, props.address.forward, props.helix_svg_position_y);
    } else {
      var ext = props.ext;
      var adj_dom = props.ext.adjacent_domain;
      var adj_helix = props.helix;
      var adj_helix_svg_y = props.helix_svg_position_y;
      Point<num> extension_attached_end_svg =
          util.compute_extension_attached_end_svg(ext, adj_dom, adj_helix, adj_helix_svg_y);
      pos = util.compute_extension_free_end_svg(extension_attached_end_svg, ext, adj_dom, props.geometry);
    }
    bool display_connector = props.display_connector;

    String classname = constants.css_selector_modification;
    if (props.modification is Modification5Prime) {
      classname += " 5'";
    } else if (props.modification is Modification3Prime) {
      classname += " 3'";
    } else {
      classname += " internal";
    }

    if (props.selected) {
      classname += ' ' + constants.css_selector_selected;
    }
    if (props.strand.is_scaffold) {
      classname += ' ' + constants.css_selector_scaffold;
    }

    var elements = [
      if (display_connector) _end_connector(pos, props.address.forward, props.modification.connector_length),
      _modification_svg(pos, props.address.forward, display_connector, props.modification.connector_length),
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
    var element = querySelector('#${props.selectable_modification.id}');
    element.addEventListener('contextmenu', on_context_menu);
  }

  @override
  componentWillUnmount() {
    var element = querySelector('#${props.selectable_modification.id}');
    element.removeEventListener('contextmenu', on_context_menu);
  }

  on_context_menu(Event ev) {
    MouseEvent event = ev;
    if (!event.shiftKey) {
      event.preventDefault();
      event.stopPropagation(); // needed to prevent strand context menu from popping up
      app.dispatch(actions.ContextMenuShow(
          context_menu:
              ContextMenu(items: context_menu_modification(props.strand).build(), position: event.page)));
    }
  }

  List<ContextMenuItem> context_menu_modification(Strand strand) => [
        ContextMenuItem(title: 'remove modification', on_click: remove_modification),
        ContextMenuItem(title: 'edit modification', on_click: edit_modification),
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
          strand: props.strand, modification: props.modification, strand_dna_idx: props.dna_idx_mod);
    } else if (selectable_mods.length > 1) {
      action = actions.DeleteAllSelected();
    } else {
      print('WARNING: selectable_mods should have at least one element in it by this line');
      return;
    }

    app.dispatch(action);
  }

  edit_modification() async {
    int display_text_idx = 0;
    int idt_text_idx = 1;
    int connector_length_idx = 2;
    // int id_idx = 2;
    var items = List<DialogItem>.filled(3, null);
    items[display_text_idx] = DialogText(label: 'display text', value: props.modification.display_text);
    items[idt_text_idx] = DialogText(label: 'idt text', value: props.modification.idt_text);
    items[connector_length_idx] =
        DialogInteger(label: 'connector length', value: props.modification.connector_length);
    // items[id_idx] = DialogText(label: 'id', value: props.modification.id);

    var dialog = Dialog(title: 'edit modification', items: items);
    List<DialogItem> results = await util.dialog(dialog);
    if (results == null) return;

    String display_text = (results[display_text_idx] as DialogText).value;
    String idt_text = (results[idt_text_idx] as DialogText).value;
    int connector_length = (results[connector_length_idx] as DialogInteger).value;
    // String id = (results[id_idx] as DialogText).value;

    Modification new_mod;
    if (props.modification is Modification3Prime) {
      new_mod = Modification3Prime(
        //id: id,
        display_text: display_text,
        idt_text: idt_text,
        connector_length: connector_length,
      );
    } else if (props.modification is Modification5Prime) {
      new_mod = Modification5Prime(
        //id: id,
        display_text: display_text,
        idt_text: idt_text,
        connector_length: connector_length,
      );
    } else {
      new_mod = ModificationInternal(
        // id: props.modification.id,
        display_text: display_text,
        idt_text: props.modification.idt_text,
        connector_length: connector_length,
      );
    }

    List<SelectableModification> selectable_mods =
        app.state.ui_state.selectables_store.selected_modifications.toList();
    if (!selectable_mods.contains(props.selectable_modification)) {
      selectable_mods.add(props.selectable_modification);
    }

    actions.UndoableAction action;
    if (selectable_mods.length == 1) {
      action = actions.ModificationEdit(
          strand: props.strand, modification: new_mod, strand_dna_idx: props.dna_idx_mod);
    } else if (selectable_mods.length > 1) {
      if (new_mod is Modification5Prime) {
        var selectable_mods_5p = List<SelectableModification5Prime>.from(
            selectable_mods.where((mod) => mod is SelectableModification5Prime));
        action =
            actions.Modifications5PrimeEdit(modifications: selectable_mods_5p, new_modification: new_mod);
      } else if (new_mod is Modification3Prime) {
        var selectable_mods_3p = List<SelectableModification3Prime>.from(
            selectable_mods.where((mod) => mod is SelectableModification3Prime));
        action =
            actions.Modifications3PrimeEdit(modifications: selectable_mods_3p, new_modification: new_mod);
      } else if (new_mod is ModificationInternal) {
        var selectable_mods_int = List<SelectableModificationInternal>.from(
            selectable_mods.where((mod) => mod is SelectableModificationInternal));
        action =
            actions.ModificationsInternalEdit(modifications: selectable_mods_int, new_modification: new_mod);
      }
    } else {
      print('WARNING: selectable_mods should have at least one element in it by this line');
      return;
    }

    app.dispatch(action);
  }

  ReactElement _end_connector(Point<num> pos, bool forward, int connector_length) {
    num y_delta = y_delta_mod();
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

  ReactElement _modification_svg(Point<num> pos, bool forward, bool display_connector, int connector_length) {
    num y_delta = y_delta_mod();
    double y_del_small = (forward ? -y_delta : y_delta).toDouble();
    int font_size = props.font_size;
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
      ..key = 'mod')(props.modification.display_text);
  }

  num y_delta_mod() => props.helix.geometry.base_height_svg * 0.45;

  num x_delta_mod() => props.helix.geometry.base_width_svg / 3.0;
}
