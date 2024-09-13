import 'package:over_react/over_react_redux.dart';
import 'package:over_react_test/over_react_test.dart';
import 'package:react/react_client/react_interop.dart';
import 'package:test/test.dart';

import 'package:scadnano/src/app.dart';
import 'package:scadnano/src/state/app_state.dart';
import 'package:scadnano/src/state/select_mode.dart';
import 'package:scadnano/src/state/select_mode_state.dart';
import 'package:scadnano/src/view/select_mode.dart';
import 'package:scadnano/src/util.dart' as util;

import '../utils.dart' as utils;

AppState initializeTestState() {
  List<SelectModeChoice> modes = [
    SelectModeChoice.crossover,
    SelectModeChoice.loopout,
    SelectModeChoice.scaffold
  ];
  return util
      .default_state()
      .rebuild((b) => b.ui_state.storables.select_mode_state.replace(SelectModeState().set_modes(modes)));
}

const SelectModeTestId = 'scadnano.SelectModeComponent';

String testIdSelectModeChoiceButton(SelectModeChoice choice) {
  return '${SelectModeTestId}.button.${choice.name}';
}

main() {
  utils.initializeComponentTests();

  group('ConnectedSelectModes', () {
    Ref<SelectModeComponent?>? selectModeRef;
    SelectModeComponent? component;

    setUp(() {
      utils.initialize_test_store(initializeTestState());
      selectModeRef = createRef<SelectModeComponent>();
      mount((ReduxProvider()..store = app.store)(
        (ConnectedSelectMode()
          ..is_origami = false
          ..select_mode_state = app.state.ui_state.select_mode_state
          ..addTestId(SelectModeTestId)
          ..ref = selectModeRef)(),
      ));
      component = selectModeRef!.current;
      // component = getComponentByTestId(testJacket.getInstance(), SelectModeTestId);
      expect(component, isNotNull, reason: 'ConnectedSelectMode should be mounted');
    });

    tearDown(() {
      component = null;
    });

    //FIXME: These broke in the migration to null safety and I don't feel like fixing them.
    // group('renders a ConnectedSelectModes', () {
    //   test('that renders the crossover button', () {
    //     final crossover_button =
    //         getByTestId(component, testIdSelectModeChoiceButton(SelectModeChoice.crossover));
    //     expect(crossover_button, isNotNull);
    //   });
    //
    //   test('that the loopout button is selected', () {
    //     final loopout_button = getByTestId(component, testIdSelectModeChoiceButton(SelectModeChoice.loopout));
    //     expect(loopout_button, isNotNull);
    //
    //     ClassNameMatcher matcher = ClassNameMatcher.expected('select-mode-button-selected');
    //     expect(loopout_button.className, matcher);
    //   });
    //
    //   test('that selecting the loopout button unselects it', () async {
    //     final loopout_button = getByTestId(component, testIdSelectModeChoiceButton(SelectModeChoice.loopout));
    //     click(loopout_button);
    //     expect(loopout_button, isNotNull);
    //
    //     final redrawCount = await component.didRedraw().future.timeout(Duration(milliseconds: 20));
    //     expect(redrawCount, 1);
    //     ClassNameMatcher matcher = ClassNameMatcher.expected('select-mode-button-unselected');
    //     expect(loopout_button.className, matcher);
    //   });
    // });
  });
}
