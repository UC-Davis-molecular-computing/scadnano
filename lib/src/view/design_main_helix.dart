//part of '../components.dart';

//library view_helix_react;

import 'package:quiver/iterables.dart' as iter;

import 'package:over_react/over_react.dart';
import 'package:react/react_client.dart';

import '../model/helix.dart';
import '../app.dart';
import '../constants.dart' as constants;

part 'design_main_helix.over_react.g.dart';

@Factory()
UiFactory<DesignMainHelixProps> DesignMainHelix = _$DesignMainHelix;

@Props()
class _$DesignMainHelixProps extends FluxUiProps<Helix, Helix> {}

@Component()
class DesignMainHelixComponent extends FluxUiComponent<DesignMainHelixProps> {
  @override
  Map getDefaultProps() => (newProps());

  @override
  render() {
    Helix helix = this.props.store;
    // for helix circles
    var cx = -(2 * constants.BASE_WIDTH_SVG + constants.DISTANCE_BETWEEN_HELICES_SVG / 2);
    var cy = constants.BASE_WIDTH_SVG;

    // for helix horizontal lines
    num width = helix.svg_width();
    num height = helix.svg_height();

    var vert_line_paths = this._vert_line_paths();
    int idx = helix.idx();

    return (Dom.g()
      ..className = 'helix-main-view'
      ..transform = helix.translate())(
      (Dom.circle()
        ..className = 'helix-circle-main-view'
        ..cx = '$cx'
        ..cy = '$cy'
        ..r = '${constants.DISTANCE_BETWEEN_HELICES_SVG / 2.0}')(),
      (Dom.text()
        ..className = 'helix-text-main-view'
        ..x = '$cx'
        ..y = '$cy')('$idx'),
      (Dom.path()
        ..className = 'helix-lines helix-horz-line'
        ..d = 'M 0 0 H $width M 0 ${height / 2.0} H $width M 0 $height H $width')(),
      (Dom.path()
        ..className = 'helix-lines helix-vert-minor-line'
        ..d = vert_line_paths['minor'])(),
      (Dom.path()
        ..className = 'helix-lines helix-vert-major-line'
        ..d = vert_line_paths['major'])(),
    );
  }

  /// Return Map mapping 'minor' and 'major' to paths describing minor and major vertical lines.
  Map<String, String> _vert_line_paths() {
    List<int> regularly_spaced_ticks(int distance, int end) {
      if (distance < 0) {
        throw ArgumentError('distance between major ticks must be positive');
      } else if (distance == 0) {
        return [];
      } else {
        return [for (int offset in iter.range(0, end + 1, distance)) offset];
      }
    }

    Helix helix = this.props.store;
    var major_tick_distance = helix.has_major_tick_distance()
        ? helix.major_tick_distance
        : app.model.dna_design.major_tick_distance;
    Set<int> major_ticks = (helix.has_major_ticks()
            ? helix.major_ticks
            : regularly_spaced_ticks(major_tick_distance, helix.max_bases))
        .toSet();

    List<String> path_cmds_vert_minor = [];
    List<String> path_cmds_vert_major = [];

    num x = 0;
    for (int base = 0; base <= helix.max_bases; base++) {
      var path_cmds = major_ticks.contains(base) ? path_cmds_vert_major : path_cmds_vert_minor;
      path_cmds.add('M $x 0');
      path_cmds.add('v ${helix.svg_height()}');
      x += constants.BASE_WIDTH_SVG;
    }

    return {'minor': path_cmds_vert_minor.join(' '), 'major': path_cmds_vert_major.join(' ')};
  }
}
