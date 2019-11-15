import 'package:over_react/over_react.dart';
import 'package:react/react_client.dart';
import 'package:built_collection/built_collection.dart';

import 'design_main_helix.dart';
import '../model/helix.dart';

part 'design_main_helices.over_react.g.dart';

@Factory()
UiFactory<DesignMainHelicesProps> DesignMainHelices = _$DesignMainHelices;

@Props()
class _$DesignMainHelicesProps extends UiProps { // FluxUiProps<HelicesStore, HelicesStore> {
  BuiltList<Helix> helices;
}

@Component2()
class DesignMainHelicesComponent extends UiComponent2<DesignMainHelicesProps> { // FluxUiComponent<DesignMainHelicesProps> {
//  @override
//  Map getDefaultProps() => (newProps());

  @override
  render() {
//    List<Helix> helices = this.props.store.helices;
    BuiltList<Helix> helices = this.props.helices;
    int idx = 0;
    return (Dom.g()..className = 'helices-main-view')([
      for (Helix helix in helices)
        (DesignMainHelix()
          ..helix = helix
          ..key = idx++)()
    ]);
  }
}
