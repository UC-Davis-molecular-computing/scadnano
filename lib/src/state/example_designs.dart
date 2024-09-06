// @dart=2.9
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import '../serializers.dart';
import '../constants.dart' as constants;

part 'example_designs.g.dart';

final DEFAULT_example_designs_builder = ExampleDesignsBuilder();
final DEFAULT_example_designs = DEFAULT_example_designs_builder.build();

abstract class ExampleDesigns
    with BuiltJsonSerializable
    implements Built<ExampleDesigns, ExampleDesignsBuilder> {
  String get directory;

  BuiltList<String> get filenames;

  int get selected_idx;

  static void _initializeBuilder(ExampleDesignsBuilder b) {
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

  String get selected_filename =>
      example_is_selected ? '${selected_filename_no_ext}.${constants.default_scadnano_file_extension}' : null;

  String get selected_filename_no_ext => example_is_selected ? filenames[selected_idx] : null;

  String get selected_full_filename => example_is_selected ? '${directory}/${selected_filename}' : null;

  String get selected_full_filename_no_ext =>
      example_is_selected ? '${directory}/${selected_filename_no_ext}' : null;

  /// url of currently selected file
  String get url => selected_full_filename;

  /************************ begin BuiltValue boilerplate ************************/
  factory ExampleDesigns.from([void Function(ExampleDesignsBuilder) updates]) = _$ExampleDesigns;

  ExampleDesigns._();

  static Serializer<ExampleDesigns> get serializer => _$exampleDesignsSerializer;

  factory ExampleDesigns({BuiltList<String> filenames, String directory, int selected_idx}) =
      _$ExampleDesigns._;

  @memoized
  int get hashCode;
}
