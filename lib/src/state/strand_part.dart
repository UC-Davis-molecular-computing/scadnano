import 'package:built_value/built_value.dart';

// implemented by Loopout, Crossover, BoundSubstrand
abstract class StrandPart {
  // can't really be nullable but need a way to delay setting it until whole Strand is built
  @nullable
  String get strand_id;
}
