import 'dart:html';
import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:quiver/iterables.dart' as iter;
import 'package:over_react/over_react.dart';
import 'package:react/react.dart' as react;
import 'package:react/react_client.dart';

import '../state/context_menu.dart';
import '../state/dialog.dart';
import '../state/geometry.dart';
import '../state/grid.dart';
import '../state/grid_position.dart';
import '../state/position3d.dart';
import '../state/helix.dart';
import '../app.dart';
import '../actions/actions.dart' as actions;
import '../constants.dart' as constants;
import '../util.dart' as util;
import 'pure_component.dart';

part 'design_main_helix.over_react.g.dart';

UiFactory<DesignMainHelixProps> DesignMainHelix = _$DesignMainHelix;

mixin DesignMainHelixProps on UiProps {
  Helix helix;
  int view_order;
  bool strand_create_enabled;
  int design_major_tick_distance;
  num major_tick_offset_font_size;
  num major_tick_width_font_size;
  Grid grid;
  bool helix_change_apply_to_all;
  bool show_dna;
  bool display_base_offsets_of_major_ticks;
  bool display_major_tick_widths;
  Geometry geometry;
}

class DesignMainHelixComponent extends UiComponent2<DesignMainHelixProps> with PureComponent {
  @override
  render() {
    Helix helix = props.helix;
    Geometry geometry = props.geometry;

    // for helix circles
    var cx = -(2 * constants.BASE_WIDTH_SVG + geometry.distance_between_helices_main_svg / 2);
    var cy = helix.svg_height() / 2.0;

    // for helix horizontal lines
    num width = helix.svg_width();
    num height = helix.svg_height();

    num x_start = helix.min_offset * constants.BASE_WIDTH_SVG;

    var horz_line_paths = _horz_line_paths(helix);
    var vert_line_paths = _vert_line_paths(helix, props.design_major_tick_distance);
    int idx = helix.idx;

    Point<num> translation = helix_main_view_translation(helix);

    return (Dom.g()
      ..className = 'helix-main-view'
      ..transform = 'translate(${translation.x} ${translation.y})')([
      (Dom.circle()
        ..className = 'main-view-helix-circle'
        ..id = helix_circle_id()
        ..cx = '$cx'
        ..cy = '$cy'
        ..r = '${geometry.helix_radius_svg}'
        ..key = 'main-view-helix-circle')(), //Dom.svgTitle()(tooltip_helix_length_adjust)),
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
      if (props.strand_create_enabled)
        (Dom.rect()
//          ..onClick = start_strand_create
          ..onPointerDown = start_strand_create
          ..x = x_start
          ..y = '0'
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
    for (var id in [helix_circle_id(), helix_text_id()]) {
      var elt = querySelector('#${id}');
      elt.addEventListener('contextmenu', on_context_menu);
    }
  }

  @override
  componentWillUnmount() {
    for (var id in [helix_circle_id(), helix_text_id()]) {
      var elt = querySelector('#${id}');
      elt.removeEventListener('contextmenu', on_context_menu);
    }
  }

  on_context_menu(Event ev) {
    MouseEvent event = ev;
    if (!event.shiftKey) {
      event.preventDefault();
      app.dispatch(actions.ContextMenuShow(
          context_menu: ContextMenu(items: context_menu_helix(props.helix).build(), position: event.page)));
    }
  }

  start_strand_create(react.SyntheticPointerEvent event_syn) {
    MouseEvent event = event_syn.nativeEvent;
    if (event.button != constants.LEFT_CLICK_BUTTON) return;

    var address = util.get_address_on_helix(event, props.helix);
    app.dispatch(actions.StrandCreateStart(address: address, color: util.color_cycler.next()));
  }

  helix_adjust_length() {
    app.disable_keyboard_shortcuts_while(dialog_helix_adjust_length);
  }

  helix_adjust_major_tick_marks() {
    app.disable_keyboard_shortcuts_while(dialog_helix_adjust_major_tick_marks);
  }

  helix_adjust_roll() {
    app.disable_keyboard_shortcuts_while(dialog_helix_adjust_roll);
  }

  helix_adjust_position() {
    app.disable_keyboard_shortcuts_while(dialog_helix_adjust_position);
  }

  helix_adjust_grid_position() {
    app.disable_keyboard_shortcuts_while(dialog_helix_adjust_grid_position);
  }

  Future<void> dialog_helix_adjust_length() async {
    Helix helix = props.helix;
    int helix_idx = helix.idx;

    var dialog = Dialog(title: 'adjust helix length', items: [
      DialogNumber(label: 'minimum', value: helix.min_offset),
      DialogNumber(label: 'maximum', value: helix.max_offset),
      DialogCheckbox(label: 'apply to all helices', value: props.helix_change_apply_to_all),
    ]);
    List<DialogItem> results = await util.dialog(dialog);
    if (results == null) return;

    int min_offset = (results[0] as DialogNumber).value;
    int max_offset = (results[1] as DialogNumber).value;
    bool apply_to_all = (results[2] as DialogCheckbox).value;

    if (min_offset >= max_offset) {
      window.alert('minimum offset ${min_offset} must be strictly less than maximum offset, '
          'but maximum offset is ${max_offset}');
      return;
    }

    if (apply_to_all) {
      app.dispatch(actions.HelixOffsetChangeAll(min_offset: min_offset, max_offset: max_offset));
    } else {
      app.dispatch(
          actions.HelixOffsetChange(helix_idx: helix_idx, min_offset: min_offset, max_offset: max_offset));
    }
  }

  Future<void> dialog_helix_adjust_roll() async {
    Helix helix = props.helix;
    int helix_idx = helix.idx;

    var dialog = Dialog(title: 'adjust helix roll (degrees)', items: [
      DialogFloatingNumber(label: 'roll', value: helix.roll),
    ]);
    List<DialogItem> results = await util.dialog(dialog);
    if (results == null) return;

    double roll = (results[0] as DialogFloatingNumber).value;
    roll = roll % 360;

    app.dispatch(actions.HelixRollSet(helix_idx: helix_idx, roll: roll));
  }

  Future<void> dialog_helix_adjust_major_tick_marks() async {
    Helix helix = props.helix;
    int helix_idx = helix.idx;
    Grid grid = props.grid;

    var dialog = Dialog(title: 'adjust helix tick marks', items: [
      DialogCheckbox(label: 'regular spacing', value: helix.major_tick_distance != null),
      DialogNumber(
          label: 'regular distance', value: helix.major_tick_distance ?? grid.default_major_tick_distance()),
      DialogText(
          label: 'varying major tick distances (space-separated)',
          value: helix.major_ticks == null ? '' : util.deltas(helix.major_ticks).join(' ')),
      DialogCheckbox(label: 'apply to all', value: props.helix_change_apply_to_all),
    ], disable_when_on: {
      2: 0
    }, disable_when_off: {
      1: 0
    });

    List<DialogItem> results = await util.dialog(dialog);
    if (results == null) return;

    bool use_major_tick_distance = (results[0] as DialogCheckbox).value;
    int major_tick_distance = (results[1] as DialogNumber).value;
    List<String> major_ticks_str =
        (results[2] as DialogText).value.trim().split(' ').where((token) => token.isNotEmpty).toList();
    bool apply_to_all = (results[3] as DialogCheckbox).value;

    List<int> major_ticks = [];
    if (!use_major_tick_distance && major_ticks_str.isNotEmpty) {
      for (var major_tick_str in major_ticks_str) {
        int major_tick = int.tryParse(major_tick_str);
        if (major_tick == null) {
          window.alert('"${major_tick_str}" is not a valid integer');
          return;
        } else if (major_tick <= 0 && major_ticks.isNotEmpty) {
          window.alert('non-positive value ${major_tick} can only be used if it is the first element '
              'in the list, specifying where the first tick should be; all others must be positive offsets '
              'from the previous tick mark');
          return;
        } else {
          major_ticks.add(major_tick + (major_ticks.isEmpty ? 0 : major_ticks.last));
        }
      }

      int t = major_ticks.firstWhere((t) => t < helix.min_offset, orElse: () => null);
      if (t != null) {
        window.alert('major tick ${t} is less than minimum offset ${helix.min_offset}');
        return;
      }

      // TODO: avoid global variable here if possible (move this logic to middleware)
      if (apply_to_all) {
        for (var other_helix in app.state.dna_design.helices.values) {
          t = major_ticks.firstWhere((t) => t < other_helix.min_offset, orElse: () => null);
          if (t != null) {
            window.alert('major tick ${t} is less than minimum offset ${other_helix.min_offset}');
            return;
          }
        }
//        for (var other_helix in app.state.dna_design.helices.values) {
//          t = major_ticks.firstWhere((t) => t > other_helix.max_offset, orElse: () => null);
//          if (t != null) {
//            window.alert("major tick ${t} is greater than maximum offset ${other_helix.max_offset}, "
//                "so I'm only going up to the major tick just before that");
//          }
//        }
      }
    }

    actions.Action action;
    if (apply_to_all) {
      if (use_major_tick_distance) {
        action = actions.HelixMajorTickDistanceChangeAll(major_tick_distance: major_tick_distance);
      } else {
        action = actions.HelixMajorTicksChangeAll(major_ticks: major_ticks.toBuiltList());
      }
    } else {
      if (use_major_tick_distance) {
        action = actions.HelixMajorTickDistanceChange(
            helix_idx: helix_idx, major_tick_distance: major_tick_distance);
      } else {
        action = actions.HelixMajorTicksChange(helix_idx: helix_idx, major_ticks: major_ticks.toBuiltList());
      }
    }
    app.dispatch(action);
  }

  Future<void> dialog_helix_adjust_grid_position() async {
    var grid_position = props.helix.grid_position ?? GridPosition(0, 0);

    var dialog = Dialog(title: 'adjust helix grid position', items: [
      DialogNumber(label: 'h', value: grid_position.h),
      DialogNumber(label: 'v', value: grid_position.v),
    ]);

    List<DialogItem> results = await util.dialog(dialog);
    if (results == null) return;

    num h = (results[0] as DialogNumber).value;
    num v = (results[1] as DialogNumber).value;

    app.dispatch(actions.HelixGridPositionSet(helix: props.helix, grid_position: GridPosition(h, v)));
  }

  Future<void> dialog_helix_adjust_position() async {
    var position = props.helix.position ?? Position3D();

    var dialog = Dialog(title: 'adjust helix position', items: [
      DialogFloatingNumber(label: 'x', value: position.x),
      DialogFloatingNumber(label: 'y', value: position.y),
      DialogFloatingNumber(label: 'z', value: position.z),
    ]);

    List<DialogItem> results = await util.dialog(dialog);
    if (results == null) return;

    num x = (results[0] as DialogFloatingNumber).value;
    num y = (results[1] as DialogFloatingNumber).value;
    num z = (results[2] as DialogFloatingNumber).value;

    // TODO: (check validity)
    app.dispatch(actions.HelixPositionSet(
        helix_idx: props.helix.idx,
        position: Position3D(
          x: x,
          y: y,
          z: z,
        )));
  }

  String helix_circle_id() => 'main-view-helix-circle-${props.helix.idx}';

  String helix_text_id() => 'main-view-helix-text-${props.helix.idx}';

  List<ContextMenuItem> context_menu_helix(Helix helix) {
    ContextMenuItem context_menu_item_adjust_position = (props.helix.grid == Grid.none)
        ? ContextMenuItem(
            title: 'adjust position',
            on_click: helix_adjust_position,
          )
        : ContextMenuItem(
            title: 'adjust grid position',
            on_click: helix_adjust_grid_position,
          );

    return [
      ContextMenuItem(
        title: 'adjust length',
        on_click: helix_adjust_length,
      ),
      ContextMenuItem(
        title: 'adjust tick marks',
        on_click: helix_adjust_major_tick_marks,
      ),
      ContextMenuItem(
        title: 'adjust roll',
        on_click: helix_adjust_roll,
      ),
      context_menu_item_adjust_position,
    ];
  }

  final num DISTANCE_OFFSET_DISPLAY_FROM_HELIX = 3;

  _major_tick_offsets_svg_group() {
    var helix = props.helix;
    List<int> major_ticks = helix.calculate_major_ticks(props.design_major_tick_distance);

    var y = -DISTANCE_OFFSET_DISPLAY_FROM_HELIX - (props.show_dna ? constants.BASE_HEIGHT_SVG : 0);

    var offset_texts_elements = [];
    for (int offset in major_ticks) {
      var x = (offset + 0.5) * constants.BASE_WIDTH_SVG;
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
    var helix = props.helix;
    List<int> major_ticks = helix.calculate_major_ticks(props.design_major_tick_distance);

    num y = helix.svg_height() +
        DISTANCE_OFFSET_DISPLAY_FROM_HELIX +
        (props.show_dna ? constants.BASE_HEIGHT_SVG : 0);

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
      var x = base * constants.BASE_WIDTH_SVG;
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
}

String _horz_line_paths(Helix helix) {
  num width = helix.svg_width();
  num height = helix.svg_height();
  num x_start = helix.min_offset * constants.BASE_WIDTH_SVG;
  num x_end = x_start + width;

  return 'M $x_start 0 '
      'H $x_end '
      'M $x_start ${height / 2.0} '
      'H $x_end '
      'M $x_start $height '
      'H $x_end';
}

/// Return Map {'minor': thin_lines, 'major': thick_lines} to paths describing minor and major vertical lines.
Map<String, String> _vert_line_paths(Helix helix, int design_major_tick_distance) {
  var major_tick_distance =
      helix.has_major_tick_distance() ? helix.major_tick_distance : design_major_tick_distance;
  Set<int> major_ticks = (helix.has_major_ticks()
          ? helix.major_ticks
          : regularly_spaced_ticks(major_tick_distance, helix.min_offset, helix.max_offset))
      .toSet();

  List<String> path_cmds_vert_minor = [];
  List<String> path_cmds_vert_major = [];

  for (int base = helix.min_offset; base <= helix.max_offset; base++) {
    var base_minus_min_offset = base; // - helix.min_offset;
    var x = base_minus_min_offset * constants.BASE_WIDTH_SVG;
    var path_cmds = major_ticks.contains(base) ? path_cmds_vert_major : path_cmds_vert_minor;
    path_cmds.add('M $x 0');
    path_cmds.add('v ${helix.svg_height()}');
    x += constants.BASE_WIDTH_SVG;
  }

  return {'minor': path_cmds_vert_minor.join(' '), 'major': path_cmds_vert_major.join(' ')};
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
