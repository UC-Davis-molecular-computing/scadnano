import 'package:over_react/over_react.dart';

import 'design_main_mouseover_rect_helix.dart';
import '../model/helix.dart';

part 'design_main_mouseover_rect_helices.over_react.g.dart';

const _ID = 'mouseover-rectangle-main-view';
const _CLASS = 'mouseover-rectangle-main-view';

@Factory()
UiFactory<DesignMainMouseoverRectHelicesProps> DesignMainMouseoverRectHelices =
    _$DesignMainMouseoverRectHelices;

@Props()
class _$DesignMainMouseoverRectHelicesProps extends FluxUiProps<HelicesStore, HelicesStore> {}

@Component()
class DesignMainMouseoverRectHelicesComponent extends FluxUiComponent<DesignMainMouseoverRectHelicesProps> {
  @override
  Map getDefaultProps() => (newProps());

  @override
  render() {
    int idx = 0;
    return (Dom.g()
//      ..onMouseMove = _trigger_mouse_move
      ..id = _ID
      ..className = _CLASS)([
      for (Helix helix in this.props.store.helices)
        (DesignMainMouseoverRectHelix()
          ..helix = helix
          ..key = idx++)()
    ]);
  }
}


