import 'dart:async';

import 'package:redux/redux.dart';

import '../state/local_storage_design_choice.dart';
import '../state/app_state.dart';
import '../actions/actions.dart' as actions;
import '../app.dart';
import 'local_storage.dart';

Timer timer;

periodic_design_save_local_storage_middleware(Store<AppState> store, action, NextDispatcher next) {
  next(action);

  if (action is actions.LocalStorageDesignChoiceSet || action is actions.SetAppUIStateStorable) {
    LocalStorageDesignChoice choice;
    if (action is actions.LocalStorageDesignChoiceSet) {
      choice = action.choice;
    } else if (action is actions.SetAppUIStateStorable) {
      choice = action.storables.local_storage_design_choice;
    }

    if (choice.option == LocalStorageDesignOption.periodic) {
      stop_timer_periodic_design_save_local_storage(); // stop just in case one is already going
      start_timer_periodic_design_save_local_storage(choice.period_seconds);
    } else {
      stop_timer_periodic_design_save_local_storage();
    }
  }
}

start_timer_periodic_design_save_local_storage(int period_seconds) {
  if (period_seconds > 0) {
    Duration duration = Duration(seconds: period_seconds);
    timer = Timer.periodic(duration, (timer) {
      save(app.state, Storable.design);
    });
  } else {
    throw AssertionError('WARNING: period_seconds cannot be <= 0 but is ${period_seconds}');
  }
}

stop_timer_periodic_design_save_local_storage() {
  if (timer != null) {
    timer.cancel();
    timer = null;
  }
}
