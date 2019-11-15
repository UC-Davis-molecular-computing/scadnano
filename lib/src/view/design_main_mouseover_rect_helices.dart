import 'package:over_react/over_react.dart';
import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/model/dna_design.dart';

import '../app.dart';
import 'design_main_mouseover_rect_helix.dart';
import '../model/helix.dart';

part 'design_main_mouseover_rect_helices.over_react.g.dart';

const _ID = 'mouseover-rectangle-main-view';
const _CLASS = 'mouseover-rectangle-main-view';

@Factory()
UiFactory<DesignMainMouseoverRectHelicesProps> DesignMainMouseoverRectHelices =
    _$DesignMainMouseoverRectHelices;

@Props()
class _$DesignMainMouseoverRectHelicesProps extends UiProps { // FluxUiProps<HelicesStore, HelicesStore> {
  BuiltList<Helix> helices;
}

@Component2()
class DesignMainMouseoverRectHelicesComponent extends UiComponent2<DesignMainMouseoverRectHelicesProps> { // FluxUiComponent<DesignMainMouseoverRectHelicesProps> {
//  @override
//  Map getDefaultProps() => (newProps());

  @override
  render() {
//    List<Helix> helices = this.props.store.helices;
    BuiltList<Helix> helices = this.props.helices;
    int idx = 0;
    return (Dom.g()
//      ..onMouseMove = _trigger_mouse_move
      ..id = _ID
      ..className = _CLASS)([
      for (Helix helix in helices)
        (DesignMainMouseoverRectHelix()
//        (ConnectedDesignMainMouseoverRectHelix()
//          ..dna_design = app.model.dna_design
          ..helix = helix
          ..key = idx++)()
    ]);
  }
}


