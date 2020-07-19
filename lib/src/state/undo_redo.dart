import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import '../serializers.dart';
import 'design.dart';

part 'undo_redo.g.dart';

final DEFAULT_UndoRedoBuilder = UndoRedoBuilder();
final DEFAULT_UndoRedo = DEFAULT_UndoRedoBuilder.build();

abstract class UndoRedo with BuiltJsonSerializable implements Built<UndoRedo, UndoRedoBuilder> {
  BuiltList<Design> get undo_stack;

  BuiltList<Design> get redo_stack;

  static void _initializeBuilder(UndoRedoBuilder b) {
    b.undo_stack = ListBuilder<Design>();
    b.redo_stack = ListBuilder<Design>();
  }

  /************************ begin BuiltValue boilerplate ************************/

  factory UndoRedo([void Function(UndoRedoBuilder) updates]) =>
      _$UndoRedo((u) => u..replace(DEFAULT_UndoRedo));

  UndoRedo._();

  static Serializer<UndoRedo> get serializer => _$undoRedoSerializer;

  @memoized
  int get hashCode;
}
