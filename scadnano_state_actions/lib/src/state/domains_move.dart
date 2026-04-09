import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import '../serializers.dart';
import 'domain.dart';
import 'group.dart';
import 'helix.dart';
import 'strand.dart';
import 'address.dart';

part 'domains_move.g.dart';

abstract class DomainsMove with BuiltJsonSerializable implements Built<DomainsMove, DomainsMoveBuilder> {
  factory DomainsMove.from([void Function(DomainsMoveBuilder) updates]) = _$DomainsMove;

  DomainsMove._();

  static Serializer<DomainsMove> get serializer => _$domainsMoveSerializer;

  @memoized
  int get hashCode;

  /************************ end BuiltValue boilerplate ************************/

  factory DomainsMove({
    required BuiltList<Domain> domains_moving,
    required BuiltList<Domain> all_domains,
    required BuiltList<Strand> strands_with_domains_moving,
    required BuiltMap<int, Helix> helices,
    required BuiltMap<String, HelixGroup> groups,
    required BuiltMap<int, int> original_helices_view_order_inverse,
    required Address original_address,
    bool copy = false,
    bool keep_color = true,
  }) {
    var domains_fixed =
        copy
            ? all_domains
            : [
              for (var domain in all_domains)
                if (!domains_moving.contains(domain)) domain,
            ];
    return DomainsMove.from(
      (b) =>
          b
            ..domains_moving.replace(domains_moving)
            ..domains_fixed.replace(domains_fixed)
            ..strands_with_domains_moving.replace(strands_with_domains_moving)
            ..helices.replace(helices)
            ..groups.replace(groups)
            ..original_helices_view_order_inverse.replace(original_helices_view_order_inverse)
            ..original_address.replace(original_address)
            ..current_address.replace(original_address)
            ..copy = copy
            ..keep_color = keep_color
            ..allowable = true,
    );
  }

  BuiltList<Domain> get domains_moving;

  BuiltList<Domain> get domains_fixed;

  BuiltMap<int, Helix> get helices;

  BuiltMap<String, HelixGroup> get groups;

  BuiltList<Strand> get strands_with_domains_moving;

  // Since copied Domains may come from a different Design with different groups, we need to
  // store this to know how to position them in new HelixGroups.
  BuiltMap<int, int> get original_helices_view_order_inverse;

  Address get original_address;

  Address get current_address;

  bool get allowable;

  bool get copy;

  bool get keep_color;

  Helix get original_helix => helices[original_address.helix_idx]!;

  Helix get current_helix => helices[current_address.helix_idx]!;

  int get original_view_order =>
      groups[original_helix.group]!.helices_view_order_inverse[original_helix.idx]!;

  int get current_view_order => groups[current_helix.group]!.helices_view_order_inverse[current_helix.idx]!;

  int get delta_offset => current_address.offset - original_address.offset;

  int get delta_view_order => current_view_order - original_view_order;

  bool get delta_forward => current_address.forward != original_address.forward;

  bool get is_nontrivial => original_address != current_address;

  @memoized
  Map<int, List<Domain>> get domains_moving_on_helix {
    Map<int, List<Domain>> map = {for (int idx in helices.keys) idx: []};
    for (var domain in domains_moving) {
      map[domain.helix]!.add(domain);
    }
    return map;
  }

  @memoized
  Map<int, List<Domain>> get domains_fixed_on_helix {
    Map<int, List<Domain>> map = {for (int idx in helices.keys) idx: []};
    for (var domain in domains_fixed) {
      map[domain.helix]!.add(domain);
    }
    return map;
  }

  @memoized
  Map<Strand, List<Domain>> get domains_moving_from_strand {
    Set<Domain> domains_moving_set = domains_moving.toSet();
    Map<Strand, List<Domain>> map = {for (var strand in strands_with_domains_moving) strand: []};
    for (var strand in map.keys) {
      for (var domain in strand.domains) {
        if (domains_moving_set.contains(domain)) {
          map[strand]!.add(domain);
        }
      }
    }
    return map;
  }
}
