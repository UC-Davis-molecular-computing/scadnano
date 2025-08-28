import 'dart:html';

import 'package:color/color.dart';
import 'package:over_react/over_react.dart';
import 'package:built_collection/built_collection.dart';
import 'package:platform_detect/platform_detect.dart';
import 'package:scadnano/src/state/context_menu.dart';
import 'package:scadnano/src/state/dialog.dart';
import 'package:scadnano/src/state/geometry.dart';

import '../state/selectable.dart';
import '../state/helix.dart';
import '../app.dart';
import '../state/domain.dart';
import 'pure_component.dart';
import '../util.dart' as util;
import '../constants.dart' as constants;
import '../actions/actions.dart' as actions;
import 'design_main_strand_loopout.dart';

part 'design_main_strand_insertion.over_react.g.dart';

typedef (Insertion, Domain) PairedInsertionFinder(Insertion insertion, Domain substrand);

UiFactory<DesignMainStrandInsertionProps> DesignMainStrandInsertion = _$DesignMainStrandInsertion;

mixin DesignMainStrandInsertionProps on UiProps {
  late SelectableInsertion selectable_insertion;
  late Helix helix;
  late String transform;
  late Color color;
  late bool selected;
  late bool display_reverse_DNA_right_side_up;
  late double svg_position_y;

  late bool retain_strand_color_on_selection;
  late Geometry geometry;
}

