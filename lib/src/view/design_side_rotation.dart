import 'package:over_react/over_react.dart';

import '../model/dna_design.dart';
import '../model/strand.dart';
import '../app.dart';
import '../model/helix.dart';
import 'design_side_rotation_arrow.dart';

part 'design_side_rotation.over_react.g.dart';

@Factory()
UiFactory<DesignSideRotationProps> DesignSideRotation = _$DesignSideRotation;

@Props()
class _$DesignSideRotationProps extends UiProps {
  double radius;
  Helix helix;
  int offset;
}

@Component2()
class DesignSideRotationComponent extends UiComponent2<DesignSideRotationProps> {
  @override
  bool shouldComponentUpdate(Map nextProps, Map nextState) {
    Helix helix_next = nextProps['DesignSideHelixProps.helix'];
    int offset_next = nextProps['DesignSideHelixProps.offset'];
    Helix helix = props.helix;
    int offset = props.offset;
//    print('should DesignSideRotation update? ${!(helix == helix_next && offset == offset_next)}');
//    print('  helix == helix_next?            ${helix == helix_next}');
//    print('  offset == offset_next?          ${offset == offset_next}');
    return !(helix == helix_next && offset == offset_next);
  }

  @override
  render() {
    Helix helix = this.props.helix;
    int offset = this.props.offset;
    num radius = this.props.radius;

//    print('rendering rotation on helix ${helix.idx}');

    DNADesign dna_design = app.state.dna_design;
    var substrands = dna_design.substrands_on_helix_at(helix.idx, offset);

    Strand strand_forward;
    Strand strand_reverse;
    for (var ss in substrands) {
      if (ss.forward) {
        strand_forward = app.state.dna_design.substrand_to_strand[ss];
      } else {
        strand_reverse = app.state.dna_design.substrand_to_strand[ss];
      }
    }

    var rotation_3p = dna_design.helix_rotation_3p(helix, offset);
    var rotation_5p = dna_design.helix_rotation_5p(helix, offset);
    var color_3p = strand_forward == null ? 'black' : strand_forward.color.toHexColor().toCssString();
    var color_5p = strand_reverse == null ? 'black' : strand_reverse.color.toHexColor().toCssString();

    return Dom.g()(
      (DesignSideRotationArrow()
        ..radius = radius
        ..angle_degrees = rotation_3p
        ..color = color_3p
        ..className = 'rotation-arrow')(),
      (DesignSideRotationArrow()
        ..radius = radius
        ..angle_degrees = rotation_5p
        ..color = color_5p
        ..className = 'rotation-arrow')(),
    );
  }
}
