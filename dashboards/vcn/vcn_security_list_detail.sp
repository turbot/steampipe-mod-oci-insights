dashboard "vcn_security_list_detail" {

  title         = "OCI VCN Security List Detail"
  documentation = file("./dashboards/vcn/docs/vcn_security_list_detail.md")

  tags = merge(local.vcn_common_tags, {
    type = "Detail"
  })

  input "security_list_id" {
    title = "Select a security list:"
    query = query.vcn_security_list_input
    width = 4
  }

  container {

    card {
      width = 3

      query = query.vcn_security_list_ingress_ssh
      args  = [self.input.security_list_id.value]
    }

    card {
      width = 3

      query = query.vcn_security_list_ingress_rdp
      args  = [self.input.security_list_id.value]
    }

  }

  with "vcn_subnets_for_vcn_security_list" {
    query = query.vcn_subnets_for_vcn_security_list
    args  = [self.input.security_list_id.value]
  }

  with "vcn_vcns_for_vcn_security_list" {
    query = query.vcn_vcns_for_vcn_security_list
    args  = [self.input.security_list_id.value]
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.vcn_security_list
        args = {
          vcn_security_list_ids = [self.input.security_list_id.value]
        }
      }

      node {
        base = node.vcn_subnet
        args = {
          vcn_subnet_ids = with.vcn_subnets_for_vcn_security_list.rows[*].subnet_id
        }
      }

      node {
        base = node.vcn_vcn
        args = {
          vcn_vcn_ids = with.vcn_vcns_for_vcn_security_list.rows[*].vcn_id
        }
      }

      edge {
        base = edge.vcn_subnet_to_vcn_security_list
        args = {
          vcn_subnet_ids = with.vcn_subnets_for_vcn_security_list.rows[*].subnet_id
        }
      }

      edge {
        base = edge.vcn_vcn_to_vcn_security_list
        args = {
          vcn_vcn_ids = with.vcn_vcns_for_vcn_security_list.rows[*].vcn_id
        }
      }

    }
  }

  container {

    container {

      width = 6

      table {
        title = "Overview"
        type  = "line"
        width = 6
        query = query.vcn_security_list_overview
        args  = [self.input.security_list_id.value]

      }

      table {
        title = "Tags"
        width = 6
        query = query.vcn_security_list_tag
        args  = [self.input.security_list_id.value]

      }

    }

    container {

      width = 6

      table {
        title = "Ingress Rules"
        query = query.vcn_network_security_list_ingress_rule
        args  = [self.input.security_list_id.value]
      }

      table {
        title = "Egress Rules"
        query = query.vcn_network_security_list_egress_rule
        args  = [self.input.security_list_id.value]
      }

    }

  }

}

# Input queries

query "vcn_security_list_input" {
  sql = <<EOQ
    select
      b.display_name as label,
      b.id as value,
      json_build_object(
        'b.id', concat('id: ', right(reverse(split_part(reverse(b.id), '.', 1)), 8)),
        'b.region', concat('region: ', region),
        'c.name', concat('compartment: ', coalesce(c.title, 'root')),
        't.name', concat('tenant: ', t.name)
      ) as tags
    from
      oci_core_security_list as b
      left join oci_identity_compartment as c on b.compartment_id = c.id
      left join oci_identity_tenancy as t on b.tenant_id = t.id
    where
      b.lifecycle_state <> 'TERMINATED'
    order by
      b.display_name;
  EOQ
}

# With queries

query "vcn_subnets_for_vcn_security_list" {
  sql = <<-EOQ
    select
      id as subnet_id
    from
      oci_core_subnet,
      jsonb_array_elements_text(security_list_ids) as sid
    where
      sid = $1;
  EOQ
}

query "vcn_vcns_for_vcn_security_list" {
  sql = <<-EOQ
    select
      vcn_id
    from
      oci_core_security_list
    where
      id = $1
  EOQ
}

# Card queries

