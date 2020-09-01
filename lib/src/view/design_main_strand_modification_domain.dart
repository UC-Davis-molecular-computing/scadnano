import 'dart:html';
import 'dart:math';

import 'package:over_react/over_react.dart';
import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/state/context_menu.dart';
import 'package:scadnano/src/state/dialog.dart';
import '../state/modification.dart';
import '../app.dart';
import '../actions/actions.dart' as actions;
import '../util.dart' as util;

import '../state/strand.dart';
import '../state/helix.dart';
import '../constants.dart' as constants;

part 'design_main_strand_modification_domain.over_react.g.dart';

UiFactory<DesignMainStrandModificationDomainProps> DesignMainStrandModificationDomain =
    _$DesignMainStrandModificationDomain;

mixin DesignMainStrandModificationDomainProps on UiProps {
  Strand strand;
  int dna_idx_mod;
  Address address;
  Helix helix;
  Modification modification;
  bool display_connector;
  int font_size;
  bool invert_y;
  String transform;
}

class DesignMainStrandModificationDomainComponent
    extends UiComponent2<DesignMainStrandModificationDomainProps> {
  @override
  render() {
    Point<num> pos = props.helix.svg_base_pos(props.address.offset, props.address.forward);
    bool display_connector = props.display_connector;
    if (props.modification is Modification5Prime) {
      return (Dom.g()
        ..className = "'modification-5'"
        ..id = "modification-" + props.modification.id + "-" + props.address.offset.toString()
        ..transform = props.transform)([
        if (display_connector) _end_connector(pos, props.address.forward),
        _modification_svg(pos, props.address.forward, display_connector),
      ]);
    } else if (props.modification is Modification3Prime) {
      return (Dom.g()
        ..className = "'modification-3'"
        ..id = "modification-" + props.modification.id + "-" + props.address.offset.toString()
        ..transform = props.transform)([
        if (display_connector) _end_connector(pos, props.address.forward),
        _modification_svg(pos, props.address.forward, display_connector),
      ]);
    } else {
      return (Dom.g()
        ..className = 'modification-internal'
        ..id = "modification-" + props.modification.id + "-" + props.address.offset.toString()
        ..transform = props.transform)([
        if (display_connector) _internal_connector(pos, props.address.forward),
        _modification_svg(pos, props.address.forward, display_connector),
      ]);
    }
  }

  @override
  componentDidMount() {
    var element = querySelector(
        '#${"modification-" + props.modification.id.replaceAll('/', '\\/') + "-" + props.address.offset.toString()}');
    element.addEventListener('contextmenu', on_context_menu);
  }

  @override
  componentWillUnmount() {
    var element = querySelector(
        '#${"modification-" + props.modification.id.replaceAll('/', '\\/') + "-" + props.address.offset.toString()}');
    element.removeEventListener('contextmenu', on_context_menu);
  }

  on_context_menu(Event ev) {
    MouseEvent event = ev;
    if (!event.shiftKey) {
      event.preventDefault();
      event.stopPropagation(); // needed to prevent strand context menu from popping up
      app.dispatch(actions.ContextMenuShow(
          context_menu: ContextMenu(items: context_menu_strand(props.strand).build(), position: event.page)));
    }
  }

  List<ContextMenuItem> context_menu_strand(Strand strand) => [
        ContextMenuItem(title: 'remove modification', on_click: remove_modification),
        ContextMenuItem(title: 'edit modification', on_click: edit_modification),
      ];

  remove_modification() {
    app.dispatch(actions.ModificationRemove(
        strand: props.strand, modification: props.modification, strand_dna_idx: props.dna_idx_mod));
  }

  edit_modification() async {
    int display_text_idx = 0;
    int id_idx = 1;
    int idt_text_idx = 2;
    var items = List<DialogItem>(3);
    items[display_text_idx] = DialogText(label: 'display text', value: props.modification.display_text);
    items[id_idx] = DialogText(label: 'id', value: props.modification.id);
    items[idt_text_idx] = DialogText(label: 'idt text', value: props.modification.idt_text);

    var dialog = Dialog(title: 'edit modification', items: items);
    List<DialogItem> results = await util.dialog(dialog);
    if (results == null) return;

    String display_text = (results[display_text_idx] as DialogText).value;
    String id = (results[id_idx] as DialogText).value;
    String idt_text = (results[idt_text_idx] as DialogText).value;

    Modification mod;
    if (props.modification is Modification3Prime) {
      mod = Modification3Prime(
          display_text: display_text, id: id, idt_text: idt_text, unused_fields: BuiltMap<String, Object>());
    } else if (props.modification is Modification5Prime) {
      mod = Modification5Prime(
          display_text: display_text, id: id, idt_text: idt_text, unused_fields: BuiltMap<String, Object>());
    } else {
      mod = ModificationInternal(
          display_text: display_text,
          id: props.modification.id,
          idt_text: props.modification.idt_text,
          allowed_bases: null,
          unused_fields: BuiltMap<String, Object>());
    }
    app.dispatch(
        actions.ModificationEdit(strand: props.strand, modification: mod, strand_dna_idx: props.dna_idx_mod));
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

  ReactElement _internal_connector(Point<num> pos, bool forward) {
    num y_delta = y_delta_mod();
    double y_del_small = (forward ? -y_delta : y_delta).toDouble();
    return (Dom.line()
      ..stroke = 'black'
      ..strokeWidth = 2
      ..x1 = pos.x
      ..y1 = pos.y
      ..x2 = pos.x
      ..y2 = pos.y + y_del_small
      ..key = 'connector')();
  }

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