class DesignMainStrandInsertionComponent extends UiComponent2<DesignMainStrandInsertionProps>
    with PureComponent {
  Insertion get insertion => props.selectable_insertion.insertion;

  Domain get domain => props.selectable_insertion.domain;

  @override
  render() {
    var classname = constants.css_selector_insertion_group;
    if (props.selected) {
      if (props.retain_strand_color_on_selection) {
        classname += ' ' + constants.css_selector_selected;
      } else {
        classname += ' ' + constants.css_selector_selected_pink;
      }
    }
    if (props.selectable_insertion.is_scaffold) {
      classname += ' ' + constants.css_selector_scaffold;
    }

    Point<double> pos = props.helix.svg_base_pos(
      this.insertion.offset,
      this.domain.forward,
      props.svg_position_y,
      props.geometry,
    );
    ReactElement insertion_background = _insertion_background(pos);
    ReactElement insertion_path = _insertion_path();
    ReactElement text_num_insertions = _text_number_of_insertions(pos);
    return (Dom.g()
      ..id = props.selectable_insertion.id_group
      ..className = classname
      ..onPointerDown = ((ev) {
        if (insertion_selectable(props.selectable_insertion)) {
          props.selectable_insertion.handle_selection_mouse_down(ev.nativeEvent);
        }
      })
      ..onPointerUp = ((ev) {
        if (insertion_selectable(props.selectable_insertion)) {
          props.selectable_insertion.handle_selection_mouse_up(ev.nativeEvent);
        }
      })
      ..transform = props.transform)(insertion_path, insertion_background, text_num_insertions);
  }

  ReactElement _insertion_path() {
    Geometry geometry = props.geometry;
    int offset = this.insertion.offset;
    Color color = props.color;

    Point<double> pos = props.helix.svg_base_pos(
      offset,
      this.domain.forward,
      props.svg_position_y,
      props.geometry,
    );

    num dx1 = geometry.base_width_svg;
    num dx2 = 0.5 * geometry.base_width_svg;
    if (props.display_reverse_DNA_right_side_up && !this.domain.forward) {
      dx1 = -dx1;
      dx2 = -dx2;
    }
    num dy1 = 2 * geometry.base_height_svg;
    num dy2 = 2 * geometry.base_height_svg;
    if (this.domain.forward) {
      dy1 = -dy1;
      dy2 = -dy2;
      dx1 = -dx1;
      dx2 = -dx2;
    }
    num x0 = pos.x;
    num y0 = pos.y;
    var x1 = (x0 + dx1).toStringAsFixed(2);
    var x2 = (x0 + dx2).toStringAsFixed(2);
    var x3 = x0.toStringAsFixed(2);
    var x4 = (x0 - dx2).toStringAsFixed(2);
    var x5 = (x0 - dx1).toStringAsFixed(2);

    var y1 = (y0 + dy1).toStringAsFixed(2);
    var y2 = (y0 + dy2).toStringAsFixed(2);

    //  String key = 'insertion-H${substrand.helix}-${offset}';
    ReactElement insertion_path =
        (Dom.path()
          // ..onClick = ((_) => change_insertion_length())
          ..className = constants.css_selector_insertion
          ..stroke = color.toHexColor().toCssString()
          ..fill = 'none'
          ..id =
              props
                  .selectable_insertion
                  .id // needed for SVG text to attach itself to path
          ..d =
              'M $x0 $y0 '
              'C $x1 $y1, $x2 $y2, $x3 $y2 '
              'C $x4 $y2, $x5 $y1, $x0 $y0 '
          ..key = props.selectable_insertion.id)();
    return insertion_path;
  }

  ReactElement _text_number_of_insertions(Point<double> pos) {
    Geometry geometry = props.geometry;
    int offset = this.insertion.offset;
    Insertion insertion = this.insertion;

    // write number of insertions inside insertion loop
    int length = insertion.length;

    var dy_text = '${0.2 * geometry.base_height_svg}';
    if (browser.isFirefox) {
      // le sigh
      dy_text = '${0.14 * geometry.base_height_svg}';
    }

    num background_width = geometry.base_width_svg;
    num background_height = 1.5 * geometry.base_height_svg;
    num background_x = pos.x - background_width / 2;
    num background_y = pos.y - geometry.base_height_svg / 2;
    if (this.domain.forward) {
      background_y -= background_height;
    } else {
      background_y += geometry.base_height_svg;
    }

    String key = 'num-insertion-H${this.domain.helix}-${offset}';
    SvgProps text_path_props =
        Dom.textPath()
          ..startOffset = '50%'
          //      ..href = '#${util.id_insertion(substrand, offset)}'
          ..xlinkHref = '#${props.selectable_insertion.id}'
          ..className = 'insertion-length';

    //    return (Dom.text()
    //      ..onClick = ((_) => change_insertion_length())
    //      ..dy = dy_text
    //      ..id = key
    //      ..key = key)(text_path_props('${length}'));

    return (Dom.g()..key = key)(
      (Dom.rect()
        ..x = background_x
        ..y = background_y
        ..width = background_width
        ..height = background_height
        ..className = 'insertion-background'
      // ..onClick = ((_) => change_insertion_length())
      )(),
      (Dom.text()
        // ..onClick = ((_) => change_insertion_length())
        ..dy = dy_text
      // ..id = props.selectable_insertion.id()
      )(text_path_props('${length}')),
    );
  }

  ReactElement _insertion_background(Point<double> pos) {
    Geometry geometry = props.geometry;
    String key_background = 'insertion-background-H${this.domain.helix}-${this.insertion.offset}';
    num background_width = geometry.base_width_svg;
    num background_height = geometry.base_height_svg;
    num background_x = pos.x - background_width / 2;
    num background_y = pos.y - background_height / 2;
    return (Dom.rect()
      ..className = 'insertion-background'
      ..x = background_x
      ..y = background_y
      ..width = background_width
      ..height = background_height
      ..onClick = (_) {
        if (edit_mode_is_insertion()) {
          app.dispatch(actions.InsertionRemove(domain: this.domain, insertion: this.insertion));
        }
      }
      ..key = key_background)();
  }

  @override
  componentDidMount() {
    var element = querySelector('#${props.selectable_insertion.id_group}')!;
    element.addEventListener('contextmenu', on_context_menu);
    super.componentDidMount();
  }

  @override
  componentWillUnmount() {
    var element = querySelector('#${props.selectable_insertion.id_group}')!;
    element.removeEventListener('contextmenu', on_context_menu);
    super.componentWillUnmount();
  }

  on_context_menu(Event ev) {
    MouseEvent event = ev as MouseEvent;
    if (!event.shiftKey) {
      event.preventDefault();
      event.stopPropagation(); // needed to prevent strand context menu from popping up
      app.dispatch(
        actions.ContextMenuShow(
          context_menu: ContextMenu(
            items: context_menu_insertion().build(),
            position: util.from_point_num(event.page),
          ),
        ),
      );
    }
  }

  List<ContextMenuItem> context_menu_insertion() => [
    ContextMenuItem(title: 'change insertion length', on_click: change_insertion_length),
  ];

  change_insertion_length() async {
    int new_length = await ask_for_length(
      'change insertion length',
      current_length: this.insertion.length,
      lower_bound: 1,
      dialog_type: DialogType.set_insertion_length,
      tooltip: """\
Changes the insertion length. 

Keep in mind that the insertion length is the number of *extra* bases.
So for example an insertion length of 1 would represent at that offset
2 total bases: the original base and the 1 extra base from the insertion.
""",
    );
    if (new_length == this.insertion.length) {
      return;
    }

    var selected_insertions = app.state.ui_state.selectables_store.selected_insertions;
    actions.UndoableAction action;
    if (selected_insertions.length > 0) {
      var insertions = [for (var selected_insertion in selected_insertions) selected_insertion.insertion];
      var domains = [for (var selected_insertion in selected_insertions) selected_insertion.domain];
      action = actions.InsertionsLengthChange(insertions: insertions, domains: domains, length: new_length);
    } else {
      action = actions.InsertionLengthChange(
        domain: this.domain,
        insertion: this.insertion,
        length: new_length,
      );
    }

    app.dispatch(action);
  }
}
