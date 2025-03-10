import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import '../serializers.dart';

part 'context_menu.g.dart';

typedef Callback = void Function();

abstract class ContextMenu with BuiltJsonSerializable implements Built<ContextMenu, ContextMenuBuilder> {
  factory ContextMenu.from([void Function(ContextMenuBuilder) updates]) = _$ContextMenu;

  ContextMenu._();

  static Serializer<ContextMenu> get serializer => _$contextMenuSerializer;

  factory ContextMenu({required BuiltList<ContextMenuItem> items, required Point<double> position}) =
      _$ContextMenu._;

  @memoized
  int get hashCode;

  /************************ end BuiltValue boilerplate ************************/

  BuiltList<ContextMenuItem> get items;

  Point<double> get position;
}

abstract class ContextMenuItem
    with BuiltJsonSerializable
    implements Built<ContextMenuItem, ContextMenuItemBuilder> {
  factory ContextMenuItem.from([void Function(ContextMenuItemBuilder) updates]) = _$ContextMenuItem;

  ContextMenuItem._();

  static Serializer<ContextMenuItem> get serializer => _$contextMenuItemSerializer;

  factory ContextMenuItem({
    required String title,
    Callback? on_click = null,
    String tooltip = '',
    BuiltList<ContextMenuItem>? nested = null,
    bool disabled = false,
  }) {
    return ContextMenuItem.from(
      (b) =>
          b
            ..title = title
            ..on_click = on_click
            ..tooltip = tooltip
            ..nested = nested?.toBuilder()
            ..disabled = disabled,
    );
  }

  @memoized
  int get hashCode;

  /************************ end BuiltValue boilerplate ************************/

  String get title;

  @BuiltValueField(serialize: false, compare: false)
  Callback? get on_click;

  String get tooltip;

  BuiltList<ContextMenuItem>? get nested;

  bool get disabled;
}
