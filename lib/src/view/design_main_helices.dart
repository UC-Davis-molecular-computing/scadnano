import 'package:over_react/over_react.dart';
import 'package:react/react_client.dart';
import 'package:built_collection/built_collection.dart';

import 'design_main_helix.dart';
import '../state/helix.dart';

part 'design_main_helices.over_react.g.dart';

@Factory()
UiFactory<DesignMainHelicesProps> DesignMainHelices = _$DesignMainHelices;

@Props()
class _$DesignMainHelicesProps extends UiProps {
  BuiltList<Helix> helices;
  BuiltSet<int> side_selected_helix_idxs;
  bool strand_create_enabled;
}

@Component2()
class DesignMainHelicesComponent extends UiComponent2<DesignMainHelicesProps> {
  @override
  bool shouldComponentUpdate(Map nextProps, Map nextState) {
    var helices = nextProps['DesignMainHelicesProps.helices'];
    var side_selected_helix_idxs = nextProps['DesignMainHelicesProps.side_selected_helix_idxs'];
    var strand_create_enabled = nextProps['DesignMainHelicesProps.strand_create_enabled'];
    return !(helices == props.helices &&
        side_selected_helix_idxs == props.side_selected_helix_idxs &&
        strand_create_enabled == props.strand_create_enabled);
  }

  @override
  render() {
    BuiltSet<int> side_selected_helix_idxs = props.side_selected_helix_idxs;

    var children = [];
    for (Helix helix in props.helices) {
      if (side_selected_helix_idxs.isEmpty || side_selected_helix_idxs.contains(helix.idx)) {
        children.add((DesignMainHelix()
          ..helix = helix
          ..strand_create_enabled = props.strand_create_enabled
          ..key = helix.idx)());
      }
    }

    return (Dom.g()..className = 'helices-main-view')(children);
  }
}
