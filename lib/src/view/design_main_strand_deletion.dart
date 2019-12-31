import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:over_react/over_react.dart';
import 'package:scadnano/src/state/bound_substrand.dart';
import 'package:scadnano/src/state/edit_mode.dart';
import 'package:scadnano/src/state/helix.dart';
import '../app.dart';
import '../constants.dart' as constants;
import '../actions/actions.dart' as actions;
import 'edit_mode_queryable.dart';
import 'pure_component.dart';

part 'design_main_strand_deletion.over_react.g.dart';

@Factory()
UiFactory<DesignMainStrandDeletionProps> DesignMainStrandDeletion = _$DesignMainStrandDeletion;

@Props()
class _$DesignMainStrandDeletionProps extends EditModePropsAbstract {
  BoundSubstrand substrand;
  int deletion;
  Helix helix;
  BuiltSet<EditModeChoice> edit_modes;
}

@Component2()
class DesignMainStrandDeletionComponent extends UiComponent2<DesignMainStrandDeletionProps>
    with PureComponent, EditModeQueryable<DesignMainStrandDeletionProps> {
  @override
  render() {
    BoundSubstrand substrand = props.substrand;
    int deletion_offset = props.deletion;

    Point<num> pos = props.helix.svg_base_pos(deletion_offset, substrand.forward);

    // deletion
    var width = 0.8 * constants.BASE_WIDTH_SVG;
    var half_width = 0.5 * width;
    var path_cmds = 'M ${pos.x - half_width} ${pos.y - half_width} '
        'l ${width} ${width} m ${-width} ${0} l ${width} ${-width}';

    // deletion invisible background
    num background_width = constants.BASE_WIDTH_SVG;
    num background_height = constants.BASE_HEIGHT_SVG;
    num background_x = pos.x - background_width / 2;
    num background_y = pos.y - background_height / 2;

    String key = 'deletion-H${substrand.helix}-${deletion_offset}';
    String key_background = 'deletion-background-H${substrand.helix}-${deletion_offset}';
    return [
      (Dom.rect()
        ..className = 'deletion-background'
        ..x = background_x
        ..y = background_y
        ..width = background_width
        ..height = background_height
        ..onClick = ((_) {
          if (deletion_mode) {
            app.dispatch(actions.DeletionRemove(substrand: props.substrand, offset: props.deletion));
//            remove_deletion();
          }
        })
        ..key = key_background)(),
      (Dom.path()
        ..className = 'deletion-cross'
        ..fill = 'none'
        ..d = path_cmds
        ..onClick = ((_) {
          if (deletion_mode) {
            app.dispatch(actions.DeletionRemove(substrand: props.substrand, offset: props.deletion));
//            remove_deletion();
          }
        })
        ..id = key
        ..key = key)()
    ];
  }

//  remove_deletion() {
//    var paired_substrand = props.find_paired_substrand(props.substrand, props.deletion);
//    if (paired_substrand != null && paired_substrand.deletions.contains(props.deletion)) {
//      app.dispatch(actions.BatchAction([
//        actions.DeletionRemove(substrand: props.substrand, offset: props.deletion),
//        actions.DeletionRemove(substrand: paired_substrand, offset: props.deletion),
//      ]));
//    } else {
//      app.dispatch(actions.DeletionRemove(substrand: props.substrand, offset: props.deletion));
//    }
//  }
}
