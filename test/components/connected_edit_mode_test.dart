@TestOn('browser')
import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:over_react_test/jacket.dart';
import 'package:over_react_test/over_react_test.dart';
import 'package:react/react_client.dart';
import 'package:react/react_client/react_interop.dart';
import 'package:redux/redux.dart';
import 'package:scadnano/src/reducers/app_state_reducer.dart';
import 'package:scadnano/src/state/app_state.dart';
import 'package:scadnano/src/state/edit_mode.dart';
import 'package:scadnano/src/view/edit_mode.dart';
import 'package:test/test.dart';

import 'package:scadnano/src/util.dart' as util;

// const app_id = 'scadnano.ReduxBoundary';

void initializeComponentTests() {
  setClientConfiguration();
  enableTestMode();
}

Store<AppState> testStore;
Store<AppState> initializeTestStore() {
  addTearDown(() {
    testStore = null;
  });

  return testStore = Store<AppState>(
    app_state_reducer,
    initialState: util.default_state(),
  );
}

void main() {
  initializeComponentTests();

  group('ConnectedEditModes', () {
    // Ref<EditModeComponent> componentRef;
    ReactComponent component;

    setUp(() {
      initializeTestStore();
      // component = ConnectedEditMode()();
      // component = ((ReduxProvider()..store = testStore)(
      //   (ConnectedEditMode())(),
      // ));
      // component = (ReduxProvider()..store = testStore)(
      //   ConnectedEditMode()(),
      // );
      // mount(component);
      // componentRef = createRef();
      var testJacket = mount((ReduxProvider()..store = testStore
          // ..addTestId(app_id)
          )(
        // (ConnectedEditMode()..ref = componentRef)(),
        (ConnectedEditMode())(),
        // component,
      ));

      component = testJacket.getInstance();

      // component = componentRef.current;
      // expect(component, isNotNull, reason: 'ConnectedEditMode should forward refs to the child EditMode');
      expect(component, isNotNull, reason: 'ConnectedEditMode should be mounted');
    });

    tearDown(() {
      // componentRef = null;
      component = null;
    });

    group('renders a EditMode', () {
      test('that renders the select button', () {
        final select_button =
            getByTestId(component, 'scadnano.EditModeComponent.button.${EditModeChoice.select.name}');
        expect(select_button, isNotNull);
      });
      // group('with prop callbacks mapped to the expected Redux action:', () {
      //   test('props.onClick => EditModeToggle', () {
      //     final editModeToggleCompleter = Completer<BuiltSet<EditModeChoice>>();
      //     testStore.onChange.listen((newState) {
      //       editModeToggleCompleter.complete(newState.ui_state.edit_modes);
      //     });
      //     component.props.
      //   });
      // });
    });
  });
}
