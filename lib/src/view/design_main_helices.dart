import 'package:over_react/over_react.dart';
import 'package:react/react_client.dart';
import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/constants.dart';

import 'design_main_helix.dart';
import '../model/helix.dart';
import '../util.dart' as util;

part 'design_main_helices.over_react.g.dart';

@Factory()
UiFactory<DesignMainHelicesProps> DesignMainHelices = _$DesignMainHelices;

@Props()
class _$DesignMainHelicesProps extends UiProps {
  BuiltList<Helix> helices;
}

@Component2()
class DesignMainHelicesComponent extends UiComponent2<DesignMainHelicesProps> {

  @override
  render() {
    BuiltList<Helix> helices = props.helices;

    return (Dom.g()..className = 'helices-main-view')([
      for (Helix helix in helices)
        (DesignMainHelix()
          ..helix = helix
          ..key = helix.idx)()
    ]);
  }
}
