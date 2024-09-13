import 'dart:html';

import 'package:built_collection/built_collection.dart';
import 'package:over_react/over_react.dart';
import 'package:react/react.dart' as react;

import '../state/context_menu.dart';
import '../state/geometry.dart';
import '../state/edit_mode.dart';
import '../state/mouseover_data.dart';
import '../state/helix.dart';
import '../app.dart';
import 'pure_component.dart';
import '../actions/actions.dart' as actions;
import '../constants.dart' as constants;
import '../util.dart' as util;
import 'helix_context_menu.dart';

part 'design_main_helix.over_react.g.dart';

UiFactory<DesignMainHelixProps> DesignMainHelix = _$DesignMainHelix;

mixin DesignMainHelixProps on UiProps {
  late Helix helix;
  late bool selected;
  late double major_tick_offset_font_size;
  late double major_tick_width_font_size;
  late bool helix_change_apply_to_all;
  late bool show_dna;
  late bool show_domain_labels;
  late bool display_base_offsets_of_major_ticks;
  late bool display_major_tick_widths;
  late bool show_helix_circles;
  late Point<double> helix_svg_position;
}

class DesignMainHelixComponent extends UiComponent2<DesignMainHelixProps> with PureComponent {
  String group_id() => 'helix-main-view-${props.helix.idx}';

  @override
  render() {
    Geometry geometry = props.helix.geometry;

    // for helix circles
    var cx = -(2 * geometry.base_width_svg + geometry.distance_between_helices_svg / 2);
    var cy = props.helix_svg_position.y + props.helix.svg_height / 2.0;

    // for helix horizontal lines
    num width = props.helix.svg_width;
    num height = props.helix.svg_height;

    var horz_line_paths = _horz_line_paths(props.helix, props.helix_svg_position.y);
    var vert_line_paths = _vert_line_paths(props.helix, props.helix_svg_position.y);
    int idx = props.helix.idx;

    return (Dom.g()
      ..id = group_id()
      ..className = 'helix-main-view')([
      if (props.show_helix_circles)
        (Dom.circle()
          ..className = 'main-view-helix-circle ' + (props.selected ? "selected" : "")
          ..onClick = ((e) => this._handle_click(e, props.helix))
          ..id = helix_circle_id()
          ..cx = '$cx'
          ..cy = '$cy'
          ..r = '${geometry.helix_radius_svg}'
          ..key = 'main-view-helix-circle')(), //Dom.svgTitle()(tooltip_helix_length_adjust)),
      if (props.show_helix_circles)
        (Dom.text()
          ..className = 'main-view-helix-text'
          ..onClick = ((e) => this._handle_click(e, props.helix))
          ..id = helix_text_id()
          ..x = '$cx'
          ..y = '$cy'
          ..key = 'main-view-helix-text')('$idx'), //, Dom.svgTitle()(tooltip_helix_length_adjust)),
      (Dom.g()
        ..className = 'helix-lines-group'
        ..key = 'helix-lines-group')(
        (Dom.path()
          ..className = 'helix-lines helix-horz-line'
          ..d = horz_line_paths)(),
        (Dom.path()
          ..className = 'helix-lines helix-vert-minor-line'
          ..d = vert_line_paths['minor'])(),
        (Dom.path()
          ..className = 'helix-lines helix-vert-major-line'
          ..d = vert_line_paths['major'])(),
      ),
      if (props.display_base_offsets_of_major_ticks) _major_tick_offsets_svg_group(),
      if (props.display_major_tick_widths) _major_tick_widths_svg_group(),
//      if (props.strand_create_enabled)
      (Dom.rect()
//          ..onClick = start_strand_create
        ..onPointerDown = (react.SyntheticPointerEvent event_syn) {
          // start creating a strand, but only if we are not currently creating a crossover
          if (app.state.ui_state.edit_modes.contains(EditModeChoice.pencil) &&
              !app.state.ui_state.drawing_potential_crossover) {
            MouseEvent event = event_syn.nativeEvent;
            if (event.button != constants.LEFT_CLICK_BUTTON) return;
            var group = app.state.design.groups[props.helix.group]!;
            var helix_svg_position = app.state.helix_idx_to_svg_position_map[props.helix.idx]!;
            var address = util.get_address_on_helix(event, props.helix, group, geometry, helix_svg_position);
            app.dispatch(actions.StrandCreateStart(address: address, color: util.color_cycler.next()));
          }
        }
        ..onMouseLeave = ((_) => util.mouse_leave_update_mouseover())
        //XXX: it matters that we reference props.mouseover_datas, not a local variable
        // this ensures that when subsequent mouse events happen, the most recent mouseover_datas is examined,
        // otherwise the callback is not updated until render executes again
        ..onMouseEnter = ((event) => util.update_mouseover(
            event, props.helix, app.state.helix_idx_to_svg_position_map[props.helix.idx]!))
        ..onMouseMove = ((event) => util.update_mouseover(
            event, props.helix, app.state.helix_idx_to_svg_position_map[props.helix.idx]!))
        ..x = props.helix_svg_position.x
        ..y = props.helix_svg_position.y
        ..width = '$width'
        ..height = '$height'
        ..className = 'helix-invisible-rect'
        ..key = 'helix-invisible-rect')(),
    ]);
  }

  // needed for capturing right-click events with React:
  // https://medium.com/@ericclemmons/react-event-preventdefault-78c28c950e46
  @override
  componentDidMount() {
    if (props.show_helix_circles) {
      var elt = querySelector('#${group_id()}')!;
      elt.addEventListener('contextmenu', on_context_menu);
    }
  }

