//part of '../components.dart';

import 'package:over_react/over_react.dart';
import 'package:scadnano/src/view/design_main_mouseover_rect_helix.dart';

import '../model/helix.dart';

part 'design_main_mouseover_rect_helices.over_react.g.dart';

@Factory()
UiFactory<DesignMainMouseoverRectHelicesProps> DesignMainMouseoverRectHelices = _$DesignMainMouseoverRectHelices;

@Props()
class _$DesignMainMouseoverRectHelicesProps extends FluxUiProps<HelicesStore, HelicesStore> {}

@Component()
class DesignMainMouseoverRectHelicesComponent extends FluxUiComponent<DesignMainMouseoverRectHelicesProps> {
  @override
  Map getDefaultProps() => (newProps());

  @override
  render() {
    int idx = 0;
    return (Dom.g()..className = 'mouseover-rectangle-main-view')([
      for (Helix helix in this.props.store.helices)
        (DesignMainMouseoverRectHelix()
          ..helix = helix
          ..key = idx++)()
    ]);
  }
}
