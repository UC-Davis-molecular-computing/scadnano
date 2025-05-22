import 'package:web/web.dart';
import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:color/color.dart';
import 'package:over_react/over_react.dart';
import 'package:scadnano/src/state/dialog.dart';

import 'transform_by_helix_group.dart';
import '../state/geometry.dart';
import '../state/group.dart';
import '../state/selectable.dart';
import '../state/context_menu.dart';
import '../state/edit_mode.dart';
import '../state/helix.dart';
import '../state/mouseover_data.dart';
import '../state/strand.dart';
import '../state/domain.dart';
import '../state/loopout.dart';
import '../app.dart';
import 'design_main_strand.dart' as design_main_strand;
import '../util.dart' as util;
import '../constants.dart' as constants;
import 'pure_component.dart';
import '../actions/actions.dart' as actions;

part 'design_main_strand_loopout.over_react.g.dart';

UiFactory<DesignMainLoopoutProps> DesignMainLoopout = _$DesignMainLoopout;

mixin DesignMainLoopoutProps on UiProps implements TransformByHelixGroupPropsMixin {
  late Loopout loopout;
  late Strand strand;
  late Color strand_color;

  late Domain prev_domain;
  late Domain next_domain;
  late Helix prev_helix;
  late Helix next_helix;
  late bool selected;
  late bool show_domain_names;

  late BuiltMap<int, Helix> helices;
  late BuiltMap<String, HelixGroup> groups;

  // This is here to make TransformByHelixGroupPropsMixin happy, but we use
  // prev_geometry and next_geometry instead.
  late Geometry geometry;
  late Geometry prev_geometry;
  late Geometry next_geometry;
  late double prev_helix_svg_position_y;
  late double next_helix_svg_position_y;
  late bool retain_strand_color_on_selection;
}

mixin DesignMainLoopoutState on UiState {
  // making this "local" state for the component (instead of storing in the global store)
  // skips wasteful actions and updating the state just to tell if the mouse is hovering over a loopout
  late bool mouse_hover;
}

