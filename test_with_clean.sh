bash clean.sh
cd scadnano_state_actions && dart run build_runner build --delete-conflicting-outputs && cd ..
cd scadnano_reducers && dart run build_runner build --delete-conflicting-outputs && cd ..
dart run build_runner test
