import '../state/domain.dart';
import '../state/helix.dart';
import '../state/strand.dart';
import '../state/dna_design.dart';
import '../actions/actions.dart' as actions;

/// Converts deletions and insertions by "inlining" them. Insertions and deletions are removed,
/// and their substrands have their lengths altered. Also, major tick marks on the helices will be
/// shifted to preserve their adjacency to bases already present. For example, if there are major
/// tick marks at 0, 8, 18, 24, and a deletion between 0 and 8, then the substrand is shorted by 1,
/// and the tick marks become 0, 7, 15, 23, and the helix's maximum offset is shrunk by 1.
///
/// We assume that a major tick mark appears just to the LEFT of the offset it encodes, e.g.,
/// with minimum offset set, a major tick mark at offset 0 is the leftmost tick mark that could appear.
DNADesign inline_insertions_deletions_reducer(DNADesign design, actions.InlineInsertionsDeletions _) {
  Map<int, Helix> helices_new = design.helices.toMap();
  List<StrandBuilder> strand_builders_new = design.strands.map((s) => s.toBuilder()).toList();
  for (int helix_idx = 0; helix_idx < design.helices.length; helix_idx++) {
    _inline_deletions_insertions_on_helix(design, helix_idx, helices_new, strand_builders_new);
  }
  List<Strand> strands = strand_builders_new.map((b) => b.build()).toList();
  for (int i = 0; i < strands.length; i++) {
    strands[i] = strands[i].initialize();
  }
  return design.rebuild((b) => b..helices.replace(helices_new)..strands.replace(strands));
}

_inline_deletions_insertions_on_helix(
    DNADesign design, int helix_idx, Map<int, Helix> helices_new, List<StrandBuilder> strands_new) {
  var helices = design.helices;
  //////////////////////////////////////////////////////////////////////////////////////////////////////
  // first gather information before changing anything

  Helix helix = helices[helix_idx];

  // gather all mods on helix
  var deletions = [
    for (var substrand in design.domains_on_helix(helix_idx))
      for (var deletion in substrand.deletions) deletion
  ];
  var insertions = [
    for (var substrand in design.domains_on_helix(helix_idx))
      for (var insertion in substrand.insertions) insertion
  ];

  // change max offset
  int insertions_length =
      insertions.isEmpty ? 0 : [for (var insertion in insertions) insertion.length].reduce((a, b) => a + b);
  int delta_length = insertions_length - deletions.length;

  // combined collection of deletions/insertions into one dict mapping offset --> None/len, where
  // value of -1 indicates deletion, and otherwise is length of insertion
  Map<int, int> dels_ins = {};
  for (int deletion in deletions) {
    dels_ins[deletion] = -1;
  }
  for (var insertion in insertions) {
    dels_ins[insertion.offset] = insertion.length;
  }

  // put offsets in sorted order
  List<int> dels_ins_offsets_sorted = dels_ins.keys.toList();
  dels_ins_offsets_sorted.sort();

  // fix helix major ticks
  List<int> major_ticks = helix.calculate_major_ticks(design.major_tick_distance);
  major_ticks.sort();

  //////////////////////////////////////////////////////////////////////////////////////////////////////
  // now that info is gathered, start changing things

  helix = helix.rebuild((b) => b.max_offset = b.max_offset + delta_length);
  if (major_ticks.length > 0) {
    int major_tick_idx = 0;
    int delta_acc = 0; // accumulated delta; insertions add to this and deletions subtract from it
    for (int offset in dels_ins_offsets_sorted) {
      // go to first major tick great than offset, updating passed ones by delta_acc
      while (major_tick_idx < major_ticks.length && major_ticks[major_tick_idx] <= offset) {
        major_ticks[major_tick_idx] += delta_acc;
        major_tick_idx++;
      }
      delta_acc += dels_ins[offset];
    }
    // if necessary, update major ticks beyond last ins/del
    while (major_tick_idx < major_ticks.length) {
      major_ticks[major_tick_idx] += delta_acc;
      major_tick_idx++;
    }
    // TODO: check if regularly spaced and reaching both ends, and if so set helix.major_tick_distance
    helix = helix.rebuild((b) => b..major_ticks.replace(major_ticks));
  }

  // put back into map of helices
  helices_new[helix_idx] = helix;

  // fix substrand start/end offsets
  var substrands_both_directions = design.domains_on_helix(helix_idx);
  // go one direction at a time so we never have overlapping substrands
  var substrands_one_direction = {
    true: substrands_both_directions.where((ss) => ss.forward),
    false: substrands_both_directions.where((ss) => !ss.forward),
  };
  for (bool forward in [true, false]) {
    var substrands = substrands_one_direction[forward].toList();
    int delta_acc = 0;
    substrands.sort((ss1, ss2) => ss1.start - ss2.start);
    for (var substrand in substrands) {
      int new_start = substrand.start + delta_acc;
      delta_acc += substrand.dna_length() - substrand.visual_length;
      int new_end = substrand.end + delta_acc;
      Domain new_substrand = substrand.rebuild((b) => b
        ..start = new_start
        ..end = new_end
        ..insertions.replace([])
        ..deletions.replace([]));

      // find strand where this substrand resides and replace it
      Strand strand = design.substrand_to_strand[substrand];
      int strand_idx = design.strand_to_index[strand];
      for (int ss_idx = 0; ss_idx < strand.substrands.length; ss_idx++) {
        if (strand.substrands[ss_idx] is Domain && strand.substrands[ss_idx] == substrand) {
          strands_new[strand_idx].substrands[ss_idx] = new_substrand;
          break;
        }
      }
    }
  }
}
