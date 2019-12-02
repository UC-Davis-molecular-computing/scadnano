import 'package:over_react/over_react.dart';

import '../model/selection_box.dart';

part 'selection_box_view.over_react.g.dart';

@Factory()
UiFactory<SelectionBoxViewProps> SelectionBoxView = _$SelectionBoxView;

@Props()
class _$SelectionBoxViewProps extends UiProps {
  SelectionBox selection_box;
  num stroke_width;
  String id;
}

@Component2()
class SelectionBoxViewComponent extends UiComponent2<SelectionBoxViewProps> {

  @override
  render() {
    SelectionBox box = props.selection_box;
    num stroke_width = props.stroke_width;

//    print('selection box: $box');

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
