import 'dart:html';
import 'dart:math';

import 'package:quiver/iterables.dart' as iter;
import 'package:over_react/over_react.dart';
import 'package:react/react_client.dart';
import 'package:smart_dialogs/smart_dialogs.dart';

import '../state/helix.dart';
import '../app.dart';
import '../actions/actions.dart' as actions;
import '../constants.dart' as constants;
import '../util.dart' as util;
import 'pure_component.dart';

part 'design_main_helix.over_react.g.dart';

@Factory()
UiFactory<DesignMainHelixProps> DesignMainHelix = _$DesignMainHelix;

@Props()
class _$DesignMainHelixProps extends UiProps {
  Helix helix;
  int view_order;
  bool strand_create_enabled;
}

@Component2()
class DesignMainHelixComponent extends UiComponent2<DesignMainHelixProps> with PureComponent {
  @override
  render() {
    Helix helix = props.helix;

    // for helix circles
    var cx = -(2 * constants.BASE_WIDTH_SVG + constants.DISTANCE_BETWEEN_HELICES_SVG / 2);
    var cy = constants.BASE_WIDTH_SVG;

    // for helix horizontal lines
    num width = helix.svg_width();
    num height = helix.svg_height();

    var vert_line_paths = _vert_line_paths(helix);
    int idx = helix.idx;

    var x_start = helix.min_offset * constants.BASE_WIDTH_SVG;
    var x_end = x_start + width;

    Point<num> translation = helix_main_view_translation(helix);
    String tooltip_helix_length_adjust = 'click to adjust helix length';

    return (Dom.g()
      ..className = 'helix-main-view'
      ..transform = 'translate(${translation.x} ${translation.y})')([
      (Dom.circle()
        ..className = 'main-view-helix-circle'
        ..cx = '$cx'
        ..cy = '$cy'
        ..r = '${constants.DISTANCE_BETWEEN_HELICES_SVG / 2.0}'
        ..onClick = ((_) => app.disable_keyboard_shortcuts_while(handle_helix_adjust_length_button_pressed))
        ..key = 'main-view-helix-circle')(Dom.svgTitle()(tooltip_helix_length_adjust)),
      (Dom.text()
        ..className = 'main-view-helix-text'
        ..x = '$cx'
        ..y = '$cy'
        ..onClick = ((_) => app.disable_keyboard_shortcuts_while(handle_helix_adjust_length_button_pressed))
        ..key = 'main-view-helix-text')(Dom.svgTitle()(tooltip_helix_length_adjust), '$idx'),
      (Dom.g()
        ..className = 'helix-lines-group'
        ..key = 'helix-lines-group')(
        (Dom.path()
          ..className = 'helix-lines helix-horz-line'
          ..d = 'M $x_start 0 '
              'H $x_end '
              'M $x_start ${height / 2.0} '
              'H $x_end '
              'M $x_start $height '
              'H $x_end'
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
      if (props.strand_create_enabled)
        (Dom.rect()
          ..onClick = create_strand
          ..x = '0'
          ..y = '0'
          ..width = '$width'
          ..height = '$height'
          ..className = 'helix-invisible-rect'
          ..key = 'helix-invisible-rect')(),
    ]);
  }

  create_strand(SyntheticMouseEvent event_syn) {
    MouseEvent event = event_syn.nativeEvent;
    var address = util.get_address_on_helix(event, props.helix);
    int offset = address.offset;
    bool forward = address.forward;
    if (offset <= props.helix.min_offset) {
      return;
    }
    int start = offset;
    int end = offset + 2;
    app.dispatch(actions.StrandCreate(helix_idx: props.helix.idx, forward: forward, start: start, end: end));
  }

  Future<void> handle_helix_adjust_length_button_pressed() async {
    Helix helix = props.helix;
    int helix_idx = helix.idx;

    // https://pub.dev/documentation/smart_dialogs/latest/smart_dialogs/Info/get.html
    String buttontype = DiaAttr.CHECKBOX;
    String htmlTitleText = 'helix ${helix_idx} new offsets';
    List<String> textLabels = ['minimum:', 'maximum:', 'apply to all helices'];
    List<List<String>> comboInfo = null;
    List<String> defaultInputTexts = ['${helix.min_offset}', '${helix.max_offset}', null];
    List<int> widths = [1, 1, 0];
    List<String> isChecked = [null, null, 'true'];
    bool alternateRowColor = false;
    List<String> buttonLabels = ['OK', 'Cancel'];

    UserInput result = await Info.get(buttontype, htmlTitleText, textLabels, comboInfo, defaultInputTexts,
        widths, isChecked, alternateRowColor, buttonLabels);

    if (result.buttonCode != 'DIA_ACT_OK') {
      return;
    }

    String min_offset_str = result.getUserInput(0)[0];
    String max_offset_str = result.getUserInput(1)[0];

    int min_offset;
    int max_offset;

    try {
      min_offset = int.parse(min_offset_str);
    } on FormatException {
      Info.show('minimum offset value "${min_offset_str}" is not an integer');
      return;
    }
    try {
      max_offset = int.parse(max_offset_str);
    } on FormatException {
      Info.show('maximum offset value "${max_offset_str}" is not an integer');
      return;
    }

    if (min_offset >= max_offset) {
      Info.show('minimum offset ${min_offset} must be strictly less than maximum offset, '
          'but maximum offset is ${max_offset}');
      return;
    }

    bool apply_to_all = result.getCheckedState(2) == 'true';
    if (apply_to_all) {
      app.dispatch(actions.HelixOffsetChangeAll(min_offset: min_offset, max_offset: max_offset));
    } else {
      app.dispatch(
          actions.HelixOffsetChange(helix_idx: helix_idx, min_offset: min_offset, max_offset: max_offset));
    }
  }
}

//static _default_svg_position(int idx) => Point<num>(0, constants.DISTANCE_BETWEEN_HELICES_SVG * idx);
//
Point<num> helix_main_view_translation(Helix helix) {
  return helix.svg_position;
  //FIXME: standardize this
//  int view_order = helix.view_order;
//  if (helix.position != null) {
//    return Point<num>(
//        helix.position.z * constants.BASE_WIDTH_SVG, helix.position.y * constants.DISTANCE_BETWEEN_HELICES_SVG);
//  } else {
//    return Point<num>(0, constants.DISTANCE_BETWEEN_HELICES_SVG * view_order);
//  }
}

/// Return Map {'minor': thin_lines, 'major': thick_lines} to paths describing minor and major vertical lines.
Map<String, String> _vert_line_paths(Helix helix) {
  List<int> regularly_spaced_ticks(int distance, int start, int end) {
    if (distance == null || distance == 0) {
      return [];
    } else if (distance < 0) {
      throw ArgumentError('distance between major ticks must be positive');
    } else {
      return [for (int offset in iter.range(start, end + 1, distance)) offset];
    }
  }

  var major_tick_distance =
      helix.has_major_tick_distance() ? helix.major_tick_distance : app.state.dna_design.major_tick_distance;
  Set<int> major_ticks = (helix.has_major_ticks()
          ? helix.major_ticks
          : regularly_spaced_ticks(major_tick_distance, helix.min_offset, helix.max_offset))
      .toSet();

  List<String> path_cmds_vert_minor = [];
  List<String> path_cmds_vert_major = [];

  for (int base = helix.min_offset; base <= helix.max_offset; base++) {
    var x = base * constants.BASE_WIDTH_SVG;
    var path_cmds = major_ticks.contains(base) ? path_cmds_vert_major : path_cmds_vert_minor;
    path_cmds.add('M $x 0');
    path_cmds.add('v ${helix.svg_height()}');
    x += constants.BASE_WIDTH_SVG;
  }

  return {'minor': path_cmds_vert_minor.join(' '), 'major': path_cmds_vert_major.join(' ')};
}
