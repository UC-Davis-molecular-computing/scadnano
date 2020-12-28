import 'package:built_collection/built_collection.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:over_react/over_react.dart';
import '../state/edit_mode.dart';
import '../state/strand.dart';

import '../state/helix.dart';
import '../state/mouseover_data.dart';
import '../state/app_state.dart';

part 'design_footer.over_react.g.dart';

UiFactory<DesignFooterProps> ConnectedDesignFooter = connect<AppState, DesignFooterProps>(
  mapStateToPropsWithOwnProps: (state, props) {
    BuiltList<MouseoverData> mouseover_datas = state.ui_state.mouseover_datas;
    MouseoverData first_mouseover_data =
        mouseover_datas.isNotEmpty ? state.ui_state.mouseover_datas.first : null;
    Strand strand_first_mouseover_data =
        mouseover_datas.isNotEmpty ? state.design.substrand_to_strand[first_mouseover_data.domain] : null;
    String loaded_filename = state.ui_state.loaded_filename;
    return (DesignFooter()
      ..show_mouseover_rect = state.ui_state.edit_modes.contains(EditModeChoice.backbone)
      ..mouseover_datas = state.ui_state.mouseover_datas
      ..strand_first_mouseover_data = strand_first_mouseover_data
      ..loaded_filename = loaded_filename);
  },
)(DesignFooter);

UiFactory<DesignFooterProps> DesignFooter = _$DesignFooter;

mixin DesignFooterProps on UiProps {
  BuiltList<MouseoverData> mouseover_datas;
  bool show_mouseover_rect;
  Strand strand_first_mouseover_data;
  String loaded_filename;
}

class DesignFooterComponent extends UiComponent2<DesignFooterProps> {
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
      if (mouseover_data.domain != null) {
        int domain_length = mouseover_data.domain.dna_length();
        var strand = props.strand_first_mouseover_data;
        text += (', ' +
            'domain length: ${domain_length}, ' +
            'strand length: ${strand.dna_length()}, ' +
            (strand.name != null ? 'strand name: ${strand.name} ' : ''));
        ;
      }
    } else {
//      String key = String.fromCharCodes([constants.KEY_CODE_MOUSEOVER_HELIX_VIEW_INFO]);
//      String key = EditModeChoice.backbone.shortcut_key();
//      if (props.show_mouseover_rect) {
//        text = 'You can now view data about objects by placing the cursor over them, '
//            'but you will not be able to select them. To enable selecting them, press the $key key again.';
//      } else {
//        text = 'To see data about the helix and strands, '
//            'press the $key key and then place the cursor over the object you wish to inspect.';
//      }
      text = props.loaded_filename;
    }
    return (Dom.span()..className = 'design-footer-mouse-over-paragraph')(text);
  }
}
