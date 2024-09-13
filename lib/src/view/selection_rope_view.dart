import 'package:over_react/over_react_redux.dart';
import 'package:over_react/over_react.dart';

import '../app.dart';
import '../state/selection_rope.dart';

part 'selection_rope_view.over_react.g.dart';

UiFactory<SelectionRopeViewProps> ConnectedSelectionRopeView = connect<SelectionRope, SelectionRopeViewProps>(
  mapStateToPropsWithOwnProps: (rope, props) {
    return SelectionRopeView()
      ..selection_rope = rope
      ..stroke_width_getter = props.stroke_width_getter
      ..id_ = props.id_
      ..is_main = props.is_main;
  },
  context: app.context_selection_rope,
)(SelectionRopeView);

UiFactory<SelectionRopeViewProps> SelectionRopeView = _$SelectionRopeView;

mixin SelectionRopeViewProps on UiProps {
  SelectionRope? selection_rope;
  num Function()? stroke_width_getter;
  String? id_;
  bool? is_main;
}

class SelectionRopeViewComponent extends UiComponent2<SelectionRopeViewProps> {
  @override
  render() {
    SelectionRope? rope = props.selection_rope;
    if (rope == null || props.stroke_width_getter == null || props.id_ == null || props.is_main == null) {
      return null;
    }
    num stroke_width = props.stroke_width_getter!();

    if (rope == null) {
      return null;
    }
    if (props.is_main! != rope.is_main) {
      return null;
    }

    if (rope.points.length == 0) {
      return null;
    } else {
      var points_str = [for (var point in rope.points) '${point.x},${point.y} '];

      bool potential_is_illegal = rope.potential_is_illegal();
      var points_str_potential = List<String>.from(points_str);
      bool draw_potential = rope.current_point != null;
      if (draw_potential) {
        points_str_potential.add('${rope.current_point!.x},${rope.current_point!.y}');
      }

      return [
        (Dom.polygon()
          ..points = points_str
          ..strokeWidth = stroke_width
          ..id = props.id_
          ..className = 'selection-rope'
          ..key = 'selection-rope')(),
        if (draw_potential)
          (Dom.polygon()
            ..points = points_str_potential
            ..strokeWidth = stroke_width
            ..id = props.id_
            ..className = 'selection-rope-potential${potential_is_illegal ? "-illegal" : ""}'
            ..key = 'selection-rope-potential')(),
      ];
    }
  }
}
