import 'package:built_value/serializer.dart';
import 'package:built_value/built_value.dart';
import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/model/mouseover_data.dart';

import '../model/select_mode.dart';
import 'actions.dart';

part 'serializers.g.dart';

@SerializersFor([
  ToggleSelectMode,
  SetSelectModes,
  SetShowDNA,
  SetShowMismatches,
  SetShowEditor,
  SaveDNAFile,
  LoadDNAFile,
  MouseoverDataClear,
  MouseoverDataUpdate,
  SideViewSelectionBoxCreateToggling,
  SideViewSelectionBoxCreateSelecting,
  SideViewSelectionBoxSizeChanged,
  SideViewSelectionBoxRemove,
  MainViewSelectionBoxCreateToggling,
  MainViewSelectionBoxCreateSelecting,
  MainViewSelectionBoxSizeChanged,
  MainViewSelectionBoxRemove,
  SideViewMousePositionUpdate,
  SideViewMousePositionRemove,
])
Serializers serializers = _$serializers;
