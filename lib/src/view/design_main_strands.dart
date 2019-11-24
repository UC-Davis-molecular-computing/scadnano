import 'package:over_react/over_react.dart';
import 'package:built_collection/built_collection.dart';

import '../app.dart';
import '../model/strand.dart';
import 'design_main_strand.dart';

part 'design_main_strands.over_react.g.dart';

@Factory()
UiFactory<DesignMainStrandsProps> DesignMainStrands = _$DesignMainStrands;

@Props()
class _$DesignMainStrandsProps extends UiProps { // FluxUiProps<StrandsStore, StrandsStore> {
  BuiltList<Strand> strands;
}

@Component2()
class DesignMainStrandsComponent extends UiComponent2<DesignMainStrandsProps> { // FluxUiComponent<DesignMainStrandsProps> {

  @override
  bool shouldComponentUpdate(Map nextProps, Map nextState) {
    BuiltList<Strand> strands = props.strands;
    BuiltList<Strand> strands_next = nextProps['DesignMainStrandsProps.strands'];
    return !(strands == strands_next);
  }

  @override
  render() {
    //TODO: this gets called (unnecessarily??) on mouseup
//    print('${'*'*100}\nDesignMainStrands.render()');
//    return (Dom.g()..className = 'strands-main-view')([
//      for (Strand strand in this.props.store.strands)
//        (DesignMainStrand()
//          ..store = strand
//          ..key = strand.toString())()
//    ]);

//    List<Strand> strands = this.props.store.strands;
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
