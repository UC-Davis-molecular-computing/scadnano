// @dart=2.9

import 'dart:math';

import 'package:scadnano/src/state/grid_position.dart';
import 'package:test/test.dart';
import 'package:tuple/tuple.dart';

import 'package:scadnano/src/middleware/oxdna_export.dart';
import 'package:scadnano/src/state/helix.dart';
import 'package:scadnano/src/state/grid.dart';
import 'package:scadnano/src/state/design.dart';

/// Split a string by whitespace
List<String> split_ws(String str) => str.trim().split(RegExp('\\s+'));

/// Sum numbers in a list
num sum(List<num> lst) => lst.reduce((a, b) => a + b);

main() {
  group('OxDNAExport', () {
    double OX_UNITS_TO_NM;
    double NM_TO_OX_UNITS;
    double OX_BASE_DIST;
    double BASES_PER_TURN;
    double HELIX_ANGLE;
    double RISE_PER_BASE_PAIR;
    double EXPECTED_ADJ_NUC_CM_DIST2;
    const eps = 0.0001;

    setUp(() {
      OX_UNITS_TO_NM = 0.8518;
      NM_TO_OX_UNITS = 1.0 / OX_UNITS_TO_NM;
      OX_BASE_DIST = 0.6;
      BASES_PER_TURN = 10.5;
      HELIX_ANGLE = pi * 2 / BASES_PER_TURN;
      RISE_PER_BASE_PAIR = 0.332;
      // square of expected distance between adjacent nucleotide centers of mass
      EXPECTED_ADJ_NUC_CM_DIST2 =
          pow(2 * OX_BASE_DIST * sin(HELIX_ANGLE / 2), 2) + pow(RISE_PER_BASE_PAIR * NM_TO_OX_UNITS, 2);
    });

    test('oxdna_export_basic_design', () {
      /*
      2 double strands of length 7 connected across helices.
                  0      7
        helix 0   [------\
                  +------]\
                  |       |
        helix 1   +------>/
                  <------/
      */
      var helices = [for (int i = 0; i < 2; i++) Helix(idx: i, max_offset: 7, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);
      design = design.strand(0, 0).to(7).cross(1).move(-7).commit();
      design = design.strand(0, 7).move(-7).cross(1).move(7).commit();

      // expected values for verification
      int expected_num_nucleotides = 7 * 4;
      int expected_strand_length = 7 * 2;

      Tuple2<String, String> oxdna_dat_top = to_oxdna_format(design);
      List<String> dat_lines = oxdna_dat_top.item1.trim().split('\n');
      List<String> top_lines = oxdna_dat_top.item2.trim().split('\n');

      // check length of output files are as expected (matches # of nucleotides plus header size)
      expect(dat_lines.length, expected_num_nucleotides + 3);
      expect(top_lines.length, expected_num_nucleotides + 1);

      // find relevant values for nucleotides
      List<List<double>> cm_poss = []; // center of mass position
      List<int> nbrs_3p = [];
      List<int> nbrs_5p = [];

      for (var line in dat_lines.sublist(3)) {
        List<String> data = split_ws(line);
        // make sure there are 15 values per line (3 values per vector * 5 vectors per line)
        // order of vectors: center of mass position, backbone base versor, normal versor, velocity, angular velocity (more info on versors: https://eater.net/quaternions)
        expect(data.length, 15);

        cm_poss.add([for (var x in data.sublist(0, 3)) double.parse(x)]);

        List<double> bb_vec = [for (var x in data.sublist(3, 6)) double.parse(x)]; // backbone base vector
        List<double> nm_vec = [for (var x in data.sublist(6, 9)) double.parse(x)]; // normal vector

        // make sure normal vectors and backbone vectors are unit length
        num sqr_bb_vec = sum([for (var x in bb_vec) x * x]);
        num sqr_nm_vec = sum([for (var x in nm_vec) x * x]);
        expect(sqr_bb_vec, closeTo(1.0, eps));
        expect(sqr_nm_vec, closeTo(1.0, eps));

        for (var val_str in data.sublist(9)) {
          // values for velocity and angular velocity vectors are 0
          double value = double.parse(val_str);
          expect(value, closeTo(0, eps));
        }
      }

      List<int> strand1_idxs = [];
      List<int> strand2_idxs = [];
      int nuc_idx = 0;
      int strand1_start = null;
      int strand2_start = null;
      for (var line in top_lines.sublist(1)) {
        var data = split_ws(line);
        // make sure there are 4 values per line: strand, base, 3' neighbor, 5' neighbor
        expect(data.length, 4);

        // make sure there are only 2 strands
        int strand_num = int.parse(data[0]);
        expect(strand_num, anyOf([equals(1), equals(2)]));
        //expect([1,2], contains(strand_num));
        // make sure base is valid
        String base = data[1];
        expect(base, anyOf([equals('A'), equals('C'), equals('G'), equals('T')]));

        nbrs_3p.add(int.parse(data[2]));
        nbrs_5p.add(int.parse(data[3]));

        // append start of strand (no 5' neighbor) to list of indexes for strand
        int neighbor_5 = int.parse(data[3]);
        if (neighbor_5 == -1) {
          if (strand_num == 1) {
            strand1_start = nuc_idx;
            strand1_idxs.add(strand1_start);
          } else {
            strand2_start = nuc_idx;
            strand2_idxs.add(strand2_start);
          }
        }
        nuc_idx++;
      }

      expect(strand1_start, isNotNull);
      expect(strand2_start, isNotNull);

      // reconstruct strands using indices from oxDNA files
      int next_idx = nbrs_3p[strand1_start];
      while (next_idx >= 0) {
        strand1_idxs.add(next_idx);
        next_idx = nbrs_3p[strand1_idxs.last];
      }

      next_idx = nbrs_3p[strand2_start];
      while (next_idx >= 0) {
        strand2_idxs.add(next_idx);
        next_idx = nbrs_3p[strand2_idxs.last];
      }

      // assert that strands are the correct length
      expect(strand1_idxs.length, expected_strand_length);
      expect(strand2_idxs.length, expected_strand_length);

      for (int i = 0; i < expected_strand_length - 1; i++) {
        // ignore nucleotide distance between domains (on crossover)
        if (i == 6) continue;

        int strand1_nuc_idx1 = strand1_idxs[i];
        int strand1_nuc_idx2 = strand1_idxs[i + 1];
        int strand2_nuc_idx1 = strand2_idxs[i];
        int strand2_nuc_idx2 = strand2_idxs[i + 1];

        // find the center of mass for adjacent nucleotides
        List<double> s1_cmp1 = cm_poss[strand1_nuc_idx1];
        List<double> s1_cmp2 = cm_poss[strand1_nuc_idx2];
        List<double> s2_cmp1 = cm_poss[strand2_nuc_idx1];
        List<double> s2_cmp2 = cm_poss[strand2_nuc_idx2];

        // calculate and verify squared distance between adjacent nucleotides in a domain
        List<num> diff1 = [for (int j = 0; j < 3; j++) s1_cmp1[j] - s1_cmp2[j]];
        List<num> diff2 = [for (int j = 0; j < 3; j++) s2_cmp1[j] - s2_cmp2[j]];
        num sqr_dist1 = sum([for (var x in diff1) x * x]);
        num sqr_dist2 = sum([for (var x in diff2) x * x]);

        expect(sqr_dist1, closeTo(EXPECTED_ADJ_NUC_CM_DIST2, eps));
        expect(sqr_dist2, closeTo(EXPECTED_ADJ_NUC_CM_DIST2, eps));
      }
    });
  });
}

/*


class TestOxdnaExport(unittest.TestCase):
    def setUp(self) -> None:
        self.OX_UNITS_TO_NM = 0.8518
        self.NM_TO_OX_UNITS = 1.0 / self.OX_UNITS_TO_NM
        self.OX_BASE_DIST = 0.6
        self.BASES_PER_TURN = 10.5
        self.HELIX_ANGLE = math.pi * 2 / self.BASES_PER_TURN
        self.RISE_PER_BASE_PAIR = 0.332
        # square of expected distance between adjacent nucleotide centers of mass
        self.EXPECTED_ADJ_NUC_CM_DIST2 = (2 * self.OX_BASE_DIST * math.sin(self.HELIX_ANGLE / 2)) ** 2 + (self.RISE_PER_BASE_PAIR * self.NM_TO_OX_UNITS) ** 2

    def test_basic_design(self) -> None:
        """ 2 double strands of length 7 connected across helices.
                  0      7
        helix 0   [------+
                  +------]
                  |      |
        helix 1   <------+
                  +------>
        """
        helices = [sc.Helix(max_offset=7), sc.Helix(max_offset=7)]
        design = sc.Design(helices=helices, grid=sc.square)
        design.strand(0, 0).to(7).cross(1).move(-7)
        design.strand(0, 7).move(-7).cross(1).move(7)

        # expected values for verification
        expected_num_nucleotides = 7 * 4
        expected_strand_length = 7 * 2

        dat, top = design.to_oxdna_format()
        dat = dat.strip().split('\n')
        top = top.strip().split('\n')

        # check length of output files are as expected (matches # of nucleotides plus header size)
        self.assertEqual(expected_num_nucleotides + 3, len(dat))
        self.assertEqual(expected_num_nucleotides + 1, len(top))

        # find relevant values for nucleotides
        cm_poss = []    # center of mass position
        nbrs_3p = []
        nbrs_5p = []

        for line in dat[3:]:
            data = line.strip().split()
            # make sure there are 15 values per line (3 values per vector * 5 vectors per line)
            # order of vectors: center of mass position, backbone base versor, normal versor, velocity, angular velocity (more info on versors: https://eater.net/quaternions)
            self.assertEqual(15, len(data))

            cm_poss.append(tuple([float(x) for x in data[0:3]]))
            bb_vec = tuple([float(x) for x in data[3:6]])    # backbone base vector
            nm_vec = tuple([float(x) for x in data[6:9]])    # normal vector

            # make sure normal vectors and backbone vectors are unit length
            sqr_bb_vec = sum([x**2 for x in bb_vec])
            sqr_nm_vec = sum([x**2 for x in nm_vec])
            self.assertAlmostEqual(1.0, sqr_bb_vec)
            self.assertAlmostEqual(1.0, sqr_nm_vec)

            for value in data[9:]:    # values for velocity and angular velocity vectors are 0
                self.assertAlmostEqual(0, float(value))

        strand1_idxs = []
        strand2_idxs = []
        for nuc_idx, line in enumerate(top[1:]):
            data = line.strip().split()
            # make sure there are 4 values per line: strand, base, 3' neighbor, 5' neighbor
            self.assertEqual(4, len(data))

            # make sure there are only 2 strands
            strand_num = int(data[0])
            self.assertIn(strand_num, [1, 2])
            # make sure base is valid
            base = data[1]
            self.assertIn(base, ['A', 'C', 'G', 'T'])

            nbrs_3p.append(int(data[2]))
            nbrs_5p.append(int(data[3]))

            # append start of strand (no 5' neighbor) to list of indexes for strand
            neighbor_5 = int(data[3])
            if neighbor_5 == -1:
                if strand_num == 1:
                    strand1_start = nuc_idx
                    strand1_idxs.append(strand1_start)
                else:
                    strand2_start = nuc_idx
                    strand2_idxs.append(strand2_start)

        # reconstruct strands using indices from oxDNA files
        next_idx = nbrs_3p[strand1_start]
        while next_idx >= 0:
            strand1_idxs.append(next_idx)
            next_idx = nbrs_3p[strand1_idxs[-1]]

        next_idx = nbrs_3p[strand2_start]
        while next_idx >= 0:
            strand2_idxs.append(next_idx)
            next_idx = nbrs_3p[strand2_idxs[-1]]

        # assert that strands are the correct length
        self.assertEqual(expected_strand_length, len(strand1_idxs))
        self.assertEqual(expected_strand_length, len(strand2_idxs))

        for i in range(expected_strand_length - 1):
            # ignore nucleotide distance between domains (on crossover)
            if i == 6:
                continue

            strand1_nuc_idx1 = strand1_idxs[i]
            strand1_nuc_idx2 = strand1_idxs[i+1]
            strand2_nuc_idx1 = strand2_idxs[i]
            strand2_nuc_idx2 = strand2_idxs[i+1]

            # find the center of mass for adjacent nucleotides
            s1_cmp1 = cm_poss[strand1_nuc_idx1]
            s1_cmp2 = cm_poss[strand1_nuc_idx2]
            s2_cmp1 = cm_poss[strand2_nuc_idx1]
            s2_cmp2 = cm_poss[strand2_nuc_idx2]

            # calculate and verify squared distance between adjacent nucleotides in a domain
            diff1 = tuple([s1_cmp1[j]-s1_cmp2[j] for j in range(3)])
            diff2 = tuple([s2_cmp1[j]-s2_cmp2[j] for j in range(3)])
            sqr_dist1 = sum([x**2 for x in diff1])
            sqr_dist2 = sum([x**2 for x in diff2])

            self.assertAlmostEqual(self.EXPECTED_ADJ_NUC_CM_DIST2, sqr_dist1)
            self.assertAlmostEqual(self.EXPECTED_ADJ_NUC_CM_DIST2, sqr_dist2)

    def test_honeycomb_design(self) -> None:
        """ A single strand on a honeycomb grid.
                  0       8
        helix 0   [-------+
                          |
        helix 1   +--------
                  |
        helix 2   +------->
        """
        helices = [sc.Helix(grid_position=(1, 1), max_offset=8), sc.Helix(grid_position=(0, 1), max_offset=8), sc.Helix(grid_position=(0, 2), max_offset=8)]
        design = sc.Design(helices=helices, grid=sc.honeycomb)
        design.strand(0, 0).to(8).cross(1).move(-8).cross(2).to(8)

        # expected values for verification
        expected_num_nucleotides = 8 * 3
        expected_strand_length = 8 * 3

        dat, top = design.to_oxdna_format()
        dat = dat.strip().split('\n')
        top = top.strip().split('\n')

        # check length of output files are as expected (matches # of nucleotides plus header size)
        self.assertEqual(expected_num_nucleotides + 3, len(dat))
        self.assertEqual(expected_num_nucleotides + 1, len(top))

        # find relevant values for nucleotides
        cm_poss = []  # center of mass position
        nbrs_3p = []
        nbrs_5p = []

        for line in dat[3:]:
            data = line.strip().split()
            # make sure there are 15 values per line (3 values per vector * 5 vectors per line)
            # order of vectors: center of mass position, backbone base, normal, velocity, angular velocity
            self.assertEqual(15, len(data))

            cm_poss.append(tuple([float(x) for x in data[0:3]]))
            bb_vec = tuple([float(x) for x in data[3:6]])  # backbone base vector
            nm_vec = tuple([float(x) for x in data[6:9]])  # normal vector

            # make sure normal vectors and backbone vectors are unit length
            sqr_bb_vec = sum([x ** 2 for x in bb_vec])
            sqr_nm_vec = sum([x ** 2 for x in nm_vec])
            self.assertAlmostEqual(1.0, sqr_bb_vec)
            self.assertAlmostEqual(1.0, sqr_nm_vec)

            for value in data[9:]:  # values for velocity and angular velocity vectors are 0
                self.assertAlmostEqual(0, float(value))

        strand1_idxs = []
        for nuc_idx, line in enumerate(top[1:]):
            data = line.strip().split()
            # make sure there are 4 values per line: strand, base, 3' neighbor, 5' neighbor
            self.assertEqual(4, len(data))

            # make sure there's only 1 strand
            strand_num = int(data[0])
            self.assertEqual(1, strand_num)
            # make sure base is valid
            base = data[1]
            self.assertIn(base, ['A', 'C', 'G', 'T'])

            nbrs_3p.append(int(data[2]))
            nbrs_5p.append(int(data[3]))

            # append start of strand (no 5' neighbor) to list of indexes for strand
            neighbor_5 = int(data[3])
            if neighbor_5 == -1:
                strand1_start = nuc_idx
                strand1_idxs.append(strand1_start)

        # reconstruct strand using indices from oxDNA files
        next_idx = nbrs_3p[strand1_start]
        while next_idx >= 0:
            strand1_idxs.append(next_idx)
            next_idx = nbrs_3p[strand1_idxs[-1]]

        # assert that strand is correct length
        self.assertEqual(expected_strand_length, len(strand1_idxs))

        for i in range(expected_strand_length - 1):
            # ignore nucleotide distances between domains (on crossovers)
            if i == 7:
                continue

            if i == 15:
                continue

            strand1_nuc_idx1 = strand1_idxs[i]
            strand1_nuc_idx2 = strand1_idxs[i + 1]

            # find the center of mass for adjacent nucleotides
            s1_cmp1 = cm_poss[strand1_nuc_idx1]
            s1_cmp2 = cm_poss[strand1_nuc_idx2]

            # calculate and verify squared distance between adjacent nucleotides in a domain
            diff1 = tuple([s1_cmp1[j] - s1_cmp2[j] for j in range(3)])
            sqr_dist1 = sum([x ** 2 for x in diff1])

            self.assertAlmostEqual(self.EXPECTED_ADJ_NUC_CM_DIST2, sqr_dist1)

    def test_deletion_design(self) -> None:
        """
        0      7
        [---X-->
        """
        helix = [sc.Helix(max_offset=7)]
        design = sc.Design(helices=helix, grid=sc.square)
        design.strand(0, 0).to(7)
        design.add_deletion(helix=0, offset=4)

        # expected values for verification
        expected_num_nucleotides = 6
        expected_strand_length = 6

        dat, top = design.to_oxdna_format()
        dat = dat.strip().split('\n')
        top = top.strip().split('\n')

        # check length of output files are as expected (matches # of nucleotides plus header size)
        self.assertEqual(expected_num_nucleotides + 3, len(dat))
        self.assertEqual(expected_num_nucleotides + 1, len(top))

        # find relevant values for nucleotides
        cm_poss = []  # center of mass position
        nbrs_3p = []
        nbrs_5p = []

        for line in dat[3:]:
            data = line.strip().split()
            # make sure there are 15 values per line (3 values per vector * 5 vectors per line)
            # order of vectors: center of mass position, backbone base, normal, velocity, angular velocity
            self.assertEqual(15, len(data))

            cm_poss.append(tuple([float(x) for x in data[0:3]]))
            bb_vec = tuple([float(x) for x in data[3:6]])  # backbone base vector
            nm_vec = tuple([float(x) for x in data[6:9]])  # normal vector

            # make sure normal vectors and backbone vectors are unit length
            sqr_bb_vec = sum([x ** 2 for x in bb_vec])
            sqr_nm_vec = sum([x ** 2 for x in nm_vec])
            self.assertAlmostEqual(1.0, sqr_bb_vec)
            self.assertAlmostEqual(1.0, sqr_nm_vec)

            for value in data[9:]:  # values for velocity and angular velocity vectors are 0
                self.assertAlmostEqual(0, float(value))

        strand1_idxs = []
        for nuc_idx, line in enumerate(top[1:]):
            data = line.strip().split()
            # make sure there are 4 values per line: strand, base, 3' neighbor, 5' neighbor
            self.assertEqual(4, len(data))

            # make sure there's only 1 strand
            strand_num = int(data[0])
            self.assertEqual(1, strand_num)
            # make sure base is valid
            base = data[1]
            self.assertIn(base, ['A', 'C', 'G', 'T'])

            nbrs_3p.append(int(data[2]))
            nbrs_5p.append(int(data[3]))

            # append start of strand (no 5' neighbor) to list of indexes for strand
            neighbor_5 = int(data[3])
            if neighbor_5 == -1:
                strand1_start = nuc_idx
                strand1_idxs.append(strand1_start)

        # reconstruct strand using indices from oxDNA files
        next_idx = nbrs_3p[strand1_start]
        while next_idx >= 0:
            strand1_idxs.append(next_idx)
            next_idx = nbrs_3p[strand1_idxs[-1]]

        # assert that strand is correct length
        self.assertEqual(expected_strand_length, len(strand1_idxs))

        for i in range(expected_strand_length - 1):
            strand1_nuc_idx1 = strand1_idxs[i]
            strand1_nuc_idx2 = strand1_idxs[i + 1]

            # find the center of mass for adjacent nucleotides
            s1_cmp1 = cm_poss[strand1_nuc_idx1]
            s1_cmp2 = cm_poss[strand1_nuc_idx2]

            # calculate and verify squared distance between adjacent nucleotides in a domain
            diff1 = tuple([s1_cmp1[j] - s1_cmp2[j] for j in range(3)])
            sqr_dist1 = sum([x ** 2 for x in diff1])

            self.assertAlmostEqual(self.EXPECTED_ADJ_NUC_CM_DIST2, sqr_dist1)

    def test_insertion_design(self) -> None:
        """
        0      7
            ^ insertion of length 1
        [------>
        """
        helix = [sc.Helix(max_offset=10)]
        design = sc.Design(helices=helix, grid=sc.square)
        design.strand(0, 0).to(7)
        design.add_insertion(helix=0, offset=4, length=1)

        # expected values for verification
        expected_num_nucleotides = 8
        expected_strand_length = 8

        dat, top = design.to_oxdna_format()
        dat = dat.strip().split('\n')
        top = top.strip().split('\n')

        # check length of output files are as expected (matches # of nucleotides plus header size)
        self.assertEqual(expected_num_nucleotides + 3, len(dat))
        self.assertEqual(expected_num_nucleotides + 1, len(top))

        # find relevant values for nucleotides
        cm_poss = []  # center of mass position
        nbrs_3p = []
        nbrs_5p = []

        for line in dat[3:]:
            data = line.strip().split()
            # make sure there are 15 values per line (3 values per vector * 5 vectors per line)
            # order of vectors: center of mass position, backbone base, normal, velocity, angular velocity
            self.assertEqual(15, len(data))

            cm_poss.append(tuple([float(x) for x in data[0:3]]))
            bb_vec = tuple([float(x) for x in data[3:6]])  # backbone base vector
            nm_vec = tuple([float(x) for x in data[6:9]])  # normal vector

            # make sure normal vectors and backbone vectors are unit length
            sqr_bb_vec = sum([x ** 2 for x in bb_vec])
            sqr_nm_vec = sum([x ** 2 for x in nm_vec])
            self.assertAlmostEqual(1.0, sqr_bb_vec)
            self.assertAlmostEqual(1.0, sqr_nm_vec)

            for value in data[9:]:  # values for velocity and angular velocity vectors are 0
                self.assertAlmostEqual(0, float(value))

        strand1_idxs = []
        for nuc_idx, line in enumerate(top[1:]):
            data = line.strip().split()
            # make sure there are 4 values per line: strand, base, 3' neighbor, 5' neighbor
            self.assertEqual(4, len(data))

            # make sure there's only 1 strand
            strand_num = int(data[0])
            self.assertEqual(1, strand_num)
            # make sure base is valid
            base = data[1]
            self.assertIn(base, ['A', 'C', 'G', 'T'])

            nbrs_3p.append(int(data[2]))
            nbrs_5p.append(int(data[3]))

            # append start of strand (no 5' neighbor) to list of indexes for strand
            neighbor_5 = int(data[3])
            if neighbor_5 == -1:
                strand1_start = nuc_idx
                strand1_idxs.append(strand1_start)

        # reconstruct strand using indices from oxDNA files
        next_idx = nbrs_3p[strand1_start]
        while next_idx >= 0:
            strand1_idxs.append(next_idx)
            next_idx = nbrs_3p[strand1_idxs[-1]]

        # assert that strand is correct length
        self.assertEqual(expected_strand_length, len(strand1_idxs))

        for i in range(expected_strand_length - 1):
            strand1_nuc_idx1 = strand1_idxs[i]
            strand1_nuc_idx2 = strand1_idxs[i + 1]

            # find the center of mass for adjacent nucleotides
            s1_cmp1 = cm_poss[strand1_nuc_idx1]
            s1_cmp2 = cm_poss[strand1_nuc_idx2]

            # calculate and verify squared distance between adjacent nucleotides in a domain
            diff1 = tuple([s1_cmp1[j] - s1_cmp2[j] for j in range(3)])
            sqr_dist1 = sum([x ** 2 for x in diff1])

            self.assertAlmostEqual(self.EXPECTED_ADJ_NUC_CM_DIST2, sqr_dist1)

    def test_loopout_design(self) -> None:
        """ 2 strands, one with a loopout
            0      7
                ^ loopout at 4 of length = 4 bases
            [------>
            <------]
        """
        helix = [sc.Helix(max_offset=14)]
        design = sc.Design(helices=helix, grid=sc.square)
        design.strand(0, 0).to(4).loopout(0, 4).to(7)
        design.strand(0, 7).to(0)

        # expected values for verification
        expected_num_nucleotides = 7 * 2 + 4
        expected_strand_1_length = 7 + 4    # strand 1 has loopout of 4
        expected_strand_2_length = 7

        dat, top = design.to_oxdna_format()
        dat = dat.strip().split('\n')
        top = top.strip().split('\n')

        # check length of output files are as expected (matches # of nucleotides plus header size)
        self.assertEqual(expected_num_nucleotides + 3, len(dat))
        self.assertEqual(expected_num_nucleotides + 1, len(top))

        # find relevant values for nucleotides
        cm_poss = []    # center of mass position
        nbrs_3p = []
        nbrs_5p = []

        for line in dat[3:]:
            data = line.strip().split()
            # make sure there are 15 values per line (3 values per vector * 5 vectors per line)
            # order of vectors: center of mass position, backbone base, normal, velocity, angular velocity
            self.assertEqual(15, len(data))

            cm_poss.append(tuple([float(x) for x in data[0:3]]))
            bb_vec = tuple([float(x) for x in data[3:6]])    # backbone base vector
            nm_vec = tuple([float(x) for x in data[6:9]])    # normal vector

            # make sure normal vectors and backbone vectors are unit length
            sqr_bb_vec = sum([x**2 for x in bb_vec])
            sqr_nm_vec = sum([x**2 for x in nm_vec])
            self.assertAlmostEqual(1.0, sqr_bb_vec)
            self.assertAlmostEqual(1.0, sqr_nm_vec)

            for value in data[9:]:    # values for velocity and angular velocity vectors are 0
                self.assertAlmostEqual(0, float(value))

        strand1_idxs = []
        strand2_idxs = []
        for nuc_idx, line in enumerate(top[1:]):
            data = line.strip().split()
            # make sure there are 4 values per line: strand, base, 3' neighbor, 5' neighbor
            self.assertEqual(4, len(data))

            # make sure there are only 2 strands
            strand_num = int(data[0])
            self.assertIn(strand_num, [1, 2])
            # make sure base is valid
            base = data[1]
            self.assertIn(base, ['A', 'C', 'G', 'T'])

            nbrs_3p.append(int(data[2]))
            nbrs_5p.append(int(data[3]))

            # append start of strand (no 5' neighbor) to list of indexes for strand
            neighbor_5 = int(data[3])
            if neighbor_5 == -1:
                if strand_num == 1:
                    strand1_start = nuc_idx
                    strand1_idxs.append(strand1_start)
                else:
                    strand2_start = nuc_idx
                    strand2_idxs.append(strand2_start)

        # reconstruct strands using indices from oxDNA files
        next_idx = nbrs_3p[strand1_start]
        while next_idx >= 0:
            strand1_idxs.append(next_idx)
            next_idx = nbrs_3p[strand1_idxs[-1]]

        next_idx = nbrs_3p[strand2_start]
        while next_idx >= 0:
            strand2_idxs.append(next_idx)
            next_idx = nbrs_3p[strand2_idxs[-1]]

        # assert that strands are the correct length
        self.assertEqual(expected_strand_1_length, len(strand1_idxs))
        self.assertEqual(expected_strand_2_length, len(strand2_idxs))

        # calculate distance between nucleotides preceding and following loopout and confirm that it matches expected distance between nucleotides.
        # loopout here is nucleotides 4 to 7, so check distance between nucleotides 3 to 8
        cm_poss_pre_loopout = cm_poss[strand1_idxs[3]]
        cm_poss_post_loopout = cm_poss[strand1_idxs[8]]
        diff = tuple([cm_poss_pre_loopout[j] - cm_poss_post_loopout[j] for j in range(3)])
        sqr_dist = sum([x ** 2 for x in diff])
        self.assertAlmostEqual(self.EXPECTED_ADJ_NUC_CM_DIST2, sqr_dist)

        for i in range(expected_strand_1_length - 1):

            if i in [3, 4, 5, 6, 7]:    #skip nucleotide distances having to do with loopout, as these won't have regular distance between nucleotides (i = 3 denotes distance from 3 to 4, which includes loopout)
                continue

            strand1_nuc_idx1 = strand1_idxs[i]
            strand1_nuc_idx2 = strand1_idxs[i + 1]

            # find the center of mass for adjacent nucleotides
            s1_cmp1 = cm_poss[strand1_nuc_idx1]
            s1_cmp2 = cm_poss[strand1_nuc_idx2]

            # calculate and verify squared distance between adjacent nucleotides in a domain
            diff1 = tuple([s1_cmp1[j] - s1_cmp2[j] for j in range(3)])
            sqr_dist1 = sum([x ** 2 for x in diff1])

            self.assertAlmostEqual(self.EXPECTED_ADJ_NUC_CM_DIST2, sqr_dist1)

        for i in range(expected_strand_2_length - 1):     # check adjacent nucleotide distances for second strand
            strand2_nuc_idx1 = strand2_idxs[i]
            strand2_nuc_idx2 = strand2_idxs[i+1]

            # find the center of mass for adjacent nucleotides
            s2_cmp1 = cm_poss[strand2_nuc_idx1]
            s2_cmp2 = cm_poss[strand2_nuc_idx2]

            # calculate and verify squared distance between adjacent nucleotides in a domain
            diff2 = tuple([s2_cmp1[j]-s2_cmp2[j] for j in range(3)])
            sqr_dist2 = sum([x**2 for x in diff2])

            self.assertAlmostEqual(self.EXPECTED_ADJ_NUC_CM_DIST2, sqr_dist2)

*/
