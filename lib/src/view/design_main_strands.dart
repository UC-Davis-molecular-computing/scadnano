import 'package:over_react/over_react.dart';
import 'package:built_collection/built_collection.dart';

import '../model/strand.dart';
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
    BuiltList<Strand> strands = props.strands;
    BuiltList<Strand> strands_next = nextProps['DesignMainStrandsProps.strands'];
//    print('DesignMainStrands.shouldComponentUpdate should = ${!(strands == strands_next)}');
//    print('DesignMainStrands.shouldComponentUpdate strands == strands_next          = ${strands == strands_next}');
//    print('DesignMainStrands.shouldComponentUpdate identical(strands, strands_next) = ${identical(strands, strands_next)}');
    return !(strands == strands_next);
  }

  @override
  render() {
    BuiltList<Strand> strands = this.props.strands;

    List strand_elts = [];
    for (Strand strand in strands) {
      var strand_props =
//      DesignMainStrand()
      ConnectedDesignMainStrand()
        ..strand = strand
        ..key = strand.toString();
      var strand_elt = strand_props();
      strand_elts.add(strand_elt);
    }
    return (Dom.g()..className = 'strands-main-view')(strand_elts);
  }
}
