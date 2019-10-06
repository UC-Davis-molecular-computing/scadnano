import 'package:scadnano/src/model/helix.dart';

import '../model/mouseover_data.dart';

//TODO: use tooltips (or something) to give more information on mouse hover than the footer has room for

import 'package:over_react/over_react.dart';

part 'design_footer.over_react.g.dart';

@Factory()
UiFactory<DesignFooterProps> DesignFooter = _$DesignFooter;

@Props()
class _$DesignFooterProps extends FluxUiProps<MouseoverDataStore, MouseoverDataStore> {}

@Component()
class DesignFooterComponent extends FluxUiComponent<DesignFooterProps> {
  @override
  Map getDefaultProps() => (newProps());

  @override
  render() {
    List<MouseoverData> mouseover_datas = this.props.store.data;
    String text = '';
    if (mouseover_datas.length == 1) {
      MouseoverData mouseover_data = mouseover_datas.first;
      Helix helix = mouseover_data.helix;
      int idx = helix.idx();
      int offset = mouseover_data.offset;
      text = 'helix: ${idx}, offset: ${offset}';
      if (mouseover_data.substrand != null) {
        int substrand_length = mouseover_data.substrand.dna_length();
        var strand = mouseover_data.substrand.strand;
        text += (', ' +
            'substrand length: ${substrand_length}, ' +
            'strand length: ${strand.dna_length()}, ' +
            (strand.idt != null ? 'strand IDT name: ${strand.idt.name}' : ''));
        ;
      }
    }
    return (Dom.span()..className = 'footer-mouse-over-paragraph')(text);
  }
}
