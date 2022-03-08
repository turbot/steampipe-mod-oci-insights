dashboard "oci_vcn_network_security_group_detail" {

  title = "OCI VCN Network Security Group Detail"
  documentation = file("./dashboards/vcn/docs/vcn_network_security_group_detail.md")

  tags = merge(local.vcn_common_tags, {
    type = "Detail"
  })

  input "security_group_id" {
    title = "Select a security group:"
    sql   = query.oci_vcn_network_security_group_input.sql
    width = 4
  }

  container {

    card {
      width = 2

      query = query.oci_vcn_network_security_group_ingress_ssh
      args = {
        id = self.input.security_group_id.value
      }
    }

    card {
      width = 2

      query = query.oci_vcn_network_security_group_ingress_rdp
      args = {
        id = self.input.security_group_id.value
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
        query = query.oci_vcn_network_security_group_overview
        args = {
          id = self.input.security_group_id.value
        }

      }

      table {
        title = "Tags"
        width = 6

        query = query.oci_vcn_network_security_group_tag
        args = {
          id = self.input.security_group_id.value
        }

      }

    }

    container {
      width = 6

      table {
        title = "Ingress Rules"
        query = query.oci_vcn_network_security_group_ingress_rule
        args = {
          id = self.input.security_group_id.value
        }
      }

      table {
        title = "Egress Rules"
        query = query.oci_vcn_network_security_group_egress_rule
        args = {
          id = self.input.security_group_id.value
        }
      }

    }

  }

}

query "oci_vcn_network_security_group_input" {
  sql = <<EOQ
    select
      g.display_name as label,
      g.id as value,
      json_build_object(
        'c.name', coalesce(c.title, 'root'),
        'g.region', region,
        't.name', t.name
      ) as tags
    from
      oci_core_network_security_group as g
      left join oci_identity_compartment as c on g.compartment_id = c.id
      left join oci_identity_tenancy as t on g.tenant_id = t.id
    where
      g.lifecycle_state <> 'TERMINATED'
    order by
      g.display_name;
  EOQ
}

query "oci_vcn_network_security_group_ingress_ssh" {
  sql = <<-EOQ
    with non_compliant_rules as (
      select
        id,
        count(*) as num_noncompliant_rules
      from
        oci_core_network_security_group,
        jsonb_array_elements(rules) as r
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
        oci_core_network_security_group as nsg
        left join non_compliant_rules on non_compliant_rules.id = nsg.id
      where
        nsg.id = $1 and nsg.lifecycle_state <> 'TERMINATED';
  EOQ

  param "id" {}
}

query "oci_vcn_network_security_group_ingress_rdp" {
  sql = <<-EOQ
    with non_compliant_rules as (
      select
        id,
        count(*) as num_noncompliant_rules
      from
        oci_core_network_security_group,
        jsonb_array_elements(rules) as r
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
        oci_core_network_security_group as nsg
        left join non_compliant_rules on non_compliant_rules.id = nsg.id
      where
        nsg.id = $1 and nsg.lifecycle_state <> 'TERMINATED';
  EOQ

  param "id" {}
}

query "oci_vcn_network_security_group_overview" {
  sql = <<-EOQ
    select
      display_name as "Name",
      time_created as "Time Created",
      region as "Region",
      id as "OCID",
      compartment_id as "Compartment ID"
    from
      oci_core_network_security_group
    where
      id = $1 and lifecycle_state <> 'TERMINATED';
  EOQ

  param "id" {}
}

query "oci_vcn_network_security_group_tag" {
  sql = <<-EOQ
    with jsondata as (
      select
        tags::json as tags
      from
        oci_core_network_security_group
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

  param "id" {}
}

query "oci_vcn_network_security_group_ingress_rule" {
  sql = <<-EOQ
    select
      r ->> 'protocol' as "Protocol",
      r ->> 'source' as "Source",
      r ->> 'isStateless' as "Stateless",
      r ->> 'isValid' as "Valid"
    from
      oci_core_network_security_group,
      jsonb_array_elements(rules) as r
    where
    r ->> 'direction' = 'INGRESS' and
      id  = $1 and lifecycle_state <> 'TERMINATED';
  EOQ

  param "id" {}
}

query "oci_vcn_network_security_group_egress_rule" {
  sql = <<-EOQ
    select
      r ->> 'protocol' as "Protocol",
      r ->> 'destination' as "Destination",
      r ->> 'isStateless' as "Stateless",
      r ->> 'isValid' as "Valid"
    from
      oci_core_network_security_group,
      jsonb_array_elements(rules) as r
    where
      r ->> 'direction' = 'EGRESS' and
      id  = $1 and lifecycle_state <> 'TERMINATED';
  EOQ

  param "id" {}
}
