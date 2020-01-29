import 'package:over_react/over_react.dart';
import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/state/helix.dart';
import 'package:scadnano/src/view/pure_component.dart';

import '../state/strand.dart';
import 'design_main_dna_sequence.dart';

part 'design_main_dna_sequences.over_react.g.dart';

@Factory()
UiFactory<DesignMainDNASequencesProps> DesignMainDNASequences = _$DesignMainDNASequences;

@Props()
class _$DesignMainDNASequencesProps extends UiProps {
  BuiltList<Helix> helices;
  BuiltList<Strand> strands;
  BuiltSet<int> side_selected_helix_idxs;
}

@Component2()
class DesignMainDNASequencesComponent extends UiComponent2<DesignMainDNASequencesProps> with PureComponent {
  @override
  render() {
    return (Dom.g()..className = 'dna-sequences-main-view')([
      for (Strand strand in props.strands)
        if (strand.dna_sequence != null)
          (DesignMainDNASequence()
//            (ConnectedDesignMainDNASequence()
            ..helices = props.helices
            ..strand = strand
            ..side_selected_helix_idxs = props.side_selected_helix_idxs
            ..key = strand.toString()
            ..className = 'strand-dna-sequence-elts')()
    ]);
  }
}
