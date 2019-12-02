import 'package:built_collection/built_collection.dart';
import 'package:over_react/over_react_redux.dart';

import '../model/helix.dart';
import '../app.dart';
import '../model/mouseover_data.dart';
import '../model/app_state.dart';

//TODO: use tooltips (or something) to give more information on mouse hover than the footer has room for

import 'package:over_react/over_react.dart';

part 'design_footer.over_react.g.dart';

UiFactory<_$DesignFooterProps> ConnectedDesignFooter = connect<AppState, _$DesignFooterProps>(
  mapStateToProps: (state) => (DesignFooter()
    ..mouseover_datas = state.ui_state.mouseover_datas),
)(DesignFooter);

@Factory()
UiFactory<DesignFooterProps> DesignFooter = _$DesignFooter;

@Props()
class _$DesignFooterProps extends UiProps { // FluxUiProps<MouseoverDataStore, MouseoverDataStore> {
  BuiltList<MouseoverData> mouseover_datas;
}

@Component2()
class DesignFooterComponent extends UiComponent2<DesignFooterProps> { // FluxUiComponent<DesignFooterProps> {
  @override
  Map getDefaultProps() => (newProps());

  @override
  render() {
//    List<MouseoverData> mouseover_datas = this.props.store.data;
    BuiltList<MouseoverData> mouseover_datas = this.props.mouseover_datas;

    String text = '';
    if (mouseover_datas.length == 1) {
      MouseoverData mouseover_data = mouseover_datas.first;
      Helix helix = mouseover_data.helix;
      int idx = helix.idx;
      int offset = mouseover_data.offset;
      text = 'helix: ${idx}, offset: ${offset}';
      if (mouseover_data.substrand != null) {
        int substrand_length = mouseover_data.substrand.dna_length();
//        var strand = mouseover_data.substrand.strand;
        var strand = app.state.dna_design.substrand_to_strand[mouseover_data.substrand];
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
