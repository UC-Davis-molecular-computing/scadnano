import 'package:over_react/over_react_redux.dart';
import 'package:over_react/over_react.dart';

import '../app.dart';
import '../state/selection_box.dart';

part 'selection_box_view.over_react.g.dart';

UiFactory<SelectionBoxViewProps> ConnectedSelectionBoxView = connect<SelectionBox, SelectionBoxViewProps>(
  mapStateToPropsWithOwnProps: (box, props) {
    return SelectionBoxView()
      ..selection_box = box
      ..stroke_width_getter = props.stroke_width_getter
      ..id_ = props.id_
      ..is_main = props.is_main;
  },
  context: app.context_selection_box,
)(SelectionBoxView);

UiFactory<SelectionBoxViewProps> SelectionBoxView = _$SelectionBoxView;

mixin SelectionBoxViewProps on UiProps {
  SelectionBox? selection_box;
  num Function()? stroke_width_getter;
  String? id_;
  bool? is_main;
}

class SelectionBoxViewComponent extends UiComponent2<SelectionBoxViewProps> {
  @override
  render() {
    if (props.selection_box == null ||
        props.stroke_width_getter == null ||
        props.id_ == null ||
        props.is_main == null) {
      return null;
    }
    SelectionBox box = props.selection_box!;
    num stroke_width = props.stroke_width_getter!();

    if (props.is_main != box.is_main) {
      return null;
    }

    return (Dom.rect()
      ..x = box.x
      ..y = box.y
      ..width = box.width
      ..height = box.height
      ..strokeWidth = stroke_width
      ..id = props.id_
      ..className = 'selection-box')();
  }
}
