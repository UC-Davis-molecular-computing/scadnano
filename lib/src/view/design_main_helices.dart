import 'package:over_react/over_react.dart';
import 'package:react/react_client.dart';
import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/constants.dart';

import 'design_main_helix.dart';
import '../state/helix.dart';
import '../util.dart' as util;

part 'design_main_helices.over_react.g.dart';

@Factory()
UiFactory<DesignMainHelicesProps> DesignMainHelices = _$DesignMainHelices;

@Props()
class _$DesignMainHelicesProps extends UiProps {
  BuiltList<Helix> helices;
  BuiltSet<int> side_selected_helix_idxs;
}

@Component2()
class DesignMainHelicesComponent extends UiComponent2<DesignMainHelicesProps> {
  @override
  bool shouldComponentUpdate(Map nextProps, Map nextState) {
    var helices = props.helices;
    var side_selected_helix_idxs = props.side_selected_helix_idxs;
    BuiltList<Helix> helices_next = nextProps['DesignMainHelicesProps.helices'];
    BuiltSet<int> side_selected_helix_idxs_next = nextProps['DesignMainHelicesProps.side_selected_helix_idxs'];;
    return !(helices == helices_next && side_selected_helix_idxs == side_selected_helix_idxs_next);
  }

  @override
  render() {
    BuiltList<Helix> helices = props.helices;
    BuiltSet<int> side_selected_helix_idxs = props.side_selected_helix_idxs;

    return (Dom.g()..className = 'helices-main-view')([
      for (Helix helix in helices)
        if (side_selected_helix_idxs.isEmpty || side_selected_helix_idxs.contains(helix.idx))
          (DesignMainHelix()
            ..helix = helix
            ..key = helix.idx)()
    ]);
  }
}