class DesignMainLoopoutComponent extends UiStatefulComponent2<DesignMainLoopoutProps, DesignMainLoopoutState>
    with PureComponent {
  @override
  Map get initialState => (newState()..mouse_hover = false);

  @override
  render() {
    var classname = constants.css_selector_loopout;
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

    //XXX: commented out for same reason as similar commented code in design_main_strand_crossover.dart
//    if (mouse_hover) {
//      update_mouseover_loopout();
//    }

    String tooltip = 'loopout: length ${props.loopout.loopout_num_bases}';

    bool within_group = props.prev_helix.group == props.next_helix.group;
    String path_description;

    if (within_group) {
      path_description = loopout_path_description_within_group(
        props.prev_helix,
        props.next_helix,
        props.prev_domain,
        props.next_domain,
        props.loopout,
        true,
        props.show_domain_names,
        props.prev_helix_svg_position_y,
        props.next_helix_svg_position_y,
        props.prev_geometry,
        props.next_geometry,
      );
    } else {
      path_description = loopout_path_description_between_groups();
    }

    var color = props.loopout.color ?? props.strand_color;

    var path_props = Dom.path()
      ..className = classname
      ..stroke = color.toHexColor().toCssString()
      ..d = path_description
      ..onMouseEnter = (ev) {
        setState(newState()..mouse_hover = true);
      }
      ..onMouseLeave = ((_) {
        setState(newState()..mouse_hover = false);
      })
      ..onPointerDown = ((ev) {
        if (loopout_selectable(props.loopout)) {
          props.loopout.handle_selection_mouse_down(ev.nativeEvent);
        }
      })
      ..onPointerUp = ((ev) {
        if (loopout_selectable(props.loopout)) {
          props.loopout.handle_selection_mouse_up(ev.nativeEvent);
        }
      })
      ..key = props.loopout.id
      ..id = props.loopout.id;

    if (within_group) {
      path_props.transform = transform_of_helix2(props, props.prev_helix.idx);
    }

    return path_props(Dom.svgTitle()(tooltip));
  }

  @override
  componentDidMount() {
    var element = querySelector('#${props.loopout.id}')!;
    element.addEventListener('contextmenu', on_context_menu);
  }

  @override
  componentWillUnmount() {
    super.componentWillUnmount();
    var element = querySelector('#${props.loopout.id}')!;
    element.removeEventListener('contextmenu', on_context_menu);
  }

  on_context_menu(Event ev) {
    MouseEvent event = ev as MouseEvent;
    if (!event.shiftKey) {
      event.preventDefault();
      event.stopPropagation(); // needed to prevent strand context menu from popping up
      app.dispatch(actions.ContextMenuShow(
          context_menu:
              ContextMenu(items: context_menu_loopout().build(), position: util.from_point_num(event.page))));
    }
  }

  List<ContextMenuItem> context_menu_loopout() => [
        ContextMenuItem(
          title: 'change loopout length',
          on_click: loopout_length_change,
        ),
        ContextMenuItem(
          title: 'set loopout name',
          on_click: set_loopout_name,
        ),
        if (props.loopout.name != null)
          ContextMenuItem(
              title: 'remove loopout name',
              on_click: () {
                var loopouts = util.add_if_not_null(
                    app.state.ui_state.selectables_store.selected_loopouts, props.loopout);
                var action = loopouts.length > 1
                    ? actions.BatchAction(
                        loopouts.map((l) => actions.SubstrandNameSet(name: null, substrand: l)),
                        "remove loopout names")
                    : actions.SubstrandNameSet(name: null, substrand: props.loopout);
                app.dispatch(action);
              }),
        ContextMenuItem(
          title: 'set loopout label',
          on_click: set_loopout_label,
        ),
        if (props.loopout.label != null)
          ContextMenuItem(
              title: 'remove loopout label',
              on_click: () {
                var loopouts = util.add_if_not_null(
                    app.state.ui_state.selectables_store.selected_loopouts, props.loopout);
                var action = loopouts.length > 1
                    ? actions.BatchAction(
                        loopouts.map((l) => actions.SubstrandLabelSet(label: null, substrand: l)),
                        "remove loopout labels")
                    : actions.SubstrandLabelSet(label: null, substrand: props.loopout);
                app.dispatch(action);
              }),
        ContextMenuItem(
          title: 'set loopout color',
          on_click: () => app.dispatch(
              actions.StrandOrSubstrandColorPickerShow(strand: props.strand, substrand: props.loopout)),
        ),
        if (props.loopout.color != null)
          ContextMenuItem(
              title: 'remove loopout color',
              on_click: () => app.dispatch(actions.StrandOrSubstrandColorSet(
                  strand: props.strand, substrand: props.loopout, color: null))),
      ];

  update_mouseover_loopout() {
    Domain prev_domain = props.prev_domain;
    Domain next_domain = props.next_domain;
    List<MouseoverParams> param_list = [];
    for (var dom in [prev_domain, next_domain]) {
      int helix_idx = dom == prev_domain ? prev_domain.helix : next_domain.helix;
      int offset = dom == prev_domain ? dom.offset_3p : dom.offset_5p;
      bool forward = dom.forward;
      param_list.add(MouseoverParams(helix_idx, offset, forward));
    }

    app.dispatch(actions.MouseoverDataUpdate(mouseover_params: BuiltList<MouseoverParams>(param_list)));
  }

  loopout_length_change() async {
    int new_length = await app.disable_keyboard_shortcuts_while(() => ask_for_length(
        'change loopout length (0 to convert to crossover)',
        current_length: props.loopout.loopout_num_bases,
        lower_bound: 0,
        dialog_type: DialogType.set_loopout_length));
    if (new_length == props.loopout.loopout_num_bases) {
      return;
    }
    var selected_loopouts = app.state.ui_state.selectables_store.selected_loopouts;
    actions.UndoableAction action;
    if (selected_loopouts.length > 0) {
      action = actions.LoopoutsLengthChange(selected_loopouts, new_length);
    } else {
      action = actions.LoopoutLengthChange(props.loopout, new_length);
    }
    app.dispatch(action);
  }

  set_loopout_name() => app.disable_keyboard_shortcuts_while(ask_for_loopout_name);

  set_loopout_label() => app.disable_keyboard_shortcuts_while(() => design_main_strand.ask_for_label(
        props.strand,
        props.loopout,
        app.state.ui_state.selectables_store.selected_loopouts,
      ));

  Future<void> ask_for_loopout_name() async {
    int name_idx = 0;
    var items = util.FixedList<DialogItem>(1);
    items[name_idx] = DialogText(label: 'name', value: props.loopout.name ?? '');
    var dialog = Dialog(title: 'set loopout name', type: DialogType.set_loopout_name, items: items);

    List<DialogItem>? results = await util.dialog(dialog);
    if (results == null) return;

    String name = (results[name_idx] as DialogText).value;
    var loopouts = app.state.ui_state.selectables_store.selected_loopouts.toSet();
    loopouts.add(props.loopout);

    var action = loopouts.isNotEmpty
        ? actions.BatchAction(
            loopouts.map((l) => actions.SubstrandNameSet(name: name, substrand: l)), "set loopout names")
        : actions.SubstrandNameSet(name: name, substrand: props.loopout);
    app.dispatch(action);
  }

  String loopout_path_description_between_groups() {
    int prev_offset = props.prev_domain.dnaend_3p.offset_inclusive;
    int next_offset = props.next_domain.dnaend_5p.offset_inclusive;

    var prev_group = props.groups[props.prev_helix.group]!;
    var next_group = props.groups[props.next_helix.group]!;

    var prev_svg_untransformed = props.prev_helix.svg_base_pos(
        prev_offset, props.prev_domain.forward, props.prev_helix_svg_position_y, props.geometry);
    var next_svg_untransformed = props.next_helix.svg_base_pos(
        next_offset, props.next_domain.forward, props.next_helix_svg_position_y, props.geometry);

    var prev_svg = prev_group.transform_point_main_view(prev_svg_untransformed, props.geometry);
    var next_svg = next_group.transform_point_main_view(next_svg_untransformed, props.geometry);

    var w = 2 * util.sigmoid(props.loopout.loopout_num_bases) * props.geometry.base_width_svg;
    var h = 10 * util.sigmoid(props.loopout.loopout_num_bases - 3) * props.geometry.base_height_svg;

    // un-rotated
    var prev_y_offset = prev_svg.y + h;
    var next_y_offset = next_svg.y - h;
    var prev_x_offset = prev_svg.x + w;
    var next_x_offset = next_svg.x + w;
    var prev_c_unrotated = Point<double>(prev_x_offset, prev_y_offset);
    var next_c_unrotated = Point<double>(next_x_offset, next_y_offset);

    // rotated
    var prev_c = util.rotate(prev_c_unrotated, prev_group.pitch, origin: prev_svg);
    var next_c = util.rotate(next_c_unrotated, next_group.pitch, origin: next_svg);

    var path = 'M ${prev_svg.x} ${prev_svg.y} '
        'C ${prev_c.x} ${prev_c.y} ${next_c.x} ${next_c.y} '
        '${next_svg.x} ${next_svg.y}';

    return path;
  }
}

