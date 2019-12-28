import 'package:collection/collection.dart';

import 'package:react/react.dart';

/// Top-level ReactJS [PureComponent class](https://reactjs.org/docs/react-api.html#reactpurecomponent)
mixin PureComponent implements Component2 {
  @override
  bool shouldComponentUpdate(Map nextProps, Map nextState) {
    return !PureComponent._shallowPropsEqual(props, nextProps) ||
        !PureComponent._shallowStateEqual(state, nextState);
  }

  static bool _shallowPropsEqual(Map map1, Map map2) {
    // Does this work, or does props.children always make this return false?
    return MapEquality().equals(
          Map.of(map1)..remove('key')..remove('ref')..remove('children'),
          Map.of(map2)..remove('key')..remove('ref')..remove('children'),
        ) &&
        ListEquality().equals(map1['children'], map2['children']);
  }

  static bool _shallowStateEqual(Map map1, Map map2) {
    return MapEquality().equals(map1, map2);
  }
}
