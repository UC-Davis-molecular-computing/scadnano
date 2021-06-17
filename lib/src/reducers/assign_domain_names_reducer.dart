import 'package:built_collection/built_collection.dart';
import '../state/domain.dart';
import '../state/design.dart';
import '../state/loopout.dart';
import '../state/substrand.dart';
import 'package:tuple/tuple.dart';

import '../state/strand.dart';
import '../state/app_state.dart';
import '../actions/actions.dart' as actions;
import '../util.dart' as util;
import '../constants.dart' as constants;
import 'assign_or_remove_dna_reducer.dart';

Strand compute_domain_name_complements(Strand strand_to, Strand strand_from) {
  List<Substrand> substrands = strand_to.substrands.toList();
  for (int ss_idx = 0; ss_idx < strand_to.substrands.length; ss_idx++) {
    Substrand substrand_to = strand_to.substrands[ss_idx];
    if (substrand_to is Domain) {
      Domain domain_to = substrand_to as Domain;
      int helix_idx = domain_to.helix;
      List<Domain> domains_on_helix_from =
          strand_from.domains_on_helix[helix_idx]?.toList() ?? [];
      for (var domain_from in domains_on_helix_from) {
        if (domain_to != domain_from && domain_to.overlaps(domain_from) 
        && domain_to.start == domain_from.start && domain_to.end == domain_from.end
        && domain_from.name != null) {
          var domain_name_to = complement_domain_name(domain_from.name);
          domain_to = domain_to.rebuild((b) => b..name = domain_name_to);
          substrands[ss_idx] = domain_to;
          break;
        }
      }
    }
  }
  strand_to = strand_to.rebuild((b) => b..substrands.replace(substrands));
  return strand_to;
}

String complement_domain_name(String name) => name[name.length-1] == "*" ? name.substring(0, name.length-1) : name+"*";

BuiltList<Strand> assign_domain_name_reducer_complement_from_bound_strands(
    BuiltList<Strand> strands,
    AppState state,
    actions.AssignDomainNameComplementFromBoundStrands action) {
  List<Strand> all_strands = strands.toList();
  for (var strand_to_assign in action.strands) {
    int strand_to_assign_idx = strands.indexOf(strand_to_assign);
    for (var other_strand
        in state.design.strands_overlapping[strand_to_assign]) {
      strand_to_assign =
          compute_domain_name_complements(strand_to_assign, other_strand);
    }
    all_strands[strand_to_assign_idx] = strand_to_assign;
  }
  return all_strands.build();
}
