import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:scadnano/src/state/copy_info.dart';

import '../serializers.dart';
import 'design.dart';

part 'undo_redo.g.dart';

final DEFAULT_UndoRedoBuilder = UndoRedoBuilder();
final DEFAULT_UndoRedo = DEFAULT_UndoRedoBuilder.build();

abstract class UndoRedo with BuiltJsonSerializable implements Built<UndoRedo, UndoRedoBuilder> {
  BuiltList<UndoRedoItem> get undo_stack;

  BuiltList<UndoRedoItem> get redo_stack;

  static void _initializeBuilder(UndoRedoBuilder b) {
    b.undo_stack = ListBuilder<UndoRedoItem>();
    b.redo_stack = ListBuilder<UndoRedoItem>();
  }

  /************************ begin BuiltValue boilerplate ************************/

  factory UndoRedo([void Function(UndoRedoBuilder) updates]) =>
      _$UndoRedo((u) => u..replace(DEFAULT_UndoRedo));

  UndoRedo._();

  static Serializer<UndoRedo> get serializer => _$undoRedoSerializer;

  @memoized
  int get hashCode;
}

abstract class UndoRedoItem with BuiltJsonSerializable implements Built<UndoRedoItem, UndoRedoItemBuilder> {
  String get short_description;

  Design get design;

  CopyInfo get copy_info;

  /************************ begin BuiltValue boilerplate ************************/

  factory UndoRedoItem(String short_description, Design design, CopyInfo copy_info) => UndoRedoItem.from((b) => b
    ..short_description = short_description
    ..copy_info.update((c) {
        print('I am replaced***');
        if (copy_info != null) {
          c.replace(copy_info);
        }
      })    
    ..design.replace(design)
    );

  factory UndoRedoItem.from([void Function(UndoRedoItemBuilder) updates]) = _$UndoRedoItem;

  UndoRedoItem._();

  static Serializer<UndoRedoItem> get serializer => _$undoRedoItemSerializer;

  @memoized
  int get hashCode;
}
