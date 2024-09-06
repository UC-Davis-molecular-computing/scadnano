// @dart=2.9
import 'package:built_collection/built_collection.dart';
import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';
import '../state/dialog.dart';

import '../app.dart';
import '../state/app_state.dart';
import '../actions/actions.dart' as actions;

part 'design_loading_dialog.over_react.g.dart';

UiFactory<DesignLoadingDialogProps> ConnectedLoadingDialog = connect<AppState, DesignLoadingDialogProps>(
  mapStateToProps: (state) {
    return DesignLoadingDialog()..show = state.ui_state.load_dialog;
  },
)(DesignLoadingDialog);

UiFactory<DesignLoadingDialogProps> DesignLoadingDialog = _$DesignLoadingDialog;

mixin DesignLoadingDialogProps on UiProps {
  bool show; // these are INITIAL values only
}

class DesignLoadingDialogComponent extends UiComponent2<DesignLoadingDialogProps> {
  @override
  render() {
    if (props.show == false) {
      return null;
    }
    return (Dom.div()..className = 'dialog-form-form dialog-design-loading')(Dom.span()('Loading...'));
  }
}
