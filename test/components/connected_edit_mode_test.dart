@TestOn('browser')
import 'package:over_react/over_react_redux.dart';
import 'package:over_react_test/over_react_test.dart';
import 'package:react/react_client/react_interop.dart';
import 'package:scadnano/src/app.dart';
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

AppState initialize_test_state() {
  return util.default_state().rebuild(
    (b) => b.ui_state.storables.edit_modes.replace([EditModeChoice.pencil, EditModeChoice.nick]),
  );
}

void main() {
  utils.initializeComponentTests();

  group('ConnectedEditModes', () {
    Ref<EditModeComponent?>? editModeRef;
    EditModeComponent? component;

    setUp(() {
      utils.initialize_test_store(initialize_test_state());
      editModeRef = createRef<EditModeComponent>();
      mount(
        (ReduxProvider()..store = app.store)(
          ((ConnectedEditMode()..modes = app.state.ui_state.edit_modes)
            ..addTestId(EditModeComponentTestID)
            ..ref = editModeRef)(),
        ),
      );
      // final editModeComponent = editModeRef.current;
      // component = getComponentByTestId(editModeComponent, EditModeComponentTestID);
      component = editModeRef!.current;

      expect(component, isNotNull, reason: 'ConnectedEditMode should be mounted');
    });

    tearDown(() {
      editModeRef = null;
      component = null;
    });

    group('renders a EditMode', () {
      test('that_renders_the_select_button', () {
        final select_button = getByTestId(component, testIdEditModeChoiceButton(EditModeChoice.select));
        expect(select_button, isNotNull);
      });
      test('that_renders_the_pencil_button', () {
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
      test('that nick buttons is selected', () {
        final nick_button = getByTestId(component, testIdEditModeChoiceButton(EditModeChoice.nick));
        ClassNameMatcher matcher = ClassNameMatcher.expected('edit-mode-button-selected');
        expect(nick_button.className, matcher);
      });
      test('that clicking nick buttons unselects it', () async {
        final nick_button = getByTestId(component, testIdEditModeChoiceButton(EditModeChoice.nick));
        expect(app.state.ui_state.edit_modes.contains(EditModeChoice.nick), true);
        click(nick_button);
        expect(app.state.ui_state.edit_modes.contains(EditModeChoice.nick), false);

        final redrawCount = await component!.didRedraw().future.timeout(Duration(milliseconds: 20));
        expect(redrawCount, 1);
        ClassNameMatcher matcher = ClassNameMatcher.expected('edit-mode-button-unselected');
        expect(nick_button.className, matcher);
      });
    });
  });
}
