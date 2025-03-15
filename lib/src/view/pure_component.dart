import 'package:collection/collection.dart';

import 'package:react/react.dart';

/// Top-level ReactJS [PureComponent class](https://reactjs.org/docs/react-api.html#reactpurecomponent)
mixin PureComponent implements Component2 {
  @override
  bool shouldComponentUpdate(Map nextProps, Map nextState) {
    return !shallow_props_equal(props, nextProps) || !shallow_state_equal(state, nextState);
    //    return !PureComponent._deepPropsEqual(props, nextProps) ||
    //        !PureComponent._deepStateEqual(state, nextState);
  }
}

bool shallow_props_equal(Map map1, Map map2) {
  // Does this work, or does props.children always make this return false?
  bool should_update =
      MapEquality().equals(
        Map.of(map1)
          ..remove('key')
          ..remove('ref')
          ..remove('children'),
        Map.of(map2)
          ..remove('key')
          ..remove('ref')
          ..remove('children'),
      ) &&
      ListEquality().equals(map1['children'], map2['children']);
  return should_update;
}

bool shallow_state_equal(Map map1, Map map2) {
  return MapEquality().equals(map1, map2);
}

bool deep_props_equal(Map map1, Map map2) {
  var map1_modified =
      Map.of(map1)
        ..remove('key')
        ..remove('ref')
        ..remove('children');
  var map2_modified =
      Map.of(map2)
        ..remove('key')
        ..remove('ref')
        ..remove('children');
  for (var key in map1_modified.keys) {
    var val1 = map1_modified[key];
    var val2 = map2_modified[key];
    if (val1 != val2) {
      return false;
    }
  }
  return ListEquality().equals(map1['children'], map2['children']);
}

bool deep_state_equal(Map map1, Map map2) {
  return MapEquality().equals(map1, map2);
}
