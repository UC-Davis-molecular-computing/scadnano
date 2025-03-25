import 'dart:html';

import 'package:meta/meta.dart';
import 'package:built_collection/built_collection.dart';
import 'package:color/color.dart';
import 'package:over_react/over_react.dart';
import 'package:react/react.dart' as react;

import 'package:scadnano/src/state/modification_type.dart';

import '../state/strand.dart';
import '../state/dialog.dart';
import '../state/address.dart';
import '../state/geometry.dart';
import '../state/group.dart';
import '../app.dart';
import '../state/helix.dart';
import '../state/domain.dart';
import '../state/extension.dart';
import '../util.dart' as util;
import '../state/selectable.dart';
import 'design_main_strand_dna_end.dart';
import 'design_main_strand.dart' as design_main_strand;
import 'pure_component.dart';
import '../state/context_menu.dart';
import '../actions/actions.dart' as actions;
import '../constants.dart' as constants;

part 'design_main_strand_extension.over_react.g.dart';

UiFactory<DesignMainExtensionProps> DesignMainExtension = _$DesignMainExtension;

mixin DesignMainExtensionProps on UiProps {
  late Extension ext;

  late Domain adjacent_domain;
  late Helix adjacent_helix;

  late Color strand_color;

  late Strand strand;
  late String strand_tooltip;
  late String transform;
  late Point<double> adjacent_helix_svg_position;

  late bool selected;

  late BuiltMap<int, Helix> helices;
  late BuiltMap<String, HelixGroup> groups;
  late Geometry geometry;
  late bool retain_strand_color_on_selection;
}

@Component2()
class DesignMainExtensionComponent extends UiComponent2<DesignMainExtensionProps> with PureComponent {
  @override
  render() {
    var ext = props.ext;
    String id = props.ext.id;
    var adj_dom = props.adjacent_domain;
    var adj_helix = props.adjacent_helix;
    var adj_helix_svg_y = props.adjacent_helix_svg_position.y;

    Point<double> extension_attached_end_svg =
        util.compute_extension_attached_end_svg(ext, adj_dom, adj_helix, adj_helix_svg_y, props.geometry);

    Point<double> extension_free_end_svg =
        util.compute_extension_free_end_svg(extension_attached_end_svg, ext, adj_dom, props.geometry);

    var classname = constants.css_selector_extension;
    if (props.selected) {
      if (props.retain_strand_color_on_selection) {
        classname += ' ' + constants.css_selector_selected;
      } else {
        classname += ' ' + constants.css_selector_selected_pink;
      }
    }
    if (props.strand.is_scaffold) {
      classname += ' ' + constants.css_selector_scaffold;
    }

    // To ensure that the extension name displays right-side up, we always draw from the
    // left point to the right point, regardless of which is the free end and which is attached.
    //NOTE: this causes the DNA to appear backwards in cases when the 3' end appears to the left
    // of the 5' end. For now we will ditch this and draw the extension path from 5' to 3'
    // (see svg_5p and svg_3p below), and figure out later how to display the name properly.
    // Leaving this code here to help with that later.
    // var left_svg = extension_free_end_svg;
    // var right_svg = extension_attached_end_svg;
    // if (left_svg.x > right_svg.x) {
    //   var swap = left_svg;
    //   left_svg = right_svg;
    //   right_svg = swap;
    // }

    var svg_5p = extension_free_end_svg;
    var svg_3p = extension_attached_end_svg;
    if (!ext.is_5p) {
      var swap = svg_5p;
      svg_5p = svg_3p;
      svg_3p = swap;
    }

    var color = ext.color ?? props.strand_color;

    // This is just a straight line, but for some reason, for displaying the extension name,
    // it only works to attach a textPath to it if it is a path, not a line.
    // So we use Dom.path() instead of Dom.line()
    // var path_d = 'M ${left_svg.x} ${left_svg.y} '
    //     'L ${right_svg.x} ${right_svg.y}';
    var path_d = 'M ${svg_5p.x} ${svg_5p.y} '
        'L ${svg_3p.x} ${svg_3p.y}';
    return (Dom.path()
      ..className = classname
      ..onPointerDown = handle_click_down
      ..onPointerUp = handle_click_up
      ..stroke = color.toHexColor().toCssString()
      ..transform = props.transform
      ..d = path_d
      ..id = id
      ..key = id)(Dom.svgTitle()(tooltip_text(ext) + '\n' + props.strand_tooltip));
  }

