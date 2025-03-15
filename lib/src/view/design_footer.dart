import 'package:built_collection/built_collection.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:over_react/over_react.dart';
import '../state/domain.dart';
import '../state/edit_mode.dart';
import '../state/strand.dart';

import '../state/helix.dart';
import '../state/mouseover_data.dart';
import '../state/app_state.dart';

part 'design_footer.over_react.g.dart';

DesignFooterProps set_design_footer_props(DesignFooterProps elt, AppState state) {
  BuiltList<MouseoverData> mouseover_datas = state.ui_state.mouseover_datas;
  MouseoverData? first_mouseover_data = mouseover_datas.isNotEmpty ? mouseover_datas.first : null;
  Strand? strand_first_mouseover_data =
      mouseover_datas.isNotEmpty ? state.design.substrand_to_strand[first_mouseover_data!.domain] : null;
  String loaded_filename = state.ui_state.loaded_filename;
  return elt
    ..mouseover_datas = mouseover_datas
    ..strand_first_mouseover_data = strand_first_mouseover_data
    ..loaded_filename = loaded_filename;
}

// https://github.com/Workiva/over_react/issues/942
UiFactory<DesignFooterProps> ConnectedDesignFooter = connect<AppState, DesignFooterProps>(
  mapStateToProps: (state) => set_design_footer_props(DesignFooter(), state),
)(DesignFooter);

UiFactory<DesignFooterProps> DesignFooter = _$DesignFooter;

mixin DesignFooterProps on UiProps {
  late BuiltList<MouseoverData> mouseover_datas;
  Strand? strand_first_mouseover_data;
  String? loaded_filename;
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
      Domain? domain = mouseover_data.domain;
      if (domain != null) {
        int domain_length = domain.dna_length();
        Strand? strand = props.strand_first_mouseover_data;
        text +=
            (', strand DNA index: ${mouseover_data.strand_idx}' +
                ', domain length: ${domain_length}' +
                ', strand length: ${strand?.dna_length}' +
                (domain.name != null ? ', domain name: ${domain.name}' : '') +
                (domain.label != null ? ', domain label: ${domain.label}' : '') +
                (strand?.name != null ? ', strand name: ${strand!.name}' : '') +
                (strand?.label != null ? ', strand label: ${strand!.label}' : ''));
        ;
      }
    } else {
      text = props.loaded_filename ?? '';
    }
    return (Dom.span()..className = 'design-footer-mouse-over-paragraph')(text);
  }
}
