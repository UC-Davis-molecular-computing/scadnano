import 'package:over_react/over_react.dart';

import '../dispatcher/actions.dart';
import '../model/selection_box.dart';
import '../util.dart' as util;

part 'design_main_selection_box.over_react.g.dart';

@Factory()
UiFactory<DesignMainSelectionBoxProps> DesignMainSelectionBox = _$DesignMainSelectionBox;

@Props()
class _$DesignMainSelectionBoxProps extends FluxUiProps<SelectionBoxStore, SelectionBoxStore> {}

@Component()
class DesignMainSelectionBoxComponent extends FluxUiComponent<DesignMainSelectionBoxProps> {
  @override
  Map getDefaultProps() => (newProps());


//  @override
//  void componentDidUpdate(Map prevProps, Map prevState) {
//    super.componentDidUpdate(prevProps, prevState);
//    print('selection box componentDidUpdate');
//    var store = prevProps['store'];
//    var x_p = store.x;
//    var y_p = prevProps['store'].y;
//    var w_p = prevProps['store'].width;
//    var h_p = prevProps['store'].height;
//    var x = this.props.store.x;
//    var y = this.props.store.y;
//    var w = this.props.store.width;
//    var h = this.props.store.height;
//    if (x_p != x || y_p != y || w_p != w || h_p != h) {
//      Actions.update_selection_box_selections();
//    }
//  }

  @override
  render() {
    SelectionBoxStore store = this.props.store;
    if (!store.displayed) {
      return null;
    } else {
      return (Dom.rect()
        ..x = store.x
        ..y = store.y
        ..width = store.width
        ..height = store.height
        ..strokeWidth = 2.0 / util.current_zoom_main()
        ..id = 'selection-box'
        ..className = 'selection-box')();
    }
  }
}
