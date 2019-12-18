import 'package:built_collection/built_collection.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:over_react/over_react.dart';
import 'package:scadnano/src/state/edit_mode.dart';

import '../state/helix.dart';
import '../app.dart';
import '../state/mouseover_data.dart';
import '../state/app_state.dart';

part 'design_footer.over_react.g.dart';

UiFactory<_$DesignFooterProps> ConnectedDesignFooter = connect<AppState, _$DesignFooterProps>(
  mapStateToProps: (state) => (DesignFooter()
    ..show_mouseover_rect = state.ui_state.edit_modes.contains(EditModeChoice.backbone)
    ..mouseover_datas = state.ui_state.mouseover_datas),
)(DesignFooter);

@Factory()
UiFactory<DesignFooterProps> DesignFooter = _$DesignFooter;

@Props()
class _$DesignFooterProps extends UiProps { // FluxUiProps<MouseoverDataStore, MouseoverDataStore> {
  BuiltList<MouseoverData> mouseover_datas;
  bool show_mouseover_rect;
}

@Component2()
class DesignFooterComponent extends UiComponent2<DesignFooterProps> { // FluxUiComponent<DesignFooterProps> {
  @override
  render() {
    BuiltList<MouseoverData> mouseover_datas = props.mouseover_datas;

    String text = '';
    if (mouseover_datas.length == 1) {
      MouseoverData mouseover_data = mouseover_datas.first;
      Helix helix = mouseover_data.helix;
      int idx = helix.idx;
      int offset = mouseover_data.offset;
      text = 'helix: ${idx}, offset: ${offset}';
      if (mouseover_data.substrand != null) {
        int substrand_length = mouseover_data.substrand.dna_length();
        var strand = app.state.dna_design.substrand_to_strand[mouseover_data.substrand];
        text += (', ' +
            'substrand length: ${substrand_length}, ' +
            'strand length: ${strand.dna_length()}, ' +
            (strand.idt != null ? 'strand IDT name: ${strand.idt.name}' : ''));
        ;
      }
    } else {
//      String key = String.fromCharCodes([constants.KEY_CODE_MOUSEOVER_HELIX_VIEW_INFO]);
      String key = EditModeChoice.backbone.shortcut_key();
      if (props.show_mouseover_rect) {
        text = 'You can now view data about objects by placing the cursor over them, '
            'but you will not be able to select them. To enable selecting them, press the $key key again.';
      } else {
        text = 'To see data about the helix and strands, '
            'press the $key key and then place the cursor over the object you wish to inspect.';
      }
    }
    return (Dom.span()..className = 'footer-mouse-over-paragraph')(text);
  }
}
