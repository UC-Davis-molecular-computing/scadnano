// @dart=2.9

import 'package:color/color.dart';
import 'package:scadnano/src/reducers/change_loopout_length.dart';
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

    test('3p_extension', () {
      var sb = design.draw_strand(0, 0);
      sb.to(10);
      sb.extension_3p(5);
      sb.with_color(color);
      design = sb.commit();

      var expected_strand = Strand([
        Domain(helix: 0, forward: true, start: 0, end: 10),
        Extension(num_bases: 5, is_5p: false),
      ], color: color);
      expect(design.strands.length, 1);
      expect(design.strands[0], expected_strand);
    });
  });
}
/*

    def test_strand__3p_extension(self) -> None:
        design = self.design_6helix
        sb = design.draw_strand(0, 0)
        sb.to(10)

        sb.extension_3p(5)

        expected_strand: sc.Strand = sc.Strand([
            sc.Domain(0, True, 0, 10),
            sc.Extension(num_bases=5),
        ])
        self.assertEqual(1, len(design.strands))
        self.assertEqual(expected_strand, design.strands[0])

    def test_strand__5p_extension(self) -> None:
        design = self.design_6helix
        sb = design.draw_strand(0, 0)
        sb.extension_5p(5)
        sb.to(10)

        expected_strand: sc.Strand = sc.Strand([
            sc.Extension(5),
            sc.Domain(0, True, 0, 10),
        ])

        self.assertEqual(1, len(design.strands))
        self.assertEqual(expected_strand, design.strands[0])

    def test_strand__update_to_after_5p_extension_ok(self) -> None:
        design = self.design_6helix
        sb = design.draw_strand(0, 0)
        sb.extension_5p(5)

        sb.to(10)
        sb.update_to(15)

        expected_strand: sc.Strand = sc.Strand([
            sc.Extension(5),
            sc.Domain(0, True, 0, 15),
        ])

        self.assertEqual(1, len(design.strands))
        self.assertEqual(expected_strand, design.strands[0])

    def test_strand__move_after_5p_extension_ok(self) -> None:
        design = self.design_6helix
        sb = design.draw_strand(0, 0)
        sb.extension_5p(5)

        sb.move(15)

        expected_strand: sc.Strand = sc.Strand([
            sc.Extension(5),
            sc.Domain(0, True, 0, 15),
        ])

        self.assertEqual(1, len(design.strands))
        self.assertEqual(expected_strand, design.strands[0])

    def test_strand__to_after_3p_extension_should_raise_error(self) -> None:
        design = self.design_6helix
        sb = design.draw_strand(0, 0)
        sb.to(10)
        sb.extension_3p(5)

        with self.assertRaises(sc.IllegalDesignError):
            sb.to(15)

    def test_strand__move_after_3p_extension_should_raise_error(self) -> None:
        design = self.design_6helix
        sb = design.draw_strand(0, 0)
        sb.move(10)
        sb.extension_3p(5)

        with self.assertRaises(sc.IllegalDesignError):
            sb.move(5)

    def test_strand__cross_after_5p_extension_should_raise_error(self) -> None:
        design = self.design_6helix
        sb = design.draw_strand(0, 0)
        sb.extension_5p(5)

        with self.assertRaises(sc.IllegalDesignError):
            sb.cross(1)

    def test_strand__cross_after_3p_extension_should_raise_error(self) -> None:
        design = self.design_6helix
        sb = design.draw_strand(0, 0)
        sb.to(5)
        sb.extension_3p(5)

        with self.assertRaises(sc.IllegalDesignError):
            sb.cross(1)

    def test_strand__extension_3p_after_loopout_should_raise_error(self) -> None:
        design = self.design_6helix
        sb = design.draw_strand(0, 0)
        sb.to(10)
        sb.loopout(1, 3)

        with self.assertRaises(sc.IllegalDesignError):
            sb.extension_3p(5)

    def test_strand__extension_3p_after_extension_should_raise_error(self) -> None:
        design = self.design_6helix
        sb = design.draw_strand(0, 0)
        sb.to(10)
        sb.extension_3p(4)

        with self.assertRaises(sc.IllegalDesignError):
            sb.extension_3p(5)

    def test_strand__update_to_after_3p_extension_should_raise_error(self) -> None:
        design = self.design_6helix
        sb = design.draw_strand(0, 0)
        sb.to(10)
        sb.extension_3p(4)

        with self.assertRaises(sc.IllegalDesignError):
            sb.update_to(15)

    def test_strand__as_circular_with_3p_extension_should_raise_error(self) -> None:
        design = self.design_6helix
        sb = design.draw_strand(0, 0)
        sb.to(10)
        sb.extension_3p(4)

        with self.assertRaises(sc.IllegalDesignError):
            sb.as_circular()

    def test_strand__as_circular_with_5p_extension_should_raise_error(self) -> None:
        design = self.design_6helix
        sb = design.draw_strand(0, 0)
        sb.extension_5p(4)
        sb.to(10)

        with self.assertRaises(sc.IllegalDesignError):
            sb.as_circular()

    def test_strand__extension_3p_on_circular_strand_should_raise_error(self) -> None:
        design = self.design_6helix
        sb = design.draw_strand(0, 0)
        sb.to(10)
        sb.as_circular()

        with self.assertRaises(sc.IllegalDesignError):
            sb.extension_3p(4)

    def test_strand__extension_3p_with_label(self) -> None:
        design = self.design_6helix
        sb = design.draw_strand(0, 0)
        sb.to(10)
        sb.extension_3p(5)
        sb.with_domain_label("ext1")

        expected_strand: sc.Strand = sc.Strand([
            sc.Domain(0, True, 0, 10),
            sc.Extension(5, label="ext1"),
        ])
        self.assertEqual(1, len(design.strands))
        self.assertEqual(expected_strand, design.strands[0])

    def test_strand__extension_5p_with_label(self) -> None:
        design = self.design_6helix
        sb = design.draw_strand(0, 0)
        sb.extension_5p(5)
        sb.with_domain_label("ext1")
        sb.to(10)

        expected_strand: sc.Strand = sc.Strand([
            sc.Extension(5, label="ext1"),
            sc.Domain(0, True, 0, 10)
        ])

    def test_strand__with_sequence_on_3p_extension(self) -> None:
        design = self.design_6helix
        sb = design.draw_strand(0, 0)
        sb.to(10)
        sb.extension_3p(5)
        sb.with_sequence("A" * 10 + "G" * 5)

        expected_strand: sc.Strand = sc.Strand([
            sc.Domain(0, True, 0, 10, dna_sequence="A" * 10),
            sc.Extension(5, dna_sequence="G" * 5),
        ])
        self.assertEqual(1, len(design.strands))
        self.assertEqual(expected_strand, design.strands[0])

    def test_strand__with_sequence_on_5p_extension(self) -> None:
        design = self.design_6helix
        sb = design.draw_strand(0, 0)
        sb.extension_5p(5)
        sb.to(10)
        sb.with_sequence("C" * 5 + "T" * 10)

        expected_strand: sc.Strand = sc.Strand([
            sc.Extension(5, dna_sequence="C" * 5),
            sc.Domain(0, True, 0, 10, dna_sequence="T" * 10),
        ])
        self.assertEqual(1, len(design.strands))
        self.assertEqual(expected_strand, design.strands[0])

    def test_strand__with_domain_sequence_on_extension(self) -> None:
        design = self.design_6helix
        sb = design.draw_strand(0, 0)
        sb.to(10)
        sb.extension_3p(5)
        sb.with_domain_sequence("G" * 5)

        expected_strand: sc.Strand = sc.Strand([
            sc.Domain(0, True, 0, 10, dna_sequence="?" * 10),
            sc.Extension(5, dna_sequence="G" * 5),
        ])
        self.assertEqual(1, len(design.strands))
        self.assertEqual(expected_strand, design.strands[0])

    def test_strand__extension_with_name(self) -> None:
        design = self.design_6helix
        sb = design.draw_strand(0, 0)
        sb.to(10)
        sb.extension_3p(5)
        sb.with_domain_name("ext1")

        expected_strand: sc.Strand = sc.Strand([
            sc.Domain(0, True, 0, 10),
            sc.Extension(5, name="ext1"),
        ])
        self.assertEqual(1, len(design.strands))
        self.assertEqual(expected_strand, design.strands[0])
 */
