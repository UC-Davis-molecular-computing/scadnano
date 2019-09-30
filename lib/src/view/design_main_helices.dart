import 'package:over_react/over_react.dart';
import 'package:react/react_client.dart';
import 'package:scadnano/src/view/design_main_helix.dart';

import '../model/helix.dart';

part 'design_main_helices.over_react.g.dart';

@Factory()
UiFactory<DesignMainHelicesProps> DesignMainHelices = _$DesignMainHelices;

@Props()
class _$DesignMainHelicesProps extends FluxUiProps<HelicesStore, HelicesStore> {}

@Component()
class DesignMainHelicesComponent extends FluxUiComponent<DesignMainHelicesProps> {
  @override
  Map getDefaultProps() => (newProps());

  @override
  render() {
    int idx = 0;
    return (Dom.g()..className = 'helices-main-view')([
      for (Helix helix in this.props.store.helices)
        (DesignMainHelix()
          ..helix = helix
          ..key = idx++)()
    ]);
  }
}
