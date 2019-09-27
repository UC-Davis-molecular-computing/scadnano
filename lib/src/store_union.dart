import 'dart:async';

import 'package:async/async.dart';
import 'package:w_flux/w_flux.dart';

/// Store that combines 2 other existing stores and triggers in response to either of them triggering.
class Store2<A extends Store, B extends Store> extends Store {
  A store_a;
  B store_b;

  Stream _stream;

  Store2(A a, B b) : super() {
    this.store_a = a;
    this.store_b = b;
    this._stream = StreamZip([this.store_a, this.store_b]);
  }

  Store2.withTransformer(A a, B b, StreamTransformer<dynamic, dynamic> transformer)
      : super.withTransformer(transformer) {
    this.store_a = a;
    this.store_b = b;
    this._stream = StreamZip([this.store_a, this.store_b]);
  }

  @override
  StreamSubscription<Store2<A, B>> listen(StoreHandler onData,
      {Function onError, void Function() onDone, bool cancelOnError}) {
    this._stream.listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
}