// This is a function (not a Component method with access to props)
// so that DesignMainStrandMoving can call it also.
// The bool [include_start_M] indicates whether to start the path with a command like "M 0 1".
// When drawing a normal loopout this is needed, but when drawing a moving strand, where all path commands
// are concatenated together, it is not needed.
String loopout_path_description_within_group(
  Helix prev_helix,
  Helix next_helix,
  Domain prev_domain,
  Domain next_domain,
  Loopout loopout,
  bool include_start_M,
  bool show_loopout_labels,
  num prev_helix_svg_position_y,
  num next_helix_svg_position_y,
  Geometry prev_geometry,
  Geometry next_geometry,
) {
  Helix top_helix = prev_helix;
  Helix bot_helix = next_helix;
  Domain top_dom = prev_domain;
  Domain bot_dom = next_domain;

  bool same_helix = top_helix.idx == bot_helix.idx;
  if (same_helix && top_dom.forward == bot_dom.forward) {
    return loopout_path_description_same_helix_same_direction(loopout, prev_helix, prev_domain, next_domain,
        include_start_M, show_loopout_labels, prev_helix_svg_position_y, prev_geometry);
  } else if (prev_helix_svg_position_y > next_helix_svg_position_y || same_helix && !top_dom.forward) {
    // helices are same if same_helix is true, but we'd still like top_dom/bot_dom to reflect which
    // is on top, i.e. that of the forward domain
    top_helix = next_helix;
    bot_helix = prev_helix;
    top_dom = next_domain;
    bot_dom = prev_domain;
  }
  bool top_dom_is_prev = top_dom == prev_domain;

  int top_offset = top_dom_is_prev ? top_dom.offset_3p : top_dom.offset_5p;
  int bot_offset = top_dom_is_prev ? bot_dom.offset_5p : bot_dom.offset_3p;
  int prev_offset = top_dom_is_prev ? top_offset : bot_offset;
  int next_offset = top_dom_is_prev ? bot_offset : top_offset;

  var prev_svg =
      prev_helix.svg_base_pos(prev_offset, prev_domain.forward, prev_helix_svg_position_y, prev_geometry);
  var next_svg =
      next_helix.svg_base_pos(next_offset, next_domain.forward, next_helix_svg_position_y, next_geometry);

  var w, h;

  if (top_helix.idx == bot_helix.idx) {
    w = 1.5 * util.sigmoid(loopout.loopout_num_bases - 1) * prev_geometry.base_width_svg;
    if (show_loopout_labels) {
      h = 10 * util.sigmoid(loopout.loopout_num_bases) * prev_geometry.base_height_svg;
    } else {
      h = 10 * util.sigmoid(loopout.loopout_num_bases - 5) * prev_geometry.base_height_svg;
    }
  } else {
    w = 2 * util.sigmoid(loopout.loopout_num_bases) * prev_geometry.base_width_svg;
    h = 10 * util.sigmoid(loopout.loopout_num_bases - 3) * prev_geometry.base_height_svg;
  }

  var x_offset1, x_offset2, y_offset1, y_offset2;
  y_offset1 = prev_svg.y;
  y_offset2 = next_svg.y;
  x_offset1 = prev_svg.x;
  x_offset2 = next_svg.x;
  if (top_offset == top_dom.end - 1) {
    x_offset1 += w;
    x_offset2 += w;
  } else {
    x_offset1 -= w;
    x_offset2 -= w;
  }
  if (top_dom_is_prev) {
    y_offset1 -= h;
    y_offset2 += h;
  } else {
    y_offset1 += h;
    y_offset2 -= h;
  }

  var c1 = Point<double>(x_offset1, y_offset1);
  var c2 = Point<double>(x_offset2, y_offset2);

  var path = (include_start_M ? 'M ${prev_svg.x} ${prev_svg.y} ' : '') +
      'C ${c1.x} ${c1.y} ${c2.x} ${c2.y} ${next_svg.x} ${next_svg.y}';

  return path;
}

