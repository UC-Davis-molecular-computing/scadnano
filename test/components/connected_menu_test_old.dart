// @dart=2.9

import 'dart:convert';
import 'dart:html';

import 'package:test/test.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:over_react_test/jacket.dart';
import 'package:over_react_test/over_react_test.dart';
import 'package:react/react_client/react_interop.dart';

import 'package:scadnano/src/app.dart';
import 'package:scadnano/src/state/app_state.dart';
import 'package:scadnano/src/state/design.dart';
import 'package:scadnano/src/view/menu.dart';
import 'package:scadnano/src/util.dart' as util;

import '../utils.dart' as utils;

AppState initializeTestState() {
  return util.default_state().rebuild((b) => b
    ..ui_state.storables.show_dna = false
    ..ui_state.storables.show_mismatches = true
    ..design.replace(two_helices_design));
}

const MenuTestId = 'scadnano.MenuComponent';

String two_helices_json = r"""
 {
  "version": "0.0.1", "helices": [ {"grid_position": [0, 0]}, {"grid_position": [0, 1]} ],
  "strands": [
    {
      "substrands": [
        {"helix": 0, "forward": true , "start": 0, "end": 16}
      ]
    },
    {
      "substrands": [
        {"helix": 0, "forward": false , "start": 0, "end": 16}
      ]
    },
    {
      "substrands": [
        {"helix": 1, "forward": true , "start": 0, "end": 16}
      ]
    },
    {
      "substrands": [
        {"helix": 1, "forward": false , "start": 0, "end": 16}
      ]
    }
  ]
 }
  """;
Design two_helices_design = Design.from_json_str(two_helices_json, false);

main() {
  utils.initializeComponentTests();

  group('ConnectedSelectModes', () {
    Ref<MenuComponent> menuRef;
    MenuComponent component;

    setUp(() {
      utils.initialize_test_store(initializeTestState());
      menuRef = createRef();
      mount((ReduxProvider()..store = app.store)(
        (ConnectedMenu()
          ..addTestId(MenuTestId)
          ..ref = menuRef)(),
      ));
      component = menuRef.current;
      // component = getComponentByTestId(testJacket.getInstance(), MenuTestId);
      expect(component, isNotNull, reason: 'ConnectedMenu should be mounted');
    });

    tearDown(() {
      menuRef = null;
      component = null;
    });

    group('renders a ConnectedMenu', () {
      test('that show DNA checkmarks can be checked off', () async {
        CheckboxInputElement show_dna_checkbox =
            getByTestId(component, 'scadnano.MenuComponent.input.show_dna_sequences');
        expect(show_dna_checkbox, isNotNull);

        expect(show_dna_checkbox.checked, false);
        expect(app.state.ui_state.show_dna, false);

        change(show_dna_checkbox);

        final redrawCount = await component.didRedraw().future.timeout(Duration(milliseconds: 20));
        expect(redrawCount, 1);
        expect(show_dna_checkbox.checked, true);
        expect(app.state.ui_state.show_dna, true);
      });

      test('that show DNA mismatches can be checked off', () async {
        CheckboxInputElement show_mismatches =
            getByTestId(component, 'scadnano.MenuComponent.input.show_mismatches');
        expect(show_mismatches, isNotNull);

        expect(show_mismatches.checked, true);
        expect(app.state.ui_state.show_mismatches, true);

        change(show_mismatches);

        final redrawCount = await component.didRedraw().future.timeout(Duration(milliseconds: 20));
        expect(redrawCount, 1);
        expect(show_mismatches.checked, false);
        expect(app.state.ui_state.show_mismatches, false);
      });

      test('that Grid can be adjusted to none', () async {
        // TODO(benlee12): figure out how to simulate select events
        SelectElement select_grid = getByTestId(component, 'scadnano.MenuComponent.select.grid');
        expect(select_grid, isNotNull);
        expect(select_grid.value, 'square');

        // mouseDown(select_grid);
        // keyDown(select_grid, {'keyCode': '40'});
        // keyDown(select_grid, {'keyCode': '40'});
        // keyDown(select_grid, {'keyCode': '40'});
        // keyDown(select_grid, {'keyCode': '13'});
        // change(select_grid, {
        //   'target': {
        //     'value': 'none',
        //   }
        // });
        // keyDown(select_grid, {
        //   'target': {'value': '40'}
        // });
        // keyDown(select_grid, {
        //   'target': {'value': '40'}
        // });
        // keyDown(select_grid, {
        //   'target': {'value': '13'}
        // });

        // final redrawCount = await component.didRedraw().future.timeout(Duration(milliseconds: 20));
        // expect(redrawCount, 1);
        // expect(select_grid.value, 'none');
        // expect(app.state.ui_state.show_mismatches, false);
      });
    });
  });
}
