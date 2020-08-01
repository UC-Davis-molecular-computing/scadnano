import 'dart:html';
import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:color/color.dart';
import 'package:over_react/over_react.dart';
import 'package:smart_dialogs/smart_dialogs.dart';

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
import '../util.dart' as util;
import '../constants.dart' as constants;
import 'pure_component.dart';
import '../actions/actions.dart' as actions;

part 'design_main_strand_loopout.over_react.g.dart';

@Factory()
UiFactory<DesignMainLoopoutProps> DesignMainLoopout = _$DesignMainLoopout;

@Props()
mixin DesignMainLoopoutPropsMixin on UiProps {
  Loopout loopout;
  Strand strand;
  Color color;

  Domain prev_domain;
  Domain next_domain;
  Helix prev_helix;
  Helix next_helix;
  bool selected;
  BuiltSet<EditModeChoice> edit_modes;

  BuiltMap<int, Helix> helices;
  BuiltMap<String, HelixGroup> groups;
  Geometry geometry;
}

class DesignMainLoopoutProps = UiProps with DesignMainLoopoutPropsMixin, TransformByHelixGroupPropsMixin;

@State()
mixin DesignMainLoopoutState on UiState {
  // making this "local" state for the component (instead of storing in the global store)
  // skips wasteful actions and updating the state just to tell if the mouse is hovering over a loopout
  bool mouse_hover;
}

class DesignMainLoopoutComponent extends UiStatefulComponent2<DesignMainLoopoutProps, DesignMainLoopoutState>
    with PureComponent, TransformByHelixGroup<DesignMainLoopoutProps> {
  @override
  Map get initialState => (newState()..mouse_hover = false);

  @override
  render() {
    Color color = props.color;

    var classname = constants.css_selector_loopout;
    if (props.selected) {
      classname += ' ' + constants.css_selector_selected;
    }
    if (props.strand.is_scaffold) {
      classname += ' ' + constants.css_selector_scaffold;
    }

    //XXX: commented out for same reason as similar commented code in design_main_strand_crossover.dart
//    if (mouse_hover) {
//      update_mouseover_loopout();
//    }

    String tooltip = 'loopout: length ${props.loopout.loopout_length}';

    bool within_group = props.prev_helix.group == props.next_helix.group;
    String path_description;

    if (within_group) {
      path_description = loopout_path_description_within_group(
          props.prev_helix, props.next_helix, props.prev_domain, props.next_domain, props.loopout, true);
    } else {
      path_description = loopout_path_description_between_groups();
    }

    var path_props = Dom.path()
      ..className = classname
      ..stroke = color.toHexColor().toCssString()
      ..d = path_description
      ..onMouseEnter = (ev) {
        setState(newState()..mouse_hover = true);
        if (edit_mode_is_backbone()) {
          update_mouseover_loopout();
        }
      }
      ..onMouseLeave = ((_) {
        setState(newState()..mouse_hover = false);
        if (edit_mode_is_backbone()) {
          update_mouseover_loopout();
        }
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
      ..key = props.loopout.id()
      ..id = props.loopout.id();

    if (within_group) {
      path_props.transform = transform_of_helix(props.prev_helix.idx);
    }

    return path_props(Dom.svgTitle()(tooltip));
  }

  @override
  componentDidMount() {
    var element = querySelector('#${props.loopout.id()}');
    element.addEventListener('contextmenu', on_context_menu);
  }

  @override
  componentWillUnmount() {
    var element = querySelector('#${props.loopout.id()}');
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
        ContextMenuItem(
          title: 'change loopout length',
          on_click: loopout_length_change,
        ),
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
        current_length: props.loopout.loopout_length,
        lower_bound: 0));
    if (new_length == null || new_length == props.loopout.loopout_length) {
      return;
    }
    app.dispatch(actions.LoopoutLengthChange(props.loopout, new_length));
  }

  String loopout_path_description_between_groups() {
    int prev_offset = props.prev_domain.dnaend_3p.offset_inclusive;
    int next_offset = props.next_domain.dnaend_5p.offset_inclusive;

    var prev_group = props.groups[props.prev_helix.group];
    var next_group = props.groups[props.next_helix.group];

    var prev_svg_untransformed = props.prev_helix.svg_base_pos(prev_offset, props.prev_domain.forward);
    var next_svg_untransformed = props.next_helix.svg_base_pos(next_offset, props.next_domain.forward);

    var prev_svg = prev_group.transform_point_main_view(prev_svg_untransformed, props.geometry);
    var next_svg = next_group.transform_point_main_view(next_svg_untransformed, props.geometry);

    var w = 2 * util.sigmoid(props.loopout.loopout_length) * constants.BASE_WIDTH_SVG;
    var h = 10 * util.sigmoid(props.loopout.loopout_length - 3) * constants.BASE_HEIGHT_SVG;

    // un-rotated
    var prev_y_offset = prev_svg.y + h;
    var next_y_offset = next_svg.y - h;
    var prev_x_offset = prev_svg.x + w;
    var next_x_offset = next_svg.x + w;
    var prev_c_unrotated = Point<num>(prev_x_offset, prev_y_offset);
    var next_c_unrotated = Point<num>(next_x_offset, next_y_offset);

    // rotated
    var prev_c = util.rotate(prev_c_unrotated, prev_group.pitch, origin: prev_svg);
    var next_c = util.rotate(next_c_unrotated, next_group.pitch, origin: next_svg);

    var path = 'M ${prev_svg.x} ${prev_svg.y} '
        'C ${prev_c.x} ${prev_c.y} ${next_c.x} ${next_c.y} '
        '${next_svg.x} ${next_svg.y}';

    return path;
  }
}

