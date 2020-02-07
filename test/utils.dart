import 'package:over_react/over_react.dart';
import 'package:react/react_client.dart';
import 'package:redux/redux.dart';
import 'package:scadnano/src/app.dart';
import 'package:scadnano/src/reducers/app_state_reducer.dart';
import 'package:scadnano/src/state/app_state.dart';
import 'package:test/test.dart';

void initializeComponentTests() {
  setClientConfiguration();
  enableTestMode();
}

Store<AppState> testStore;
void initializeTestStore(AppState state) {
  addTearDown(() {
    testStore = null;
  });

  testStore = Store<AppState>(
    app_state_reducer,
    initialState: state,
  );

  app.store = testStore;
}
