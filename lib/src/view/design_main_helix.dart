import 'dart:html';
import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:quiver/iterables.dart' as iter;
import 'package:over_react/over_react.dart';
import 'package:react/react.dart' as react;
import 'package:react/react_client.dart';

import '../state/context_menu.dart';
import '../state/geometry.dart';
import '../state/edit_mode.dart';
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
  Helix helix;
  int view_order;
  bool strand_create_enabled;
  num major_tick_offset_font_size;
  num major_tick_width_font_size;
  bool helix_change_apply_to_all;
  bool show_dna;
  bool display_base_offsets_of_major_ticks;
  bool display_major_tick_widths;
  bool show_helix_circles;
}

class DesignMainHelixComponent extends UiComponent2<DesignMainHelixProps> with PureComponent {
  String group_id() => 'helix-main-view-${props.helix.idx}';

  @override
  render() {
    Geometry geometry = props.helix.geometry;

    // for helix circles
    var cx = -(2 * geometry.base_width_svg + geometry.distance_between_helices_svg / 2);
    var cy = props.helix.svg_position.y + props.helix.svg_height() / 2.0;

    // for helix horizontal lines
    num width = props.helix.svg_width();
    num height = props.helix.svg_height();

    var horz_line_paths = _horz_line_paths(props.helix);
    var vert_line_paths = _vert_line_paths(props.helix);
    int idx = props.helix.idx;

    return (Dom.g()
      ..id = group_id()
      ..className = 'helix-main-view')([
      if (props.show_helix_circles)
        (Dom.circle()
          ..className = 'main-view-helix-circle'
          ..id = helix_circle_id()
          ..cx = '$cx'
          ..cy = '$cy'
          ..r = '${geometry.helix_radius_svg}'
          ..key = 'main-view-helix-circle')(), //Dom.svgTitle()(tooltip_helix_length_adjust)),
      if (props.show_helix_circles)
        (Dom.text()
          ..className = 'main-view-helix-text'
          ..id = helix_text_id()
          ..x = '$cx'
          ..y = '$cy'
          ..key = 'main-view-helix-text')('$idx'), //, Dom.svgTitle()(tooltip_helix_length_adjust)),
      (Dom.g()
        ..className = 'helix-lines-group'
        ..key = 'helix-lines-group')(
        (Dom.path()
          ..className = 'helix-lines helix-horz-line'
          ..d = horz_line_paths
          ..key = 'helix-horz-lines')(),
        (Dom.path()
          ..className = 'helix-lines helix-vert-minor-line'
          ..d = vert_line_paths['minor']
          ..key = 'helix-vert-minor-lines')(),
        (Dom.path()
          ..className = 'helix-lines helix-vert-major-line'
          ..d = vert_line_paths['major']
          ..key = 'helix-vert-major-lines')(),
      ),
      if (props.display_base_offsets_of_major_ticks)
        _major_tick_offsets_svg_group(),
      if (props.display_major_tick_widths)
        _major_tick_widths_svg_group(),
//      if (props.strand_create_enabled)
      (Dom.rect()
//          ..onClick = start_strand_create
        ..onPointerDown = (react.SyntheticPointerEvent event_syn) {
          if (app.state.ui_state.edit_modes.contains(EditModeChoice.pencil)) {
            MouseEvent event = event_syn.nativeEvent;
            if (event.button != constants.LEFT_CLICK_BUTTON) return;
            var group = app.state.design.groups[props.helix.group];
            var address = util.get_address_on_helix(event, props.helix, group, geometry);
            app.dispatch(actions.StrandCreateStart(address: address, color: util.color_cycler.next()));
          }
        }
        ..x = props.helix.svg_position.x
        ..y = props.helix.svg_position.y
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
      var elt = querySelector('#${group_id()}');
      elt.addEventListener('contextmenu', on_context_menu);
    }
  }

  @override
  componentWillUnmount() {
    if (props.show_helix_circles) {
      var elt = querySelector('#${group_id()}');
      elt.removeEventListener('contextmenu', on_context_menu);
    }
    super.componentWillUnmount();
  }

  on_context_menu(Event ev) {
    MouseEvent event = ev;
    if (!event.shiftKey) {
      event.preventDefault();
      app.dispatch(actions.ContextMenuShow(
          context_menu: ContextMenu(
              items: context_menu_helix(props.helix, props.helix_change_apply_to_all).build(),
              position: event.page)));
    }
  }

  String helix_circle_id() => 'main-view-helix-circle-${props.helix.idx}';

  String helix_text_id() => 'main-view-helix-text-${props.helix.idx}';

  final num DISTANCE_OFFSET_DISPLAY_FROM_HELIX = 3;

  _major_tick_offsets_svg_group() {
    List<int> major_ticks = props.helix.calculate_major_ticks();

//    var y = -DISTANCE_OFFSET_DISPLAY_FROM_HELIX - (props.show_dna ? constants.BASE_HEIGHT_SVG : 0);

    num y = props.helix.svg_position.y -
        (DISTANCE_OFFSET_DISPLAY_FROM_HELIX + (props.show_dna ? props.helix.geometry.base_height_svg : 0));

    var offset_texts_elements = [];
    for (int offset in major_ticks) {
      var x = (offset + 0.5) * props.helix.geometry.base_width_svg;
//      Point<num> pos = helix.svg_base_pos(offset, true);
//      num x = pos.x;
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
    List<int> major_ticks = props.helix.calculate_major_ticks();

    num y = props.helix.svg_position.y +
        props.helix.svg_height() +
        DISTANCE_OFFSET_DISPLAY_FROM_HELIX +
        (props.show_dna ? props.helix.geometry.base_height_svg : 0);

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

      var x = props.helix.svg_position.x + base * props.helix.geometry.base_width_svg;
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

  String _horz_line_paths(Helix helix) {
    num width = helix.svg_width();
    num height = helix.svg_height();
    num x_start = helix.svg_position.x;
    num x_end = x_start + width;
    num y_start = helix.svg_position.y;
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
  Map<String, String> _vert_line_paths(Helix helix) {
    List<int> major_ticks = helix.calculate_major_ticks();
//  var major_tick_distance =
//      helix.has_major_tick_distance() ? helix.major_tick_distance : design_major_tick_distance;
//  Set<int> major_ticks = (helix.has_major_ticks()
//          ? helix.major_ticks
//          : regularly_spaced_ticks(major_tick_distance, helix.min_offset, helix.max_offset))
//      .toSet();

    List<String> path_cmds_vert_minor = [];
    List<String> path_cmds_vert_major = [];

    num y = helix.svg_position.y;

    for (int base = helix.min_offset; base <= helix.max_offset; base++) {
      var base_minus_min_offset = base; // - helix.min_offset;
      var x = base_minus_min_offset * props.helix.geometry.base_width_svg;
      var path_cmds = major_ticks.contains(base) ? path_cmds_vert_major : path_cmds_vert_minor;
      path_cmds.add('M $x $y');
      path_cmds.add('v ${helix.svg_height()}');
      x += props.helix.geometry.base_width_svg;
    }

    return {'minor': path_cmds_vert_minor.join(' '), 'major': path_cmds_vert_major.join(' ')};
  }
}

Point<num> helix_main_view_translation(Helix helix) {
  return helix.svg_position;
}

List<int> regularly_spaced_ticks(int distance, int start, int end) {
  if (distance == null || distance == 0) {
    return [];
  } else if (distance < 0) {
    throw ArgumentError('distance between major ticks must be positive');
  } else {
    return [for (int offset in iter.range(start, end + 1, distance)) offset];
  }
}