  @override
  componentWillUnmount() {
    if (props.show_helix_circles) {
      var elt = querySelector('#${group_id()}')!;
      elt.removeEventListener('contextmenu', on_context_menu);
    }
    super.componentWillUnmount();
  }

  on_context_menu(Event ev) {
    MouseEvent event = ev as MouseEvent;
    if (!event.shiftKey) {
      event.preventDefault();
      app.dispatch(actions.ContextMenuShow(
          context_menu: ContextMenu(
              items: context_menu_helix(props.helix, props.helix_change_apply_to_all),
              position: util.from_point_num(event.page))));
    }
  }

  String helix_circle_id() => 'main-view-helix-circle-${props.helix.idx}';

  String helix_text_id() => 'main-view-helix-text-${props.helix.idx}';

  final num DISTANCE_OFFSET_DISPLAY_FROM_HELIX = 3;

  _major_tick_offsets_svg_group() {
    BuiltList<int> major_ticks = props.helix.calculate_major_ticks;

    // offset if DNA sequences and/or domain labels are present
    num offset = 0;
    if (props.show_dna) {
      offset += props.helix.geometry.base_height_svg;
    }
    if (props.show_domain_labels) {
      offset += 1.2 * props.helix.geometry.base_height_svg;
    }
    num y = props.helix_svg_position.y - (DISTANCE_OFFSET_DISPLAY_FROM_HELIX + offset);

    var offset_texts_elements = [];
    for (int offset in major_ticks) {
      var x = (offset + 0.5) * props.helix.geometry.base_width_svg;
      var text_element = (Dom.text()
        ..className = 'main-view-helix-major-tick-offset-text'
        ..x = '$x'
        ..y = '$y'
        ..fontSize = '${props.major_tick_offset_font_size}'
        ..dominantBaseline = 'baseline'
        ..textAnchor = 'middle'
        ..key = 'main-view-helix-major-tick-offset-$x')(offset);

      offset_texts_elements.add(text_element);
    }

    return (Dom.g()
      ..className = 'major-tick-offsets-group'
      ..key = 'major-tick-offsets-group')(offset_texts_elements);
  }

  _major_tick_widths_svg_group() {
    BuiltList<int> major_ticks = props.helix.calculate_major_ticks;

    // offset if DNA sequences and/or domain labels are present
    num offset = 0;
    if (props.show_dna) {
      offset += props.helix.geometry.base_height_svg;
    }
    if (props.show_domain_labels) {
      offset += props.helix.geometry.base_height_svg;
    }
    num y = props.helix_svg_position.y + props.helix.svg_height + DISTANCE_OFFSET_DISPLAY_FROM_HELIX + offset;

    var offset_texts_elements = [];
    Map<num, int> map_offset_to_distance = {};
    for (var i = 0; i + 1 < major_ticks.length; i++) {
      var left_base_offset = major_ticks[i];
      var right_base_offset = major_ticks[i + 1];
      var distance = right_base_offset - left_base_offset;
      var offset = (right_base_offset + left_base_offset) / 2;

      map_offset_to_distance[offset] = distance;
    }

    for (var entry in map_offset_to_distance.entries) {
      var base = entry.key;
      var distance = entry.value;

      var x = props.helix_svg_position.x + base * props.helix.geometry.base_width_svg;
      var text_element = (Dom.text()
        ..className = 'main-view-helix-major-tick-distance-text'
        ..x = '$x'
        ..y = '$y'
        ..fontSize = '${props.major_tick_width_font_size}'
        ..dominantBaseline = 'hanging'
        ..textAnchor = 'middle'
        ..key = 'main-view-helix-major-tick-distance-$x')(distance);
      offset_texts_elements.addAll([text_element]);
    }

    return (Dom.g()
      ..className = 'major-tick-widths-group'
      ..key = 'major-tick-widths-group')(offset_texts_elements);
  }

  String _horz_line_paths(Helix helix, num helix_svg_position_y) {
    num width = helix.svg_width;
    num height = helix.svg_height;
    num x_start = helix.min_offset * props.helix.geometry.base_width_svg;
    num x_end = x_start + width;
    num y_start = helix_svg_position_y;
    num y_mid = y_start + height / 2.0;
    num y_end = y_start + height;

    return 'M $x_start $y_start '
        'H $x_end '
        'M $x_start $y_mid '
        'H $x_end '
        'M $x_start $y_end '
        'H $x_end';
  }

  /// Return Map {'minor': thin_lines, 'major': thick_lines} to paths describing minor and major vertical lines.
  Map<String, String> _vert_line_paths(Helix helix, num helix_svg_position_y) {
    BuiltList<int> major_ticks = helix.calculate_major_ticks;

    List<String> path_cmds_vert_minor = [];
    List<String> path_cmds_vert_major = [];

    num y = helix_svg_position_y;

    for (int base = helix.min_offset; base <= helix.max_offset; base++) {
      var base_minus_min_offset = base; // - helix.min_offset;
      var x = base_minus_min_offset * props.helix.geometry.base_width_svg;
      var path_cmds = major_ticks.contains(base) ? path_cmds_vert_major : path_cmds_vert_minor;
      path_cmds.add('M $x $y');
      path_cmds.add('v ${helix.svg_height}');
      x += props.helix.geometry.base_width_svg;
    }

    return {'minor': path_cmds_vert_minor.join(' '), 'major': path_cmds_vert_major.join(' ')};
  }

  _handle_click(SyntheticMouseEvent event, Helix helix) {
    if (event.shiftKey) {
      app.dispatch(actions.HelixSelect(helix.idx, false));
    } else if (event.ctrlKey || event.metaKey) {
      app.dispatch(actions.HelixSelect(helix.idx, true));
    }
  }
}
