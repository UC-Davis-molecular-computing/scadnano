import 'package:over_react/over_react_redux.dart';
import 'package:over_react/over_react.dart';

import '../app.dart';
import '../state/selection_box.dart';

part 'selection_box_view.over_react.g.dart';

UiFactory<SelectionBoxViewProps> ConnectedSelectionBoxView = connect<SelectionBox, SelectionBoxViewProps>(
  mapStateToProps: (box) {
    return SelectionBoxView()..selection_box = box;
  },
  context: app.context_selection_box,
)(SelectionBoxView);

@Factory()
UiFactory<SelectionBoxViewProps> SelectionBoxView = _$SelectionBoxView;

@Props()
class _$SelectionBoxViewProps extends UiProps {
  SelectionBox selection_box;
  num Function() stroke_width_getter;
  String id;
  bool is_main;
}

@Component2()
class SelectionBoxViewComponent extends UiComponent2<SelectionBoxViewProps> {
  @override
  render() {
    SelectionBox box = props.selection_box;
    num stroke_width = props.stroke_width_getter();

    if (box == null) {
      return null;
    }
    if (props.is_main != box.is_main) {
      return null;
    }

    return (Dom.rect()
      ..x = box.x
      ..y = box.y
      ..width = box.width
      ..height = box.height
      ..strokeWidth = stroke_width
      ..id = props.id
      ..className = 'selection-box')();
  }
}
