import 'package:over_react/over_react.dart';
import 'package:built_collection/built_collection.dart';

import '../model/composite_stores.dart';
import '../model/strand.dart';
import 'design_main_dna_sequence.dart';

part 'design_main_dna_sequences.over_react.g.dart';

@Factory()
UiFactory<DesignMainDNASequencesProps> DesignMainDNASequences = _$DesignMainDNASequences;

@Props()
class _$DesignMainDNASequencesProps extends UiProps { // FluxUiProps<DNASequencesStore, DNASequencesStore> {
  bool show_dna;
  BuiltList<Strand> strands;
}

@Component2()
class DesignMainDNASequencesComponent extends UiComponent2<DesignMainDNASequencesProps> { // FluxUiComponent<DesignMainDNASequencesProps> {
  @override
  Map getDefaultProps() => (newProps());

  @override
  render() {
    bool show_dna = this.props.show_dna;
    BuiltList<Strand> strands = this.props.strands;

    if (!show_dna) {
      return null;
    } else {
      return (Dom.g()
        ..className = 'dna-sequences-main-view')([
        for (Strand strand in strands)
          if (strand.dna_sequence != null)
//            (DesignMainDNASequence()
            (ConnectedDesignMainDNASequence()
              ..key = strand.toString()
              ..className = 'strand-dna-sequence-elts'
              ..strand = strand)()
      ]);
    }
  }
}

