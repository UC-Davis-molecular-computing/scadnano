import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import '../serializers.dart';

part 'example_dna_designs.g.dart';

final DEFAULT_example_dna_designs_builder = ExampleDNADesignsBuilder();
final DEFAULT_example_dna_designs = DEFAULT_example_dna_designs_builder.build();

abstract class ExampleDNADesigns
    with BuiltJsonSerializable
    implements Built<ExampleDNADesigns, ExampleDNADesignsBuilder> {
  String get directory;

  BuiltList<String> get filenames;

  int get selected_idx;

  static void _initializeBuilder(ExampleDNADesignsBuilder b) {
    b.directory = 'examples/output_designs';
    b.filenames = ListBuilder<String>([
      'empty',
      '2_staple_2_helix_origami_deletions_insertions_mods',
      '6_helix_origami_rectangle',
      '6_helix_bundle_honeycomb',
      '16_helix_origami_rectangle_no_twist',
      '16_helix_origami_rectangle',
      '16_helix_origami_rectangle_idt',
      'very_large_origami',
    ]);
    b.selected_idx = -1;
  }

  bool get example_is_selected => selected_idx >= 0;

  String get selected_filename => example_is_selected ? '${selected_filename_no_ext}.dna' : null;

  String get selected_filename_no_ext => example_is_selected ? filenames[selected_idx] : null;

  String get selected_full_filename => example_is_selected ? '${directory}/${selected_filename}' : null;

  String get selected_full_filename_no_ext =>
      example_is_selected ? '${directory}/${selected_filename_no_ext}' : null;

  /// url of currently selected file
  String get url => selected_full_filename;

  /************************ begin BuiltValue boilerplate ************************/
  factory ExampleDNADesigns.from([void Function(ExampleDNADesignsBuilder) updates]) = _$ExampleDNADesigns;

  ExampleDNADesigns._();

  static Serializer<ExampleDNADesigns> get serializer => _$exampleDNADesignsSerializer;

  factory ExampleDNADesigns({BuiltList<String> filenames, String directory, int selected_idx}) =
      _$ExampleDNADesigns._;

  @memoized
  int get hashCode;
}
