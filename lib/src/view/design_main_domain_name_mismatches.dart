import 'package:over_react/over_react.dart';
import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/state/group.dart';
import 'package:scadnano/src/state/helix.dart';

import '../state/design.dart';
import '../state/strand.dart';
import '../state/domain.dart';
import 'pure_component.dart';
import 'design_main_mismatch.dart';
import '../util.dart' as util;

part 'design_main_domain_name_mismatches.over_react.g.dart';

UiFactory<DesignMainDomainNameMismatchesProps> DesignMainDomainNameMismatches =
    _$DesignMainDomainNameMismatches;

mixin DesignMainDomainNameMismatchesProps on UiProps {
  Design design;
  bool only_display_selected_helices;
  BuiltSet<int> side_selected_helix_idxs;
}

class DesignMainDomainNameMismatchesComponent extends UiComponent2<DesignMainDomainNameMismatchesProps>
    with PureComponent {
  @override
  render() {
    List<ReactElement> mismatch_components = this._create_mismatch_components();
    return (Dom.g()..className = 'domain-name-mismatches-main-view')(mismatch_components);
  }

  List<ReactElement> _create_mismatch_components() {
    List<ReactElement> mismatch_components = [];

    for (int i = 0; i < props.design.helices.length; i++) {
      //props.design.helices.length - 1?
      int distance = props.design.helices[i].calculate_major_ticks()[1] -
          props.design.helices[i].calculate_major_ticks()[0];
      List<Domain> addedSubstrands = [];
      for (int j = 0; j <= props.design.max_offset - 1; j += distance) {
        List<ReactElement> domain_components = [];
        List<Domain> substrands = props.design.substrands_on_helix_at(i, j).toList();
        if (substrands.length >= 2) {
          if (substrands[0].overlaps(substrands[1])) {
            if (_check_if_mismatch(substrands[0], substrands[1])) {
              for (int k = 0; k < substrands.length; k++) {
                if (!addedSubstrands.contains(substrands[k])) {
                  addedSubstrands.add(substrands[k]);
                  double offset = (substrands[k].start + substrands[k].end) / 2;
                  var base_svg_pos =
                      props.design.helices[i].svg_base_pos(offset.toInt(), substrands[k].forward);
                  String key = '${base_svg_pos};${substrands[k].forward}';
                  var mismatch_component = (DesignMainMismatch()
                    ..base_svg_pos = base_svg_pos
                    ..geometry = props.design.geometry
                    ..forward = substrands[k].forward
                    ..key = key)();
                  domain_components.add(mismatch_component);
                  if (domain_components.isNotEmpty) {
                    mismatch_components.add((Dom.g()
                      ..className = 'mismatch-components-in-domain'
                      ..key = util.id_domain(substrands[k]))(domain_components));
                  }
                }
              }
            }
          }
        }
      }
    }
    return mismatch_components;
  }

  bool _check_if_mismatch(Domain substrand1, Domain substrand2) {
    if (substrand1.name.contains('*') == substrand2.name.contains('*')) {
      return true;
    }
    String s1name = substrand1.name;
    String s2name = substrand2.name;
    if (substrand1.name.contains('*')) {
      s1name = substrand1.name.replaceAll('*', '');
    }
    if (substrand2.name.contains('*')) {
      s2name = substrand2.name.replaceAll('*', '');
    }

    if (s1name != s2name) {
      return true;
    } else if (substrand1.start != substrand2.start) {
      return true;
    } else if (substrand1.end != substrand2.end) {
      return true;
    } else {
      return false;
    }
  }
}
