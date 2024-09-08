import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:built_collection/built_collection.dart';

import '../serializers.dart';

part 'local_storage_design_choice.g.dart';

// This is an enum that's the main component of LocalStorageDesignChoice
class LocalStorageDesignOption extends EnumClass {
  const LocalStorageDesignOption._(String name) : super(name);

  static Serializer<LocalStorageDesignOption> get serializer => _$localStorageDesignOptionSerializer;

  static const LocalStorageDesignOption on_edit = _$on_edit; // on every edit to the design
  static const LocalStorageDesignOption on_exit = _$on_exit; // on event beforeWindowUnload
  static const LocalStorageDesignOption never = _$never; // never save to localStorage
  static const LocalStorageDesignOption periodic = _$periodic; // every period_seconds seconds

  static BuiltSet<LocalStorageDesignOption> get values => _$values;

  static LocalStorageDesignOption valueOf(String name) => _$valueOf(name);
}

const int _default_period = 30;

/// Mostly this carries a single [LocalStorageDesignOption],
/// but if it is [LocalStorageDesignOption.periodic], then we also need [period_seconds].
abstract class LocalStorageDesignChoice
    with BuiltJsonSerializable
    implements Built<LocalStorageDesignChoice, LocalStorageDesignChoiceBuilder> {
  factory LocalStorageDesignChoice(
          [LocalStorageDesignOption option = LocalStorageDesignOption.on_edit,
          int period_seconds = _default_period]) =>
      LocalStorageDesignChoice.from((b) => b
        ..option = option
        ..period_seconds = period_seconds);

  factory LocalStorageDesignChoice.from([void Function(LocalStorageDesignChoiceBuilder) updates]) =
      _$LocalStorageDesignChoice;

  LocalStorageDesignChoice._();

  static Serializer<LocalStorageDesignChoice> get serializer => _$localStorageDesignChoiceSerializer;

  /************************ end BuiltValue boilerplate ************************/

  LocalStorageDesignOption get option;

  int get period_seconds;

  static void initializeBuilder(LocalStorageDesignChoiceBuilder b) {
    b.period_seconds = _default_period;
  }

  LocalStorageDesignChoice to_on_edit() => rebuild((b) => b..option = LocalStorageDesignOption.on_edit);

  LocalStorageDesignChoice to_on_exit() => rebuild((b) => b..option = LocalStorageDesignOption.on_exit);

  LocalStorageDesignChoice to_never() => rebuild((b) => b..option = LocalStorageDesignOption.never);

  LocalStorageDesignChoice to_periodic() => rebuild((b) => b..option = LocalStorageDesignOption.periodic);

  LocalStorageDesignChoice change_period(int new_period) => rebuild((b) => b..period_seconds = new_period);
}
