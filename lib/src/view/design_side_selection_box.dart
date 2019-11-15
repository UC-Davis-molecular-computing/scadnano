import 'package:over_react/over_react.dart';

import '../dispatcher/actions_OLD.dart';
import '../model/selection_box.dart';
import '../util.dart' as util;

part 'design_side_selection_box.over_react.g.dart';

@Factory()
UiFactory<DesignSideSelectionBoxProps> DesignSideSelectionBox = _$DesignSideSelectionBox;

@Props()
class _$DesignSideSelectionBoxProps extends UiProps { // FluxUiProps<SelectionBoxStore, SelectionBoxStore> {}
  SelectionBox selection_box;
}

@Component2()
class DesignSideSelectionBoxComponent extends UiComponent2<DesignSideSelectionBoxProps> { // FluxUiComponent<DesignSideSelectionBoxProps> {
//  @override
//  void componentDidUpdate(Map prevProps, Map prevState) {
//    super.componentDidUpdate(prevProps, prevState);
//    print('selection box componentDidUpdate');
//    var store = prevProps['DesignSideSelectionBox.selection_box'];
//    var x_p = store.x;
//    var y_p = prevProps['DesignSideSelectionBox.selection_box'].y;
//    var w_p = prevProps['DesignSideSelectionBox.selection_box'].width;
//    var h_p = prevProps['DesignSideSelectionBox.selection_box'].height;
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
      return (Dom.rect()
        ..x = box.x
        ..y = box.y
        ..width = box.width
        ..height = box.height
        ..strokeWidth = 2.0 / util.current_zoom_main()
        ..id = 'selection-box-side'
        ..className = 'selection-box')();
    }
  }
}