String loopout_path_description_same_helix_same_direction(
  Loopout loopout,
  Helix helix,
  Domain prev_domain,
  Domain next_domain,
  bool include_start_m,
  bool show_loopout_labels,
  num helix_svg_position_y,
  Geometry geometry,
) {
  int prev_offset = prev_domain.offset_3p;
  int next_offset = next_domain.offset_5p;
  bool forward = prev_domain.forward;
  var prev_svg = helix.svg_base_pos(prev_offset, forward, helix_svg_position_y, geometry);
  var next_svg = helix.svg_base_pos(next_offset, forward, helix_svg_position_y, geometry);

  int left_offset = prev_offset;
  int right_offset = next_offset;
  var left_svg = prev_svg;
  var right_svg = next_svg;
  bool left_is_prev = left_offset < right_offset;
  if (!left_is_prev) {
    left_offset = next_offset;
    right_offset = prev_offset;
    left_svg = next_svg;
    right_svg = prev_svg;
  }

  double x_distance = right_svg.x - left_svg.x;
  double h = 3 * util.sigmoid(loopout.loopout_num_bases - 1) * geometry.base_height_svg;
  int length = loopout.loopout_num_bases;
  if (!show_loopout_labels) {
    length -= 5;
  }

  // taking cubed root of x distance for intermediate bezier points seems to place curve at
  // about a constant offset from x coordinates of ends the loopout is connecting
  double w = 2 * pow(x_distance, 1.0 / 3.0) * util.sigmoid(length) * geometry.base_width_svg;

  double left_x = left_svg.x - w;
  double right_x = right_svg.x + w;
  double y = left_svg.y;

  if (forward) {
    y -= h;
  } else {
    y += h;
  }

  var c1 = Point<double>(left_x, y);
  var c2 = Point<double>(right_x, y);

  if (!left_is_prev) {
    var swap = c1;
    c1 = c2;
    c2 = swap;
  }

  var path = (include_start_m ? 'M ${prev_svg.x} ${prev_svg.y} ' : '') +
      'C ${c1.x} ${c1.y} ${c2.x} ${c2.y} ${next_svg.x} ${next_svg.y}';

  return path;
}

Future<int> ask_for_length(String title,
    {required int current_length,
    required int lower_bound,
    required DialogType dialog_type,
    String tooltip = ""}) async {
  int length_idx = 0;
  var items = util.FixedList<DialogItem>(1);
  items[length_idx] = DialogInteger(
    label: 'new length:',
    value: current_length,
    tooltip: tooltip,
  );
  var dialog = Dialog(
    title: title,
    type: dialog_type,
    items: items,
    use_saved_response: false,
  );

  List<DialogItem>? results = await util.dialog(dialog);
  if (results == null) return current_length;

  int length = (results[length_idx] as DialogInteger).value;
  if (length < lower_bound) {
    window.alert('length must be at least ${lower_bound}, but you entered $length');
    return current_length;
  }

  return length;
}