  handle_click_down(react.SyntheticPointerEvent event_syn) {
    MouseEvent event = event_syn.nativeEvent;
    if (event.button == constants.LEFT_CLICK_BUTTON) {
      if (extension_selectable(props.ext)) {
        // select/deselect
        props.ext.handle_selection_mouse_down(event);
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
      if (extension_selectable(props.ext) && !currently_moving) {
        props.ext.handle_selection_mouse_up(event_syn.nativeEvent);
      }
    }
  }

  @override
  componentDidMount() {
    var element = querySelector('#${props.ext.id}')!;
    element.addEventListener('contextmenu', on_context_menu);
  }

  @override
  componentWillUnmount() {
    super.componentWillUnmount();
    var element = querySelector('#${props.ext.id}')!;
    element.removeEventListener('contextmenu', on_context_menu);
  }

  on_context_menu(Event ev) {
    MouseEvent event = ev as MouseEvent;
    if (!event.shiftKey) {
      event.preventDefault();
      event.stopPropagation(); // needed to prevent strand context menu from popping up
      app.dispatch(actions.ContextMenuShow(
          context_menu: ContextMenu(
              items: context_menu_extension().build(), position: util.from_point_num(event.page))));
    }
  }

  List<ContextMenuItem> context_menu_extension() => [
        ContextMenuItem(
          title: 'change extension display length/angle',
          on_click: extension_display_length_and_angle_change,
        ),
        ContextMenuItem(
          title: 'change extension number of bases',
          on_click: extension_num_bases_change,
        ),
        ContextMenuItem(
          title: 'set extension name',
          on_click: set_extension_name,
        ),
        if (props.ext.name != null)
          ContextMenuItem(
              title: 'remove extension name',
              on_click: () {
                var exts =
                    util.add_if_not_null(app.state.ui_state.selectables_store.selected_extensions, props.ext);
                var action = exts.length > 1
                    ? actions.BatchAction(exts.map((l) => actions.SubstrandNameSet(name: null, substrand: l)),
                        "remove extension names")
                    : actions.SubstrandNameSet(name: null, substrand: props.ext);
                app.dispatch(action);
              }),
        ContextMenuItem(
          title: 'set extension label',
          on_click: set_extension_label,
        ),
        if (props.ext.label != null)
          ContextMenuItem(
              title: 'remove extension label',
              on_click: () {
                var exts =
                    util.add_if_not_null(app.state.ui_state.selectables_store.selected_extensions, props.ext);
                var action = exts.length > 1
                    ? actions.BatchAction(
                        exts.map((l) => actions.SubstrandLabelSet(label: null, substrand: l)),
                        "remove extension labels")
                    : actions.SubstrandLabelSet(label: null, substrand: props.ext);
                app.dispatch(action);
              }),
        ContextMenuItem(
          title: 'set extension color',
          on_click: () => app
              .dispatch(actions.StrandOrSubstrandColorPickerShow(strand: props.strand, substrand: props.ext)),
        ),
        if (props.ext.color != null)
          ContextMenuItem(
              title: 'remove extension color',
              on_click: () => app.dispatch(actions.StrandOrSubstrandColorSet(
                  strand: props.strand, substrand: props.ext, color: null))),
      ];

  extension_num_bases_change() async {
    int new_num_bases = await app.disable_keyboard_shortcuts_while(() => ask_for_num_bases(
        'change extension number of bases',
        current_num_bases: props.ext.num_bases,
        lower_bound: 1));
    if (new_num_bases == props.ext.num_bases) {
      return;
    }
    var selected_extensions = app.state.ui_state.selectables_store.selected_extensions;
    actions.UndoableAction action;
    if (selected_extensions.length > 0) {
      action = actions.ExtensionsNumBasesChange(selected_extensions, new_num_bases);
    } else {
      action = actions.ExtensionNumBasesChange(props.ext, new_num_bases);
    }
    app.dispatch(action);
  }

  set_extension_name() => app.disable_keyboard_shortcuts_while(ask_for_extension_name);

  set_extension_label() => app.disable_keyboard_shortcuts_while(() => design_main_strand.ask_for_label(
        props.strand,
        props.ext,
        app.state.ui_state.selectables_store.selected_extensions,
      ));

  Future<void> ask_for_extension_name() async {
    int name_idx = 0;
    var items = util.FixedList<DialogItem>(1);
    items[name_idx] = DialogText(label: 'name', value: props.ext.name ?? '');
    var dialog = Dialog(title: 'set extension name', items: items, type: DialogType.set_extension_name);

    List<DialogItem>? results = await util.dialog(dialog);
    if (results == null) return;

    String name = (results[name_idx] as DialogText).value;
    var selected_exts = app.state.ui_state.selectables_store.selected_extensions;
    var action;
    if (selected_exts.length > 1) {
      action = actions.BatchAction(
          selected_exts.map((e) => actions.SubstrandNameSet(name: name, substrand: e)),
          "set extension names");
    } else {
      action = actions.SubstrandNameSet(name: name, substrand: props.ext);
    }
    app.dispatch(action);
  }

  extension_display_length_and_angle_change() =>
      app.disable_keyboard_shortcuts_while(ask_for_extension_display_length_and_angle);

  Future<void> ask_for_extension_display_length_and_angle() async {
    int display_length_idx = 0;
    int display_angle_idx = 1;
    var items = util.FixedList<DialogItem>(2);
    items[display_length_idx] = DialogFloat(label: 'display length (nm)', value: props.ext.display_length);
    items[display_angle_idx] = DialogFloat(label: 'display angle (degrees)', value: props.ext.display_angle);
    var dialog = Dialog(
        title: 'set extension display length/angle',
        items: items,
        type: DialogType.set_extension_display_length_angle,
        use_saved_response: false);

    List<DialogItem>? results = await util.dialog(dialog);
    if (results == null) return;

    double display_length = (results[display_length_idx] as DialogFloat).value;
    double display_angle = (results[display_angle_idx] as DialogFloat).value;
    if (display_length <= 0) {
      window.alert('display_length must be positive, but is ${display_length}');
    } else {
      actions.UndoableAction action = actions.ExtensionDisplayLengthAngleSet(
          ext: props.ext, display_length: display_length, display_angle: display_angle);
      app.dispatch(action);
    }
  }
}

tooltip_text(Extension ext) =>
    ''
        '${ext.is_5p ? "5'" : "3'"} extension:\n'
        '    num_bases=${ext.num_bases}\n' +
    (ext.name == null ? "" : "\n    name=${ext.name}") +
    (ext.label == null ? "" : "\n    label=${ext.label.toString()}");

Future<int> ask_for_num_bases(String title,
    {required int current_num_bases, required int lower_bound}) async {
  int num_bases_idx = 0;
  var items = util.FixedList<DialogItem>(1);
  items[num_bases_idx] = DialogInteger(label: 'number of bases:', value: current_num_bases);
  var dialog = Dialog(
    title: title,
    type: DialogType.set_extension_num_bases,
    items: items,
    use_saved_response: false,
  );

  List<DialogItem>? results = await util.dialog(dialog);
  if (results == null) return current_num_bases;

  int num_bases = (results[num_bases_idx] as DialogInteger).value;
  if (num_bases < lower_bound) {
    window.alert('number of bases must be at least ${lower_bound}, but you entered $num_bases');
    return current_num_bases;
  }

  return num_bases;
}
