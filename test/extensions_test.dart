// @dart=2.9

import 'package:color/color.dart';
import 'package:scadnano/src/reducers/change_loopout_ext_properties.dart';
import 'package:scadnano/src/reducers/delete_reducer.dart';
import 'package:scadnano/src/reducers/nick_ligate_join_by_crossover_reducers.dart';
import 'package:scadnano/src/state/domain.dart';
import 'package:scadnano/src/state/helix.dart';
import 'package:scadnano/src/state/grid.dart';
import 'package:scadnano/src/state/loopout.dart';
import 'package:scadnano/src/state/extension.dart';
import 'package:scadnano/src/state/select_mode.dart';
import 'package:scadnano/src/state/strand.dart';
import 'package:test/test.dart';

import 'package:scadnano/src/state/design.dart';
import 'package:scadnano/src/actions/actions.dart' as actions;

import 'utils.dart';

main() {
  group('ExtensionsOnStrands', () {
    List<Helix> helices;
    Design design;
    Color color;

    setUp(() {
      helices = [for (int i = 0; i < 6; i++) Helix(idx: i, max_offset: 100, grid: Grid.square)];
      design = Design(helices: helices, grid: Grid.square);
      color = Color.rgb(0, 0, 0);
    });

    test('to_after_3p_extension_should_raise_error', () {
      var sb = design.draw_strand(0, 0).to(10).extension_3p(5);
      expect(() => sb.to(15), throwsException);
    });

    test('move_after_3p_extension_should_raise_error', () {
      var sb = design.draw_strand(0, 0).move(10).extension_3p(5);
      expect(() => sb.move(5), throwsException);
    });

    test('cross_after_5p_extension_should_raise_error', () {
      var sb = design.draw_strand(0, 0).extension_5p(5);
      expect(() => sb.cross(1), throwsException);
    });

    test('cross_after_3p_extension_should_raise_error', () {
      var sb = design.draw_strand(0, 0).to(5).extension_3p(5);
      expect(() => sb.cross(1), throwsException);
    });

    test('extension_3p_after_loopout_should_raise_error', () {
      var sb = design.draw_strand(0, 0).to(10).loopout(1, 3);
      expect(() => sb.extension_3p(5), throwsException);
    });

    test('extension_3p_after_extension_should_raise_error', () {
      var sb = design.draw_strand(0, 0).to(10).extension_3p(4);
      expect(() => sb.extension_3p(5), throwsException);
    });

    test('as_circular_with_3p_extension_should_raise_error', () {
      var sb = design.draw_strand(0, 0).to(10).extension_3p(4);
      expect(() => sb.as_circular(), throwsException);
    });

    test('as_circular_with_5p_extension_should_raise_error', () {
      var sb = design.draw_strand(0, 0).extension_5p(4).to(10);
      expect(() => sb.as_circular(), throwsException);
    });

    test('extension_3p_on_circular_strand_should_raise_error', () {
      var sb = design.draw_strand(0, 0).to(10).as_circular();
      expect(() => sb.extension_3p(4), throwsException);
    });

    test('3p_extension', () {
      design = design.draw_strand(0, 0).to(10).extension_3p(5).with_color(color).commit();

      var expected_strand = Strand([
        Domain(helix: 0, forward: true, start: 0, end: 10),
        Extension(num_bases: 5, is_5p: false),
      ], color: color);
      expect(design.strands.length, 1);
      expect(design.strands[0], expected_strand);
    });

    test('5p_extension', () {
      design = design.draw_strand(0, 0).extension_5p(5).to(10).with_color(color).commit();

      var expected_strand = Strand([
        Extension(num_bases: 5, is_5p: true),
        Domain(helix: 0, forward: true, start: 0, end: 10),
      ], color: color);
      expect(design.strands.length, 1);
      expect(design.strands[0], expected_strand);
    });

    test('move_after_5p_extension_ok', () {
      design = design.draw_strand(0, 0).extension_5p(5).move(15).with_color(color).commit();

      var expected_strand = Strand([
        Extension(num_bases: 5, is_5p: true),
        Domain(helix: 0, forward: true, start: 0, end: 15),
      ], color: color);
      expect(design.strands.length, 1);
      expect(design.strands[0], expected_strand);
    });

    test('extension_3p_with_label', () {
      design = design
          .draw_strand(0, 0)
          .to(10)
          .extension_3p(5)
          .with_domain_label('ext1')
          .with_color(color)
          .commit();

      var expected_strand = Strand([
        Domain(helix: 0, forward: true, start: 0, end: 10),
        Extension(num_bases: 5, label: 'ext1'),
      ], color: color);
      expect(design.strands.length, 1);
      expect(design.strands[0], expected_strand);
    });

    test('extension_5p_with_label', () {
      design = design
          .draw_strand(0, 0)
          .extension_5p(5)
          .with_domain_label('ext1')
          .to(10)
          .with_color(color)
          .commit();

      var expected_strand = Strand([
        Extension(num_bases: 5, label: 'ext1'),
        Domain(helix: 0, forward: true, start: 0, end: 10),
      ], color: color);
      expect(design.strands.length, 1);
      expect(design.strands[0], expected_strand);
    });

    test('with_sequence_on_3p_extension', () {
      design = design
          .draw_strand(0, 0)
          .to(10)
          .extension_3p(5)
          .with_sequence("A" * 10 + "G" * 5)
          .with_color(color)
          .commit();

      var expected_strand = Strand([
        Domain(helix: 0, forward: true, start: 0, end: 10, dna_sequence: 'A' * 10),
        Extension(num_bases: 5, dna_sequence: 'G' * 5),
      ], color: color);
      expect(design.strands.length, 1);
      expect(design.strands[0], expected_strand);
    });

    test('with_sequence_on_5p_extension', () {
      design = design
          .draw_strand(0, 0)
          .extension_5p(5)
          .to(10)
          .with_sequence("C" * 5 + "T" * 10)
          .with_color(color)
          .commit();

      var expected_strand = Strand([
        Extension(num_bases: 5, dna_sequence: 'C' * 5),
        Domain(helix: 0, forward: true, start: 0, end: 10, dna_sequence: 'T' * 10),
      ], color: color);
      expect(design.strands.length, 1);
      expect(design.strands[0], expected_strand);
    });

    test('with_domain_sequence_on_extension', () {
      design = design
          .draw_strand(0, 0)
          .to(10)
          .extension_3p(5)
          .with_domain_sequence("G" * 5)
          .with_color(color)
          .commit();

      var expected_strand = Strand([
        Domain(helix: 0, forward: true, start: 0, end: 10, dna_sequence: '?' * 10),
        Extension(num_bases: 5, dna_sequence: 'G' * 5),
      ], color: color);
      expect(design.strands.length, 1);
      expect(design.strands[0], expected_strand);
    });

    test('with_domain_sequence_on_extension_and_loopout_and_domain', () {
      var sb = design.draw_strand(0, 0);
      sb.move(3);
      sb.with_domain_sequence('AAA');
      sb.loopout(1, 2);
      sb.with_domain_sequence('CC');
      sb.move(-3);
      sb.with_domain_sequence('GGG');
      sb.extension_3p(4);
      sb.with_domain_sequence('TTTT');
      sb.with_color(color);
      design = sb.commit();

      var expected_strand = Strand([
        Domain(helix: 0, forward: true, start: 0, end: 3, dna_sequence: 'AAA'),
        Loopout(loopout_num_bases: 2, dna_sequence: 'CC', prev_domain_idx: 0),
        Domain(helix: 1, forward: false, start: 0, end: 3, dna_sequence: 'GGG'),
        Extension(num_bases: 4, dna_sequence: 'TTTT'),
      ], color: color);
      expect(design.strands.length, 1);
      expect(design.strands[0], expected_strand);
    });

    test('extension_with_name', () {
      design =
          design.draw_strand(0, 0).to(10).extension_3p(5).with_domain_name('ext1').with_color(color).commit();

      var expected_strand = Strand([
        Domain(helix: 0, forward: true, start: 0, end: 10),
        Extension(num_bases: 5, name: 'ext1'),
      ], color: color);
      expect(design.strands.length, 1);
      expect(design.strands[0], expected_strand);
    });

    test('json_reading', () {
      var json_str = '''
{
  "version": "0.17.3",
  "grid": "square",
  "helices": [
    {"grid_position": [0, 0]},
    {"grid_position": [0, 1]},
    {"grid_position": [0, 2]}
  ],
  "strands": [
    {
      "color": "#000000",
      "domains": [
        {"extension_num_bases": 5, "display_length": 2, "display_angle": 30},
        {"helix": 0, "forward": true, "start": 0, "end": 16},
        {"helix": 1, "forward": false, "start": 0, "end": 16},
        {"loopout": 3},
        {"helix": 2, "forward": true, "start": 0, "end": 16},
        {"extension_num_bases": 7, "name": "ext_3p"}
      ]
    }
  ]
}
''';
      var design = Design.from_json_str(json_str);
      var expected_strand = Strand([
        Extension(num_bases: 5, display_length: 2, display_angle: 30),
        Domain(helix: 0, forward: true, start: 0, end: 16),
        Domain(helix: 1, forward: false, start: 0, end: 16),
        Loopout(loopout_num_bases: 3, prev_domain_idx: 2),
        Domain(helix: 2, forward: true, start: 0, end: 16),
        Extension(num_bases: 7, name: 'ext_3p'),
      ], color: color);
      expect(design.strands.length, 1);
      expect(design.strands[0], expected_strand);
    });
  });
}
