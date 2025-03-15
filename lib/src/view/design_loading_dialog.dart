import 'package:built_collection/built_collection.dart';
import 'package:meta/meta.dart';
import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';
import '../state/dialog.dart';

import '../app.dart';
import '../state/app_state.dart';
import '../actions/actions.dart' as actions;

part 'design_loading_dialog.over_react.g.dart';

DesignLoadingDialogProps set_design_loading_dialog_props(DesignLoadingDialogProps elt, AppState state) =>
    elt..show = state.ui_state.show_load_dialog;

UiFactory<DesignLoadingDialogProps> ConnectedLoadingDialog = connect<AppState, DesignLoadingDialogProps>(
  mapStateToProps: (state) => set_design_loading_dialog_props(DesignLoadingDialog(), state),
)(DesignLoadingDialog);

UiFactory<DesignLoadingDialogProps> DesignLoadingDialog = _$DesignLoadingDialog;

mixin DesignLoadingDialogProps on UiProps {
  late bool show;
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
