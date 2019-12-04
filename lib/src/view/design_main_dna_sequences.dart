import 'package:over_react/over_react.dart';
import 'package:built_collection/built_collection.dart';

import '../state/strand.dart';
import 'design_main_dna_sequence.dart';

part 'design_main_dna_sequences.over_react.g.dart';

@Factory()
UiFactory<DesignMainDNASequencesProps> DesignMainDNASequences = _$DesignMainDNASequences;

@Props()
class _$DesignMainDNASequencesProps extends UiProps {
  bool show_dna;
  BuiltList<Strand> strands;
}

@Component2()
class DesignMainDNASequencesComponent extends UiComponent2<DesignMainDNASequencesProps> {
  @override
  bool shouldComponentUpdate(Map nextProps, Map nextState) {
    bool show_dna = nextProps['DesignMainDNASequencesProps.show_dna'];
    if (!show_dna && !props.show_dna) {
      // even if strands are updated, don't bother rendering if we aren't showing DNA previously or now
      return false;
    }
    BuiltList<Strand> strands = nextProps['DesignMainDNASequencesProps.strands'];
    return !(show_dna == props.show_dna && strands == props.strands);
  }

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

