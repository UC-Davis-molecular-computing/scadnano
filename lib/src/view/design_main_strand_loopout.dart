import 'dart:html';
import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:color/color.dart';
import 'package:over_react/over_react.dart';
import 'package:scadnano/src/state/context_menu.dart';

import 'package:scadnano/src/state/edit_mode.dart';
import 'package:scadnano/src/state/helix.dart';
import 'package:scadnano/src/state/mouseover_data.dart';
import 'package:scadnano/src/state/select_mode.dart';
import 'package:scadnano/src/state/strand.dart';
import 'package:scadnano/src/view/edit_mode_queryable.dart';
import 'package:smart_dialogs/smart_dialogs.dart';
import '../state/domain.dart';
import '../state/loopout.dart';
import '../app.dart';
import '../util.dart' as util;
import '../constants.dart' as constants;
import 'design_main_strand_paths.dart';
import '../actions/actions.dart' as actions;
import 'edit_mode_queryable.dart';

part 'design_main_strand_loopout.over_react.g.dart';

//UiFactory<DesignMainLoopoutProps> ConnectedDesignMainLoopout =
//    connect<AppState, DesignMainLoopoutProps>(mapStateToPropsWithOwnProps: (state, props) {
//  bool selected = state.ui_state.selectables_store.selected(props.loopout);
//  bool selectable = state.ui_state.select_mode_state.modes.contains(SelectModeChoice.loopout);
//  var prev_ss = props.strand.substrands[props.loopout.prev_substrand_idx];
//  var next_ss = props.strand.substrands[props.loopout.next_substrand_idx];
//  return DesignMainLoopout()
//    ..selected = selected
//    ..selectable = selectable
//    ..edit_modes = state.ui_state.edit_modes
//    ..prev_substrand = prev_ss
//    ..next_substrand = next_ss;
//})(DesignMainLoopout);

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
}

class DesignMainLoopoutProps = UiProps with DesignMainLoopoutPropsMixin, EditModePropsMixin;

@State()
mixin DesignMainLoopoutState on UiState {
  // making this "local" state for the component (instead of storing in the global store)
  // skips wasteful actions and updating the state just to tell if the mouse is hovering over a loopout
  bool mouse_hover;
}