// This is a function (not a Component method with access to props) so that DesignMainStrandMoving can
// call it also.
// The bool [include_start_M] indicates whether to start the path with a command like "M 0 1".
// When drawing a normal loopout this is needed, but when drawing a moving strand, where all path commands
// are concatenated together, it is not needed.
String loopout_path_description_within_group(Helix prev_helix, Helix next_helix, Domain prev_domain,
    Domain next_domain, Loopout loopout, bool include_start_M) {
  Helix top_helix = prev_helix;
  Helix bot_helix = next_helix;
  Domain top_dom = prev_domain;
  Domain bot_dom = next_domain;
  if (top_helix.idx == bot_helix.idx) {
    top_helix = bot_helix = next_helix;
    if (!prev_domain.forward) {
      top_dom = next_domain;
      bot_dom = prev_domain;
    }
  } else if (top_helix.svg_position.y > bot_helix.svg_position.y) {
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

  var prev_svg = prev_helix.svg_base_pos(prev_offset, prev_domain.forward);
  var next_svg = next_helix.svg_base_pos(next_offset, next_domain.forward);

  var w, h;

  if (top_helix.idx == bot_helix.idx) {
    w = 1.5 * util.sigmoid(loopout.loopout_length - 1) * constants.BASE_WIDTH_SVG;
    h = 10 * util.sigmoid(loopout.loopout_length - 5) * constants.BASE_HEIGHT_SVG;
  } else {
    w = 2 * util.sigmoid(loopout.loopout_length) * constants.BASE_WIDTH_SVG;
    h = 10 * util.sigmoid(loopout.loopout_length - 3) * constants.BASE_HEIGHT_SVG;
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

  var c1 = Point<num>(x_offset1, y_offset1);
  var c2 = Point<num>(x_offset2, y_offset2);

  var path = (include_start_M ? 'M ${prev_svg.x} ${prev_svg.y} ' : '') +
      'C ${c1.x} ${c1.y} ${c2.x} ${c2.y} ${next_svg.x} ${next_svg.y}';

  return path;
}

Future<int> ask_for_length(String title, {int current_length, int lower_bound}) async {
  // https://pub.dev/documentation/smart_dialogs/latest/smart_dialogs/Info/get.html
  String buttontype = DiaAttr.CHECKBOX;
  String htmlTitleText = title;
  List<String> textLabels = ['new length:'];
  List<List<String>> comboInfo = null;
  List<String> defaultInputTexts = ['${current_length}'];
  List<int> widths = [1];
  List<String> isChecked = null;
  bool alternateRowColor = false;
  List<String> buttonLabels = ['OK', 'Cancel'];

  UserInput result = await Info.get(buttontype, htmlTitleText, textLabels, comboInfo, defaultInputTexts,
      widths, isChecked, alternateRowColor, buttonLabels);

  if (result.buttonCode != 'DIA_ACT_OK') {
    return null;
  }

  String length_str = result.getUserInput(0)[0];
  int length = int.tryParse(length_str);
  if (length == null) {
    Info.show('"$length_str" is not a valid integer');
    return null;
  } else if (length < lower_bound) {
    Info.show('length must be at least ${lower_bound}, but it is $length_str');
    return null;
  }

  return length;
}
