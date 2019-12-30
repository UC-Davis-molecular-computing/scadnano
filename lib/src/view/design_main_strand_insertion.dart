import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:color/color.dart';
import 'package:over_react/over_react.dart';
import 'package:platform_detect/platform_detect.dart';
import 'package:scadnano/src/state/edit_mode.dart';
import 'package:scadnano/src/state/helix.dart';
import 'package:smart_dialogs/smart_dialogs.dart';
import 'package:tuple/tuple.dart';

import '../app.dart';
import 'package:scadnano/src/state/bound_substrand.dart';
import '../util.dart' as util;
import '../constants.dart' as constants;
import '../actions/actions.dart' as actions;
import 'design_main_strands.dart';
import 'edit_mode_queryable.dart';
import 'pure_component.dart';

part 'design_main_strand_insertion.over_react.g.dart';

typedef Tuple2<Insertion, BoundSubstrand> PairedInsertionFinder(
    Insertion insertion, BoundSubstrand substrand);

@Factory()
UiFactory<DesignMainStrandInsertionProps> DesignMainStrandInsertion = _$DesignMainStrandInsertion;

@Props()
class _$DesignMainStrandInsertionProps extends EditModePropsAbstract {
  Insertion insertion;
  BoundSubstrand substrand;
  Color color;
  Helix helix;
  String id;
  BuiltSet<EditModeChoice> edit_modes;
  PairedSubstrandFinder find_paired_substrand;
}

@Component2()
class DesignMainStrandInsertionComponent extends UiComponent2<DesignMainStrandInsertionProps>
    with PureComponent, EditModeQueryable<DesignMainStrandInsertionProps> {
  @override
  render() {
    Point<num> pos = props.helix.svg_base_pos(props.insertion.offset, props.substrand.forward);
    ReactElement insertion_background = _insertion_background(pos);
    ReactElement insertion_path = _insertion_path();
    ReactElement text_num_insertions = _text_number_of_insertions(pos);
    return [insertion_path, insertion_background, text_num_insertions];
  }

  ReactElement _insertion_path() {
    BoundSubstrand substrand = props.substrand;
    int offset = props.insertion.offset;
    Color color = props.color;

    Point<num> pos = props.helix.svg_base_pos(offset, substrand.forward);

    num dx1 = constants.BASE_WIDTH_SVG;
    num dx2 = 0.5 * constants.BASE_WIDTH_SVG;
    num dy1 = 2 * constants.BASE_HEIGHT_SVG;
    num dy2 = 2 * constants.BASE_HEIGHT_SVG;
    if (substrand.forward) {
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
    ReactElement insertion_path = (Dom.path()
      ..onClick = ((_) => change_insertion_length())
      ..className = 'insertion-line'
      ..stroke = color.toRgbColor().toCssString()
      ..fill = 'none'
      ..d = 'M $x0 $y0 '
          'C $x1 $y1, $x2 $y2, $x3 $y2 '
          'C $x4 $y2, $x5 $y1, $x0 $y0 '
      ..id = props.id
      ..key = props.id)();
    return insertion_path;
  }

  ReactElement _text_number_of_insertions(Point<num> pos) {
    int offset = props.insertion.offset;
    BoundSubstrand substrand = props.substrand;
    Insertion insertion = props.insertion;

    // write number of insertions inside insertion loop
    int length = insertion.length;

    var dy_text = '${0.2 * constants.BASE_WIDTH_SVG}';
    if (browser.isFirefox) {
      // le sigh
      dy_text = '${0.14 * constants.BASE_WIDTH_SVG}';
    }

    num background_width = constants.BASE_WIDTH_SVG;
    num background_height = 1.5 * constants.BASE_HEIGHT_SVG;
    num background_x = pos.x - background_width / 2;
    num background_y = pos.y - constants.BASE_HEIGHT_SVG / 2;
    if (substrand.forward) {
      background_y -= background_height;
    } else {
      background_y += constants.BASE_HEIGHT_SVG;
    }

    String key = 'num-insertion-H${substrand.helix}-${offset}';
    SvgProps text_path_props = Dom.textPath()
      ..className = 'insertion-length'
      ..startOffset = '50%'
      ..href = '#${util.id_insertion(substrand, offset)}';

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
          ..onClick = ((_) => change_insertion_length())
          ..key = 'rect')(),
        (Dom.text()
          ..onClick = ((_) => change_insertion_length())
          ..dy = dy_text
          ..id = key
          ..key = 'text')(text_path_props('${length}')));
  }

  ReactElement _insertion_background(Point<num> pos) {
    String key_background = 'insertion-background-H${props.substrand.helix}-${props.insertion.offset}';
    num background_width = constants.BASE_WIDTH_SVG;
    num background_height = constants.BASE_HEIGHT_SVG;
    num background_x = pos.x - background_width / 2;
    num background_y = pos.y - background_height / 2;
    return (Dom.rect()
      ..className = 'insertion-background'
      ..x = background_x
      ..y = background_y
      ..width = background_width
      ..height = background_height
      ..onClick = ((_) => remove_insertion())
      ..key = key_background)();
  }

  remove_insertion() {
    if (insertion_mode) {
      var paired_substrand = props.find_paired_substrand(props.substrand, props.insertion.offset);
      if (paired_substrand != null &&
          paired_substrand.insertions.map((i) => i.offset).contains(props.insertion.offset)) {
        app.dispatch(actions.BatchAction([
          actions.InsertionRemove(bound_substrand: props.substrand, insertion: props.insertion),
          actions.InsertionRemove(bound_substrand: paired_substrand, insertion: props.insertion),
        ]));
      } else {
        app.dispatch(actions.InsertionRemove(bound_substrand: props.substrand, insertion: props.insertion));
      }
    }
  }

  change_insertion_length() async {
    int new_length = await ask_for_insertion_length(props.insertion.length);
    if (new_length == null) {
      return;
    }
    int offset = props.insertion.offset;
    BoundSubstrand paired_substrand = props.find_paired_substrand(props.substrand, offset);
    Insertion paired_insertion = paired_substrand.insertions.firstWhere((i) => i.offset == offset);
    if (paired_insertion != null) {
      app.dispatch(actions.BatchAction([
        actions.InsertionLengthChange(
            bound_substrand: props.substrand, insertion: props.insertion, length: new_length),
        actions.InsertionLengthChange(
            bound_substrand: paired_substrand, insertion: paired_insertion, length: new_length),
      ]));
    } else {
      app.dispatch(actions.InsertionLengthChange(
          bound_substrand: props.substrand, insertion: props.insertion, length: new_length));
    }
  }
}

Future<int> ask_for_insertion_length(int current_length) async {
  // https://pub.dev/documentation/smart_dialogs/latest/smart_dialogs/Info/get.html
  String buttontype = DiaAttr.CHECKBOX;
  String htmlTitleText = 'change insertion length';
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
    Info.show('"$length_str" is not a valid positive integer');
    return null;
  } else if (length < 1) {
    Info.show('length must be positive, but it is $length_str');
    return null;
  }

  return length;
}
