import 'package:over_react/over_react.dart';

import '../model/composite_stores.dart';
import '../model/strand.dart';
import 'design_main_dna_sequence.dart';

part 'design_main_dna_sequences.over_react.g.dart';

@Factory()
UiFactory<DesignMainDNASequencesProps> DesignMainDNASequences = _$DesignMainDNASequences;

@Props()
class _$DesignMainDNASequencesProps extends FluxUiProps<DNASequencesStore, DNASequencesStore> {}

@Component()
class DesignMainDNASequencesComponent extends FluxUiComponent<DesignMainDNASequencesProps> {
  @override
  Map getDefaultProps() => (newProps());

  @override
  render() {
    if (!this.props.store.show_dna_store.show_dna) {
      return null;
    } else {
      return (Dom.g()
        ..className = 'dna-sequences-main-view')([
        for (Strand strand in this.props.store.strands_store.strands)
          if (strand.dna_sequence != null)
            (DesignMainDNASequence()
              ..key = strand.toString()
              ..className = 'strand-dna-sequence-elts'
              ..strand = strand)()
      ]);
    }
  }
}
