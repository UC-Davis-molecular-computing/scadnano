import 'package:over_react/over_react.dart';

import '../model/strand.dart';
import 'design_main_strand.dart';

part 'design_main_strands.over_react.g.dart';

@Factory()
UiFactory<DesignMainStrandsProps> DesignMainStrands = _$DesignMainStrands;

@Props()
class _$DesignMainStrandsProps extends FluxUiProps<StrandsStore, StrandsStore> {}

@Component()
class DesignMainStrandsComponent extends FluxUiComponent<DesignMainStrandsProps> {
  @override
  Map getDefaultProps() => (newProps());

  @override
  render() {
//    return (Dom.g()..className = 'strands-main-view')([
//      for (Strand strand in this.props.store.strands)
//        (DesignMainStrand()
//          ..store = strand
//          ..key = strand.toString())()
//    ]);
    List strand_elts = [];
    List<Strand> strands = this.props.store.strands;
    for (Strand strand in strands) {
      var strand_elt = (DesignMainStrand()
        //TODO: see whether it matters if key stays same even when Strand changes
        // (toString does not depend on on parts of Strand currently)
        ..store = strand
        ..key = strand.toString())();
      strand_elts.add(strand_elt);
    }
    return (Dom.g()..className = 'strands-main-view')(strand_elts);
  }
}
