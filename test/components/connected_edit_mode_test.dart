@TestOn('browser')
import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:over_react_test/jacket.dart';
import 'package:over_react_test/over_react_test.dart';
import 'package:react/react_client.dart';
import 'package:redux/redux.dart';
import 'package:scadnano/src/app.dart';
import 'package:scadnano/src/reducers/app_state_reducer.dart';
import 'package:scadnano/src/state/app_state.dart';
import 'package:scadnano/src/state/edit_mode.dart';
import 'package:scadnano/src/view/edit_mode.dart';
import 'package:test/test.dart';

import 'package:scadnano/src/util.dart' as util;

void initializeComponentTests() {
  setClientConfiguration();
  enableTestMode();
}

String testIdEditModeChoiceButton(EditModeChoice choice) {
  return 'scadnano.EditModeComponent.button.${choice.name}';
}

Store<AppState> testStore;
const EditModeComponentTestID = 'scadnano.EditModeComponent';
void initializeTestStore() {
  addTearDown(() {
    testStore = null;
  });

  testStore = Store<AppState>(
    app_state_reducer,
    initialState: util.default_state().rebuild((b) =>
        b.ui_state.edit_modes.replace([EditModeChoice.pencil, EditModeChoice.nick, EditModeChoice.helix])),
  );

  app.store = testStore;
}

void main() {
  initializeComponentTests();

  group('ConnectedEditModes', () {
    EditModeComponent component;

    setUp(() {
      initializeTestStore();
      var testJacket = mount((ReduxProvider()..store = testStore)(
        (ConnectedEditMode()..addTestId(EditModeComponentTestID))(),
      ));

      component = getComponentByTestId(testJacket.getInstance(), EditModeComponentTestID);
      expect(component, isNotNull, reason: 'ConnectedEditMode should be mounted');
    });

    tearDown(() {
      component = null;
    });

    group('renders a EditMode', () {
      test('that renders the select button', () {
        final select_button = getByTestId(component, testIdEditModeChoiceButton(EditModeChoice.select));
        expect(select_button, isNotNull);
      });
      test('that renders the pencil button', () {
        final pencil_button = getByTestId(component, testIdEditModeChoiceButton(EditModeChoice.pencil));
        expect(pencil_button, isNotNull);
      });
      test('that renders the nick button', () {
        final nick_button = getByTestId(component, testIdEditModeChoiceButton(EditModeChoice.nick));
        expect(nick_button, isNotNull);
      });
      test('that renders the ligate button', () {
        final ligate_button = getByTestId(component, testIdEditModeChoiceButton(EditModeChoice.ligate));
        expect(ligate_button, isNotNull);
      });
      test('that renders the insertion button', () {
        final insertion_button = getByTestId(component, testIdEditModeChoiceButton(EditModeChoice.insertion));
        expect(insertion_button, isNotNull);
      });
      test('that renders the deletion button', () {
        final deletion_button = getByTestId(component, testIdEditModeChoiceButton(EditModeChoice.deletion));
        expect(deletion_button, isNotNull);
      });
      test('that renders the helix button', () {
        final helix_button = getByTestId(component, testIdEditModeChoiceButton(EditModeChoice.helix));
        expect(helix_button, isNotNull);
      });
      test('that renders the backbone button', () {
        final backbone_button = getByTestId(component, testIdEditModeChoiceButton(EditModeChoice.backbone));
        expect(backbone_button, isNotNull);
      });

      test('that helix buttons is selected', () {
        final helix_button = getByTestId(component, testIdEditModeChoiceButton(EditModeChoice.helix));
        ClassNameMatcher matcher = ClassNameMatcher.expected('edit-mode-button-selected');
        expect(helix_button.className, matcher);
      });
      test('that backbone button is unselected', () {
        final backbone_button = getByTestId(component, testIdEditModeChoiceButton(EditModeChoice.backbone));
        ClassNameMatcher matcher = ClassNameMatcher.expected('edit-mode-button-unselected');
        expect(backbone_button.className, matcher);
      });
      test('that clicking helix buttons unselects it', () async {
        final helix_button = getByTestId(component, testIdEditModeChoiceButton(EditModeChoice.helix));
        expect(app.state.ui_state.edit_modes.contains(EditModeChoice.helix), true);
        click(helix_button);
        expect(app.state.ui_state.edit_modes.contains(EditModeChoice.helix), false);

        final redrawCount = await component.didRedraw().future.timeout(Duration(milliseconds: 20));
        expect(redrawCount, 1);
        ClassNameMatcher matcher = ClassNameMatcher.expected('edit-mode-button-unselected');
        expect(helix_button.className, matcher);
      });
    });
  });
}
