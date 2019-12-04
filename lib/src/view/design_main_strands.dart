import 'package:over_react/over_react.dart';
import 'package:built_collection/built_collection.dart';

import '../state/strand.dart';
import 'design_main_strand.dart';

part 'design_main_strands.over_react.g.dart';

@Factory()
UiFactory<DesignMainStrandsProps> DesignMainStrands = _$DesignMainStrands;

@Props()
class _$DesignMainStrandsProps extends UiProps {
  BuiltList<Strand> strands;
}

@Component2()
class DesignMainStrandsComponent extends UiComponent2<DesignMainStrandsProps> {
  @override
  bool shouldComponentUpdate(Map nextProps, Map nextState) {
    BuiltList<Strand> strands = nextProps['DesignMainStrandsProps.strands'];
    return !(props.strands == strands);
  }

  @override
  render() {
    return (Dom.g()..className = 'strands-main-view')([
      for (var strand in props.strands)
        (ConnectedDesignMainStrand()
          ..strand = strand
          ..key = strand.toString())()
    ]);
  }
}