query "vcn_security_list_ingress_ssh" {
  sql = <<-EOQ
    with non_compliant_rules as (
      select
        id,
        count(*) as num_noncompliant_rules
      from
        oci_core_security_list,
        jsonb_array_elements(ingress_security_rules) as r
      where
        r ->> 'direction' = 'INGRESS'
        and r ->> 'sourceType' = 'CIDR_BLOCK'
        and r ->> 'source' = '0.0.0.0/0'
        and (
        r ->> 'protocol' = 'all'
        or (
        (r -> 'tcpOptions' -> 'destinationPortRange' ->> 'min')::integer <= 22
        and (r -> 'tcpOptions' -> 'destinationPortRange' ->> 'max')::integer >= 22
        )
      )
      and lifecycle_state <> 'TERMINATED'
      group by id
      )
      select
        case when non_compliant_rules.id is null then 'Restricted' else 'Unrestricted' end as value,
        'Ingress SSH' as label,
        case when non_compliant_rules.id is null then 'ok' else 'alert' end as type
      from
        oci_core_security_list as sl
        left join non_compliant_rules on non_compliant_rules.id = sl.id
      where
        sl.id = $1 and sl.lifecycle_state <> 'TERMINATED';
  EOQ
}

query "vcn_security_list_ingress_rdp" {
  sql = <<-EOQ
    with non_compliant_rules as (
      select
        id,
        count(*) as num_noncompliant_rules
      from
        oci_core_security_list,
        jsonb_array_elements(ingress_security_rules) as r
      where
        r ->> 'direction' = 'INGRESS'
        and r ->> 'sourceType' = 'CIDR_BLOCK'
        and r ->> 'source' = '0.0.0.0/0'
        and (
        r ->> 'protocol' = 'all'
        or (
        (r -> 'tcpOptions' -> 'destinationPortRange' ->> 'min')::integer <= 3389
        and (r -> 'tcpOptions' -> 'destinationPortRange' ->> 'max')::integer >= 3389
        )
      )
      and lifecycle_state <> 'TERMINATED'
      group by id
      )
      select
        case when non_compliant_rules.id is null then 'Restricted' else 'Unrestricted' end as value,
        'Ingress RDP' as label,
        case when non_compliant_rules.id is null then 'ok' else 'alert' end as type
      from
        oci_core_security_list as sl
        left join non_compliant_rules on non_compliant_rules.id = sl.id
      where
        sl.id = $1 and sl.lifecycle_state <> 'TERMINATED';
  EOQ
}

# Other detail page queries

query "vcn_security_list_overview" {
  sql = <<-EOQ
    select
      display_name as "Name",
      time_created as "Time Created",
      region as "Region",
      id as "OCID",
      compartment_id as "Compartment ID"
    from
      oci_core_security_list
    where
      id = $1 and lifecycle_state <> 'TERMINATED';
  EOQ
}

query "vcn_security_list_tag" {
  sql = <<-EOQ
    with jsondata as (
      select
        tags::json as tags
      from
        oci_core_security_list
      where
        id = $1 and lifecycle_state <> 'TERMINATED'
    )
    select
      key as "Key",
      value as "Value"
    from
      jsondata,
      json_each_text(tags)
    order by
      key;
  EOQ
}

query "vcn_network_security_list_ingress_rule" {
  sql = <<-EOQ
    select
      r ->> 'protocol' as "Protocol",
      r ->> 'source' as "Source",
      r ->> 'isStateless' as "Stateless"
    from
      oci_core_security_list,
      jsonb_array_elements(ingress_security_rules) as r
    where
      id  = $1 and lifecycle_state <> 'TERMINATED';
  EOQ
}

query "vcn_network_security_list_egress_rule" {
  sql = <<-EOQ
    select
      r ->> 'protocol' as "Protocol",
      r ->> 'destination' as "Destination",
      r ->> 'isStateless' as "Stateless"
    from
      oci_core_security_list,
      jsonb_array_elements(egress_security_rules) as r
    where
      id  = $1 and lifecycle_state <> 'TERMINATED';
  EOQ
}
