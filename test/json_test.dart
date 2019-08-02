@TestOn("browser")

import 'dart:math';
import 'dart:convert';

import 'package:color/color.dart';
import 'package:test/test.dart';
import 'package:tuple/tuple.dart';

import 'package:scadnano/src/model.dart';

main() {
  test("serialize then deserialize", () {
    DNADesign design = DNADesign.internal();

    design.grid = Grid.hex;
    int max_bases = 60;
    design.major_tick_distance = 7;

    var hp00 = Point<int>(0, 0);
    var hp01 = Point<int>(0, 1);
    var h00 = Helix(idx: 0, grid_position: hp00, max_bases: max_bases);
    var h01 = Helix(idx: 1, grid_position: hp01, max_bases: max_bases);
    var hp10 = Point<int>(1, 0);
    var hp11 = Point<int>(1, 1);
    var h10 = Helix(idx: -1, grid_position: hp10, max_bases: max_bases);
    var h11 = Helix(idx: -1, grid_position: hp11, max_bases: max_bases);
    var hp20 = Point<int>(2, 0);
    var hp21 = Point<int>(2, 1);
    var h20 = Helix(idx: -1, grid_position: hp20, max_bases: max_bases);
    var h21 = Helix(idx: -1, grid_position: hp21, max_bases: max_bases);
    design.helices = [h00, h01, h10, h11, h20, h21,];
    design.used_helices = [h00, h01];

    Substrand ss00 = Substrand()
      ..helix_idx = 0
      ..direction = Direction.left
      ..start = 2
      ..end = 5
      ..deletions = [3]
      ..insertions = [Tuple2<int, int>(4, 1), Tuple2<int, int>(5, 2)];
//      ..dna_sequence = 'GGGGGG';

    Substrand ss01 = Substrand()
      ..helix_idx = 1
      ..direction = Direction.right
      ..start = 1
      ..end = 6
      ..deletions = []
      ..insertions = [];
//      ..dna_sequence = 'AAAAAA';

    Strand s0 = Strand()
      ..substrands = [ss00, ss01]
      ..color = RgbColor.name('red')
      ..dna_sequence = 'GGGGGGAAAAAA';

    Substrand ss10 = Substrand()
      ..helix_idx = 1
      ..direction = Direction.right
      ..start = 11
      ..end = 15
      ..deletions = []
      ..insertions = [];
//      ..dna_sequence = 'TTTTT';

    Substrand ss11 = Substrand()
      ..helix_idx = 0
      ..direction = Direction.left
      ..start = 13
      ..end = 16
      ..deletions = []
      ..insertions = [];
//      ..dna_sequence = 'CCCC';

    Strand s1 = Strand()
      ..substrands = [ss10, ss11]
      ..color = RgbColor.name('green')
      ..dna_sequence = 'TTTTTCCCC';

    design.strands = [s0, s1];

//    print("model = ${model}");
    var encoder = JsonEncoder.withIndent('  ');
    String serialized_model = encoder.convert(design);
//    print("serializedModel = $serializedModel");

    Map<String, dynamic> deserialized_map = jsonDecode(serialized_model);
    DNADesign decoded_model = DNADesign.from_json(deserialized_map);
//    print("decoded model.helicesMap = ${model2.helicesMap}");

    expect(decoded_model.grid, equals(Grid.hex));
//    expect(decodedModel.basesPerHelix, equals(60));
    expect(decoded_model.major_tick_distance, equals(7));

    expect(decoded_model.helices.length, equals(6));
    expect(decoded_model.helices, equals(h00));
    expect(decoded_model.helices, equals(h01));
    expect(decoded_model.helices, equals(h10));
    expect(decoded_model.helices, equals(h11));
    expect(decoded_model.helices, equals(h20));
    expect(decoded_model.helices, equals(h21));

    expect(decoded_model.used_helices.length, equals(2));
    expect(decoded_model.used_helices[0], equals(h00));
    expect(decoded_model.used_helices[1], equals(h01));

    expect(decoded_model.strands.length, equals(2));

    Strand parsed_strand0 = decoded_model.strands[0];
    expect(parsed_strand0.color, equals(RgbColor.name('red')));
    expect(parsed_strand0.substrands.length, equals(2));
    expect(parsed_strand0.length, equals(12));
    expect(parsed_strand0.dna_sequence, equals('GGGGGGAAAAAA'));

    Substrand parsed_substrand00 = parsed_strand0.substrands[0];
    expect(parsed_substrand00.helix_idx, equals(0));
    expect(parsed_substrand00.direction, equals(Direction.left));
    expect(parsed_substrand00.start, equals(2));
    expect(parsed_substrand00.end, equals(5));
    expect(parsed_substrand00.deletions.length, equals(1));
    expect(parsed_substrand00.deletions[0], equals(3));
    expect(parsed_substrand00.insertions.length, equals(2));
    expect(parsed_substrand00.insertions[0], equals(Tuple2<int, int>(4, 1)));
    expect(parsed_substrand00.insertions[1], equals(Tuple2<int, int>(5, 2)));
    expect(parsed_substrand00.dna_sequence, equals('GGGGGG'));
    expect(parsed_substrand00.length, equals(6));

    Substrand parsed_substrand01 = parsed_strand0.substrands[1];
    expect(parsed_substrand01.helix_idx, equals(1));
    expect(parsed_substrand01.direction, equals(Direction.right));
    expect(parsed_substrand01.start, equals(1));
    expect(parsed_substrand01.end, equals(6));
    expect(parsed_substrand01.deletions.length, equals(0));
    expect(parsed_substrand01.insertions.length, equals(0));
    expect(parsed_substrand01.dna_sequence, equals('AAAAAA'));
    expect(parsed_substrand01.length, equals(6));

    Strand parsed_strand1 = decoded_model.strands[1];
    expect(parsed_strand1.color, equals(RgbColor.name('green')));
    expect(parsed_strand1.substrands.length, equals(2));
    expect(parsed_strand1.length, equals(9));
    expect(parsed_strand1.dna_sequence, equals('TTTTTCCCC'));

    Substrand parsed_substrand10 = parsed_strand1.substrands[0];
    expect(parsed_substrand10.helix_idx, equals(1));
    expect(parsed_substrand10.direction, equals(Direction.right));
    expect(parsed_substrand10.start, equals(11));
    expect(parsed_substrand10.end, equals(15));
    expect(parsed_substrand10.deletions.length, equals(0));
    expect(parsed_substrand10.insertions.length, equals(0));
    expect(parsed_substrand10.dna_sequence, equals('TTTTT'));
    expect(parsed_substrand10.length, equals(5));

    Substrand parsed_substrand11 = parsed_strand1.substrands[1];
    expect(parsed_substrand11.helix_idx, equals(0));
    expect(parsed_substrand11.direction, equals(Direction.left));
    expect(parsed_substrand11.start, equals(13));
    expect(parsed_substrand11.end, equals(16));
    expect(parsed_substrand11.deletions.length, equals(0));
    expect(parsed_substrand11.insertions.length, equals(0));
    expect(parsed_substrand11.dna_sequence, equals('CCCC'));
    expect(parsed_substrand11.length, equals(4));
  });
}

//TODO: add test based on file 16_helix_rectangle_no_twist_causes_crash.dna in Python repo