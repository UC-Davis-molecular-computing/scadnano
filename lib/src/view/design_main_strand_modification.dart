import 'dart:html';
import 'dart:math';

import 'package:over_react/over_react.dart';
import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/state/context_menu.dart';
import 'package:scadnano/src/state/dialog.dart';
import 'package:scadnano/src/state/selectable.dart';
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

  SelectableModification selectable_modification;

  Strand get strand => selectable_modification.strand;

  Modification get modification => selectable_modification.modification;

  Address get address => selectable_modification.address;

  bool selected;
}

class DesignMainStrandModificationComponent extends UiComponent2<DesignMainStrandModificationProps> {
  @override
  render() {
    Point<num> pos = props.helix.svg_base_pos(props.address.offset, props.address.forward);
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
      if (display_connector) _end_connector(pos, props.address.forward),
      _modification_svg(pos, props.address.forward, display_connector),
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
    // int id_idx = 2;
    var items = List<DialogItem>(2);
    items[display_text_idx] = DialogText(label: 'display text', value: props.modification.display_text);
    items[idt_text_idx] = DialogText(label: 'idt text', value: props.modification.idt_text);
    // items[id_idx] = DialogText(label: 'id', value: props.modification.id);

    var dialog = Dialog(title: 'edit modification', items: items);
    List<DialogItem> results = await util.dialog(dialog);
    if (results == null) return;

    String display_text = (results[display_text_idx] as DialogText).value;
    String idt_text = (results[idt_text_idx] as DialogText).value;
    // String id = (results[id_idx] as DialogText).value;

    Modification new_mod;
    if (props.modification is Modification3Prime) {
      new_mod = Modification3Prime(
          //id: id,
          display_text: display_text,
          idt_text: idt_text);
    } else if (props.modification is Modification5Prime) {
      new_mod = Modification5Prime(
          //id: id,
          display_text: display_text,
          idt_text: idt_text);
    } else {
      new_mod = ModificationInternal(
          // id: props.modification.id,
          display_text: display_text,
          idt_text: props.modification.idt_text);
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
        var new_mod_5p = new_mod as Modification5Prime;
        action =
            actions.Modifications5PrimeEdit(modifications: selectable_mods_5p, new_modification: new_mod_5p);
      } else if (new_mod is Modification3Prime) {
        var selectable_mods_3p = List<SelectableModification3Prime>.from(
            selectable_mods.where((mod) => mod is SelectableModification3Prime));
        var new_mod_3p = new_mod as Modification3Prime;
        action =
            actions.Modifications3PrimeEdit(modifications: selectable_mods_3p, new_modification: new_mod_3p);
      } else if (new_mod is ModificationInternal) {
        var selectable_mods_int = List<SelectableModificationInternal>.from(
            selectable_mods.where((mod) => mod is SelectableModificationInternal));
        var new_mod_int = new_mod as ModificationInternal;
        action = actions.ModificationsInternalEdit(
            modifications: selectable_mods_int, new_modification: new_mod_int);
      }
    } else {
      print('WARNING: selectable_mods should have at least one element in it by this line');
      return;
    }

    app.dispatch(action);
  }

  ReactElement _end_connector(Point<num> pos, bool forward) {
    num y_delta = y_delta_mod();
    double y_del_small = (forward ? -y_delta : y_delta) / 4.0;
    double x = -x_delta_mod();
    return (Dom.polyline()
      ..fill = 'none'
      ..stroke = 'black'
      ..strokeWidth = 2
      ..points = ''
          '${pos.x},${pos.y} '
          '${pos.x + x},${pos.y + y_del_small} '
          '${pos.x},${pos.y + 2 * y_del_small} '
          '${pos.x + x},${pos.y + 3 * y_del_small} '
          '${pos.x},${pos.y + 4 * y_del_small}'
      ..key = 'connector')();
  }

  // ReactElement _internal_connector(Point<num> pos, bool forward) {
  //   num y_delta = y_delta_mod();
  //   double y_del_small = (forward ? -y_delta : y_delta).toDouble();
  //   return (Dom.line()
  //     ..stroke = 'black'
  //     ..strokeWidth = 2
  //     ..x1 = pos.x
  //     ..y1 = pos.y
  //     ..x2 = pos.x
  //     ..y2 = pos.y + y_del_small
  //     ..key = 'connector')();
  // }

  ReactElement _modification_svg(Point<num> pos, bool forward, bool display_connector) {
    num y_delta = y_delta_mod();
    double y_del_small = (forward ? -1.1 * y_delta : y_delta).toDouble();
    int font_size = props.font_size;
    String baseline = forward ? 'baseline' : 'hanging';
    if (!display_connector) {
      baseline = 'middle';
    }
    return (Dom.text()
      ..className = 'modification-text'
      ..fontSize = font_size
      ..x = pos.x
      ..y = display_connector ? pos.y + y_del_small : pos.y
      ..dominantBaseline = baseline
      ..key = 'mod')(props.modification.display_text);
  }

  num y_delta_mod() => props.helix.geometry.base_height_svg * 1.8;

  num x_delta_mod() => props.helix.geometry.base_width_svg / 3.0;
}
