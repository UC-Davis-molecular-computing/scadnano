@TestOn('browser')
// import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:over_react_test/jacket.dart';
import 'package:over_react_test/over_react_test.dart';
import 'package:react/react_client/react_interop.dart';
// import 'package:react/react_client.dart';
// import 'package:redux/redux.dart';
import 'package:scadnano/src/app.dart';
// import 'package:scadnano/src/reducers/app_state_reducer.dart';
import 'package:scadnano/src/state/app_state.dart';
import 'package:scadnano/src/state/edit_mode.dart';
import 'package:scadnano/src/view/edit_mode.dart';
import 'package:test/test.dart';

import 'package:scadnano/src/util.dart' as util;
import '../utils.dart' as utils;

String testIdEditModeChoiceButton(EditModeChoice choice) {
  return 'scadnano.EditModeComponent.button.${choice.name}';
}

const EditModeComponentTestID = 'scadnano.EditModeComponent';

AppState initializeTestState() {
  return util
      .default_state()
      .rebuild((b) => b.ui_state.edit_modes.replace([EditModeChoice.pencil, EditModeChoice.nick]));
}

void main() {
  utils.initializeComponentTests();

  group('ConnectedEditModes', () {
    Ref<EditModeComponent> editModeRef;
    EditModeComponent component;

    setUp(() {
      utils.initializeTestStore(initializeTestState());
      editModeRef = createRef();
      mount((ReduxProvider()..store = app.store)(
        (ConnectedEditMode()
          ..addTestId(EditModeComponentTestID)
          ..ref = editModeRef)(),
      ));
      // final editModeComponent = editModeRef.current;
      // component = getComponentByTestId(editModeComponent, EditModeComponentTestID);
      component = editModeRef.current;

      expect(component, isNotNull, reason: 'ConnectedEditMode should be mounted');
    });

    tearDown(() {
      editModeRef = null;
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
      test('that renders the backbone button', () {
        final backbone_button = getByTestId(component, testIdEditModeChoiceButton(EditModeChoice.backbone));
        expect(backbone_button, isNotNull);
      });

      test('that nick buttons is selected', () {
        final nick_button = getByTestId(component, testIdEditModeChoiceButton(EditModeChoice.nick));
        ClassNameMatcher matcher = ClassNameMatcher.expected('edit-mode-button-selected');
        expect(nick_button.className, matcher);
      });
      test('that backbone button is unselected', () {
        final backbone_button = getByTestId(component, testIdEditModeChoiceButton(EditModeChoice.backbone));
        ClassNameMatcher matcher = ClassNameMatcher.expected('edit-mode-button-unselected');
        expect(backbone_button.className, matcher);
      });
      test('that clicking nick buttons unselects it', () async {
        final nick_button = getByTestId(component, testIdEditModeChoiceButton(EditModeChoice.nick));
        expect(app.state.ui_state.edit_modes.contains(EditModeChoice.nick), true);
        click(nick_button);
        expect(app.state.ui_state.edit_modes.contains(EditModeChoice.nick), false);

        final redrawCount = await component.didRedraw().future.timeout(Duration(milliseconds: 20));
        expect(redrawCount, 1);
        ClassNameMatcher matcher = ClassNameMatcher.expected('edit-mode-button-unselected');
        expect(nick_button.className, matcher);
      });
    });
  });
}
