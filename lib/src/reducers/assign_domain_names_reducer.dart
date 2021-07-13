import 'package:built_collection/built_collection.dart';
import '../state/domain.dart';
import '../state/substrand.dart';

import '../state/strand.dart';
import '../state/app_state.dart';
import '../actions/actions.dart' as actions;

BuiltList<Strand> assign_domain_name_complement_from_bound_strands_reducer(
    BuiltList<Strand> strands, AppState state, actions.AssignDomainNameComplementFromBoundStrands action) {
  List<Domain> computed_domains = [];
  List<Strand> all_strands = strands.toList();
  for (var strand_to_assign in action.strands) {
    int strand_to_assign_idx = strands.indexOf(strand_to_assign);
    for (var other_strand in state.design.strands_overlapping[strand_to_assign]) {
      strand_to_assign = compute_domain_name_complements(strand_to_assign, other_strand, computed_domains);
    }
    all_strands[strand_to_assign_idx] = strand_to_assign;
  }
  return all_strands.build();
}

Strand compute_domain_name_complements(Strand strand_to, Strand strand_from, List<Domain> computed_domains) {
  List<Substrand> substrands = strand_to.substrands.toList();
  for (int ss_idx = 0; ss_idx < strand_to.substrands.length; ss_idx++) {
    Substrand substrand_to = strand_to.substrands[ss_idx];
    if (substrand_to is Domain) {
      Domain domain_to = substrand_to;
      int helix_idx = domain_to.helix;
      List<Domain> domains_on_helix_from = strand_from.domains_on_helix[helix_idx]?.toList() ?? [];
      for (var domain_from in domains_on_helix_from) {
        if (domain_to != domain_from &&
            domain_to.overlaps(domain_from) &&
            domain_to.start == domain_from.start &&
            domain_to.end == domain_from.end &&
            domain_from.name != null &&
            !computed_domains.contains(domain_to)) {
          var domain_name_to = complement_domain_name(domain_from.name);
          domain_to = domain_to.rebuild((b) => b..name = domain_name_to);
          substrands[ss_idx] = domain_to;
          computed_domains.add(domain_from);
          break;
        }
      }
    }
  }
  strand_to = strand_to.rebuild((b) => b..substrands.replace(substrands));
  return strand_to;
}

String complement_domain_name(String name) =>
    name[name.length - 1] == "*" ? name.substring(0, name.length - 1) : name + "*";

/////////////////////////////

BuiltList<Strand> assign_domain_name_complement_from_bound_domains_reducer(
    BuiltList<Strand> strands, AppState state, actions.AssignDomainNameComplementFromBoundDomains action) {
  List<Domain> computed_domains = [];
  List<Domain> all_domains = action.domains.toList();
  for (var domain_to_assign in action.domains) {
    Strand strand_to = state.design.substrand_to_strand[domain_to_assign];
    for (var other_domain in state.design.domains_on_helix_overlapping(domain_to_assign)) {
      strand_to = compute_domain_name_complements_for_bound_names(
          strand_to, domain_to_assign, other_domain, computed_domains);
    }
  }
  print(action.domains);
}

Strand compute_domain_name_complements_for_bound_names(
    Strand strand_to, Domain domain_to_assign, Domain other_domain, List<Domain> computed_domains) {
  var substrands = strand_to.substrands.toList();
  for (int ss_idx = 0; ss_idx < strand_to.substrands.length; ss_idx++) {
    if (domain_to_assign == substrands[ss_idx]) {
      int helix_idx = domain_to_assign.helix;
      List<Domain> domains_on_helix_from = strand_to.domains_on_helix[helix_idx]?.toList() ?? [];
      for (var domain_from in domains_on_helix_from) {
        if (domain_to_assign != domain_from &&
            domain_to_assign.overlaps(domain_from) &&
            domain_to_assign.start == domain_from.start &&
            domain_to_assign.end == domain_from.end &&
            domain_from.name != null &&
            !computed_domains.contains(domain_to_assign)) {
          var domain_name_to = complement_domain_name(domain_from.name);
          domain_to_assign = domain_to_assign.rebuild((b) => b..name = domain_name_to);
          substrands[ss_idx] = domain_to_assign;
          computed_domains.add(domain_from);
          break;
        }
      }
      break;
    }
  }
  return strand_to.rebuild((b) => b..substrands.replace(substrands));
}