class DesignMainLoopoutComponent extends UiStatefulComponent2<DesignMainLoopoutProps, DesignMainLoopoutState>
    with PureComponentMixin {
  @override
  Map get initialState => (newState()..mouse_hover = false);

  @override
  render() {
    Color color = props.color;

    bool mouse_hover = state.mouse_hover;

    var classname = constants.css_selector_loopout;
    if (props.selected) {
      classname += ' ' + constants.css_selector_selected;
    }
    if (props.strand.is_scaffold) {
      classname += ' ' + constants.css_selector_scaffold;
    }

    if (mouse_hover) {
      update_mouseover_loopout();
    }

    String tooltip = 'loopout: length ${props.loopout.loopout_length}';

    return _hairpin_arc(classname, color, tooltip);

//    if (util.is_hairpin(prev_ss, next_ss)) {
//      // special case for hairpin so it's not a short straight line
//      return _hairpin_arc(
//          prev_ss, next_ss, props.prev_helix, props.next_helix, loopout, classname, color, tooltip);
//    } else {
//      String path = crossover_path_description(prev_ss, next_ss, props.helices);
//      String id = loopout.id();
//
//      //XXX: need to use onPointerDown instead of onMouseDown because of the dnd Dart library:
//      // https://github.com/marcojakob/dart-dnd/issues/27
//      // perhaps not implemented by Safari though:
//      // https://love2dev.com/blog/chrome-has-decided-to-implement-pointer-events-and-the-web-rejoices/
//      return (Dom.path()
//        ..d = path
//        ..stroke = color.toHexColor().toCssString()
//        ..onMouseEnter = (ev) {
//          setState(newState()..mouse_hover = true);
//          if (show_mouseover_rect) {
//            update_mouseover_loopout();
//          }
//        }
//        ..onMouseLeave = ((_) {
//          setState(newState()..mouse_hover = false);
//          if (show_mouseover_rect) {
//            update_mouseover_loopout();
//          }
//        })
//        ..onPointerDown = ((ev) {
//          if (select_mode && props.selectable) {
//            loopout.handle_selection_mouse_down(ev.nativeEvent);
//          }
//        })
//        ..onPointerUp = ((ev) {
//          if (select_mode && props.selectable) {
//            loopout.handle_selection_mouse_up(ev.nativeEvent);
//          }
//        })
//        ..className = classname
//        ..id = id
//        ..key = id)(Dom.svgTitle()(tooltip));
//    }
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

  ReactElement _hairpin_arc(String classname, Color color, String tooltip) {
    Helix top_helix = props.prev_helix;
    Helix bot_helix = props.next_helix;
    Domain top_dom = props.prev_domain;
    Domain bot_dom = props.next_domain;
    if (top_helix.idx == bot_helix.idx) {
      top_helix = bot_helix = props.next_helix;
      if (!props.prev_domain.forward) {
        top_dom = props.next_domain;
        bot_dom = props.prev_domain;
      }
    } else if (top_helix.svg_position.y > bot_helix.svg_position.y) {
      top_helix = props.next_helix;
      bot_helix = props.prev_helix;
      top_dom = props.next_domain;
      bot_dom = props.prev_domain;
    }
    bool top_dom_is_prev = top_dom == props.prev_domain;

    int top_offset = top_dom_is_prev ? top_dom.offset_3p : top_dom.offset_5p;
    int bot_offset = top_dom_is_prev ? bot_dom.offset_5p : bot_dom.offset_3p;
    int prev_offset = top_dom_is_prev ? top_offset : bot_offset;
    int next_offset = top_dom_is_prev ? bot_offset : top_offset;

//    var top_svg = top_helix.svg_base_pos(top_offset, top_ss.forward);
//    var bot_svg = bot_helix.svg_base_pos(bot_offset, bot_ss.forward);
    var prev_svg = props.prev_helix.svg_base_pos(prev_offset, props.prev_domain.forward);
    var next_svg = props.next_helix.svg_base_pos(next_offset, props.next_domain.forward);

    var w, h;

    if (top_helix.idx == bot_helix.idx) {
      w = 1.5 * util.sigmoid(props.loopout.loopout_length - 1) * constants.BASE_WIDTH_SVG;
      h = 10 * util.sigmoid(props.loopout.loopout_length - 5) * constants.BASE_HEIGHT_SVG;
    } else {
      w = 2 * util.sigmoid(props.loopout.loopout_length) * constants.BASE_WIDTH_SVG;
      h = 10 * util.sigmoid(props.loopout.loopout_length - 3) * constants.BASE_HEIGHT_SVG;
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
//    if (top_ss == props.prev_substrand) {
//      y_offset1 = top_svg.y - h;
//      y_offset2 = bot_svg.y + h;
//      if (top_offset == top_ss.end - 1) {
//        x_offset1 = top_svg.x + w;
//        x_offset2 = bot_svg.x + w;
//      } else {
//        x_offset1 = top_svg.x - w;
//        x_offset2 = bot_svg.x - w;
//      }
//    } else {
//      y_offset2 = top_svg.y - h;
//      y_offset1 = bot_svg.y + h;
//      if (top_offset == top_ss.end - 1) {
//        x_offset2 = top_svg.x + w;
//        x_offset1 = bot_svg.x + w;
//      } else {
//        x_offset2 = top_svg.x - w;
//        x_offset1 = bot_svg.x - w;
//      }
//    }

    var c1 = Point<num>(x_offset1, y_offset1);
    var c2 = Point<num>(x_offset2, y_offset2);

    String id = props.loopout.id();
    return (Dom.path()
      ..className = classname
      ..stroke = color.toHexColor().toCssString()
      ..d = 'M ${prev_svg.x} ${prev_svg.y} C ${c1.x} ${c1.y} ${c2.x} ${c2.y} ${next_svg.x} ${next_svg.y}'
      ..onMouseEnter = (ev) {
        setState(newState()..mouse_hover = true);
        update_mouseover_loopout();
      }
      ..onMouseLeave = ((_) {
        setState(newState()..mouse_hover = false);
        update_mouseover_loopout();
      })
      ..onPointerDown = ((ev) => props.loopout.handle_selection_mouse_down(ev.nativeEvent))
      ..onPointerUp = ((ev) => props.loopout.handle_selection_mouse_up(ev.nativeEvent))
      ..key = id
      ..id = id)(Dom.svgTitle()(tooltip));
  }
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
