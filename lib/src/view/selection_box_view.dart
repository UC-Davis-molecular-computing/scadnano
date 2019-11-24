import 'package:over_react/over_react.dart';

import '../model/selection_box.dart';

part 'selection_box_view.over_react.g.dart';



@Factory()
UiFactory<SelectionBoxViewProps> SelectionBoxView = _$SelectionBoxView;

@Props()
class _$SelectionBoxViewProps extends UiProps {
  SelectionBox selection_box;
  num stroke_width;
}

@Component2()
class SelectionBoxViewComponent extends UiComponent2<SelectionBoxViewProps> {
//  @override
//  void componentDidUpdate(Map prevProps, Map prevState) {
//    super.componentDidUpdate(prevProps, prevState);
//    print('selection box componentDidUpdate');
//    var store = prevProps['SelectionBoxView.selection_box'];
//    var x_p = store.x;
//    var y_p = prevProps['SelectionBoxView.selection_box'].y;
//    var w_p = prevProps['SelectionBoxView.selection_box'].width;
//    var h_p = prevProps['SelectionBoxView.selection_box'].height;
//    var x = this.props.selection_box.x;
//    var y = this.props.selection_box.y;
//    var w = this.props.selection_box.width;
//    var h = this.props.selection_box.height;
//    if (x_p != x || y_p != y || w_p != w || h_p != h) {
////      Actions.update_selection_box_selections();
//    }
//  }

  @override
  render() {
    SelectionBox box = props.selection_box;

    if (!box.displayed) {
      return null;
    } else {
      num stroke_width = props.stroke_width;
      return (Dom.rect()
        ..x = box.x
        ..y = box.y
        ..width = box.width
        ..height = box.height
        ..strokeWidth = stroke_width
        ..id = 'selection-box-side'
        ..className = 'selection-box')();
    }
  }
}
