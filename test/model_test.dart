//@TestOn("browser")  // uncomment this to test stuff in files that require importing 'dart:html'

import 'dart:convert';

import 'package:color/color.dart';
import 'package:test/test.dart';
import 'package:tuple/tuple.dart';

import 'package:scadnano/src/model/model.dart';
import 'package:scadnano/src/model/strand.dart';

main() {
  /*
  test("serialize then deserialize", () {
    DNADesign design = DNADesign.internal();

    design.grid = Grid.hex;
    int max_bases = 60;
    design.major_tick_distance = 7;

    var hp00 = GridPosition(0, 0);
    var hp01 = GridPosition(0, 1);
    var h00 = Helix(grid_position: hp00, max_bases: max_bases);
    var h01 = Helix(grid_position: hp01, max_bases: max_bases);
    var hp10 = GridPosition(1, 0);
    var hp11 = GridPosition(1, 1);
    var h10 = PotentialHelix(hp10);
    var h11 = PotentialHelix(hp11);
    var hp20 = GridPosition(2, 0);
    var hp21 = GridPosition(2, 1);
    var h20 = PotentialHelix(hp20);
    var h21 = PotentialHelix(hp21);

    design.helices = [h00, h01];
    design.potential_helices = [h10, h11, h20, h21];

    BoundSubstrand ss00 = BoundSubstrand()
      ..helix = 0
      ..forward = false
      ..start = 2
      ..end = 8
      ..deletions = [3]
      ..insertions = [Tuple2<int, int>(4, 1), Tuple2<int, int>(6, 2)];
//      ..dna_sequence = 'GGGGGGCT';

    BoundSubstrand ss01 = BoundSubstrand()
      ..helix = 1
      ..forward = true
      ..start = 1
      ..end = 6
      ..deletions = []
      ..insertions = [];
//      ..dna_sequence = 'TAAAC';

    Strand s0 = Strand()
      ..substrands = [ss00, ss01]
      ..color = RgbColor.name('red')
      ..dna_sequence = 'GGGGGGCTTAAAC';

    BoundSubstrand ss10 = BoundSubstrand()
      ..helix = 1
      ..forward = true
      ..start = 11
      ..end = 15
      ..deletions = []
      ..insertions = [];
//      ..dna_sequence = 'TTTG';

    BoundSubstrand ss11 = BoundSubstrand()
      ..helix = 0
      ..forward = false
      ..start = 13
      ..end = 16
      ..deletions = []
      ..insertions = [];
//      ..dna_sequence = 'CCA';

    Strand s1 = Strand()
      ..substrands = [ss10, ss11]
      ..color = RgbColor.name('green')
      ..dna_sequence = 'TTTGCCA';

    design.strands = [s0, s1];

//    print("model = ${model}");
    var encoder = JsonEncoder.withIndent('  ');
    String serialized_model = encoder.convert(design);
//    print("serialized_model = $serialized_model");

    Map<String, dynamic> deserialized_map = jsonDecode(serialized_model);
    DNADesign decoded_model = DNADesign.from_json(deserialized_map);
//    print("decoded model.helicesMap = ${model2.helicesMap}");

    expect(decoded_model.grid, equals(Grid.hex));
//    expect(decodedModel.basesPerHelix, equals(60));
    expect(decoded_model.major_tick_distance, equals(7));

    expect(decoded_model.potential_helices.length, equals(4));
    expect(decoded_model.potential_helices[0], equals(h10));
    expect(decoded_model.potential_helices[1], equals(h11));
    expect(decoded_model.potential_helices[2], equals(h20));
    expect(decoded_model.potential_helices[3], equals(h21));

    expect(decoded_model.helices.length, equals(2));
    expect(decoded_model.helices[0], equals(h00));
    expect(decoded_model.helices[1], equals(h01));

    expect(decoded_model.strands.length, equals(2));

    Strand parsed_strand0 = decoded_model.strands[0];
    expect(parsed_strand0.color, equals(RgbColor.name('red')));
    expect(parsed_strand0.substrands.length, equals(2));
    expect(parsed_strand0.dna_length, equals(13));
    expect(parsed_strand0.dna_sequence, equals('GGGGGGCTTAAAC'));

    BoundSubstrand parsed_substrand00 = parsed_strand0.substrands[0];
    expect(parsed_substrand00.helix, equals(0));
    expect(parsed_substrand00.forward, equals(false));
    expect(parsed_substrand00.start, equals(2));
    expect(parsed_substrand00.end, equals(8));
    expect(parsed_substrand00.deletions.length, equals(1));
    expect(parsed_substrand00.deletions[0], equals(3));
    expect(parsed_substrand00.insertions.length, equals(2));
    expect(parsed_substrand00.insertions[0], equals(Tuple2<int, int>(4, 1)));
    expect(parsed_substrand00.insertions[1], equals(Tuple2<int, int>(6, 2)));
    expect(parsed_substrand00.dna_sequence(), equals('GGGGGGCT'));
    expect(parsed_substrand00.dna_length, equals(8));

    BoundSubstrand parsed_substrand01 = parsed_strand0.substrands[1];
    expect(parsed_substrand01.helix, equals(1));
    expect(parsed_substrand01.forward, equals(true));
    expect(parsed_substrand01.start, equals(1));
    expect(parsed_substrand01.end, equals(6));
    expect(parsed_substrand01.deletions.length, equals(0));
    expect(parsed_substrand01.insertions.length, equals(0));
    expect(parsed_substrand01.dna_sequence(), equals('TAAAC'));
    expect(parsed_substrand01.dna_length, equals(5));

    Strand parsed_strand1 = decoded_model.strands[1];
    expect(parsed_strand1.color, equals(RgbColor.name('green')));
    expect(parsed_strand1.substrands.length, equals(2));
    expect(parsed_strand1.dna_length, equals(7));
    expect(parsed_strand1.dna_sequence, equals('TTTGCCA'));

    BoundSubstrand parsed_substrand10 = parsed_strand1.substrands[0];
    expect(parsed_substrand10.helix, equals(1));
    expect(parsed_substrand10.forward, equals(true));
    expect(parsed_substrand10.start, equals(11));
    expect(parsed_substrand10.end, equals(15));
    expect(parsed_substrand10.deletions.length, equals(0));
    expect(parsed_substrand10.insertions.length, equals(0));
    expect(parsed_substrand10.dna_sequence(), equals('TTTG'));
    expect(parsed_substrand10.dna_length, equals(4));

    BoundSubstrand parsed_substrand11 = parsed_strand1.substrands[1];
    expect(parsed_substrand11.helix, equals(0));
    expect(parsed_substrand11.forward, equals(false));
    expect(parsed_substrand11.start, equals(13));
    expect(parsed_substrand11.end, equals(16));
    expect(parsed_substrand11.deletions.length, equals(0));
    expect(parsed_substrand11.insertions.length, equals(0));
    expect(parsed_substrand11.dna_sequence(), equals('CCA'));
    expect(parsed_substrand11.dna_length, equals(3));
  });
  */

  test("dna_sequence_deletions_insertions_to_spaces__no_deletions_no_insertions", () {
    var ss = BoundSubstrand()
      ..helix = 0
      ..forward = true
      ..start = 0
      ..end = 10;
    var strand = Strand()
      ..substrands = [ss]
      ..dna_sequence = "ACGTACGTAC";
    ss.strand = strand;
    expect(ss.dna_sequence_deletions_insertions_to_spaces(), "ACGTACGTAC");
  });

  test("dna_sequence_deletions_insertions_to_spaces__with_deletions_no_insertions", () {
    var ss = BoundSubstrand()
      ..helix = 0
      ..forward = true
      ..start = 0
      ..end = 10
      ..deletions = [2, 3, 7];
    var strand = Strand()
      ..substrands = [ss]
      ..dna_sequence = "ACGTACG";
    ss.strand = strand;
    expect(ss.dna_sequence_deletions_insertions_to_spaces(), "AC  GTA CG");
//                                                            0123456789
  });

  test("dna_sequence_deletions_insertions_to_spaces__no_deletions_with_insertions", () {
    var ss = BoundSubstrand()
      ..helix = 0
      ..forward = true
      ..start = 0
      ..end = 10
      ..insertions = [Tuple2<int, int>(2, 1), Tuple2<int, int>(5, 4), Tuple2<int, int>(7, 1)];
    var strand = Strand()
      ..substrands = [ss]
      ..dna_sequence = "ACGTACGTACAACCGG";
//                      012 345    67 89
    ss.strand = strand;
    expect(ss.dna_sequence_deletions_insertions_to_spaces(), "AC AC A GG");
//                                                            0123456789
  });

  test("dna_sequence_deletions_insertions_to_spaces__with_deletions_with_insertions", () {
    var ss = BoundSubstrand()
      ..helix = 0
      ..forward = true
      ..start = 0
      ..end = 10
      ..deletions=[4,8]
      ..insertions = [Tuple2<int, int>(2, 1), Tuple2<int, int>(5, 4), Tuple2<int, int>(7, 1)];
    var strand = Strand()
      ..substrands = [ss]
      ..dna_sequence = "ACGTAGTACAACCG";
//                      012 35    67 9
    ss.strand = strand;
    expect(ss.dna_sequence_deletions_insertions_to_spaces(), "AC A  A  G");
//                                                            0123456789
  });


  test("dna_sequence_deletions_insertions_to_spaces__going_left__with_deletions_with_insertions", () {
//    print("starting test");
    var ss = BoundSubstrand()
      ..helix = 0
      ..forward = false
      ..start = 0
      ..end = 10
      ..deletions=[4,8]
      ..insertions = [Tuple2<int, int>(2, 1), Tuple2<int, int>(5, 4), Tuple2<int, int>(7, 1)];
    var strand = Strand()
      ..substrands = [ss]
      ..dna_sequence = "ACGTAGTACAACCG";
//                      GCCAACATGATGCA
//                      012 35    67 9
    ss.strand = strand;
//    print("calling dna_sequence_deletions_insertions_to_spaces");
    expect(ss.dna_sequence_deletions_insertions_to_spaces(), "A  T  A CG");
//                                                            9876543210
//                    (as it appears with offsets in order)  "GC A  T  A"
  });
}

//TODO: add test based on file tests/design_causes_crash.dna in Python repo
// Probably need more error-checking in code that currently assumes .dna file was properly constructed.
