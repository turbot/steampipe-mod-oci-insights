dashboard "oci_vcn_security_list_detail" {

  title = "OCI VCN Security List Detail"
  documentation = file("./dashboards/vcn/docs/vcn_security_list_detail.md")

  tags = merge(local.vcn_common_tags, {
    type = "Detail"
  })

  input "security_list_id" {
    title = "Select a security list:"
    sql   = query.oci_vcn_security_list_input.sql
    width = 4
  }

  container {

    card {
      width = 2

      query = query.oci_vcn_security_list_ingress_ssh
      args = {
        id = self.input.security_list_id.value
      }
    }

    card {
      width = 2

      query = query.oci_vcn_security_list_ingress_rdp
      args = {
        id = self.input.security_list_id.value
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
        query = query.oci_vcn_security_list_overview
        args = {
          id = self.input.security_list_id.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.oci_vcn_security_list_tag
        args = {
          id = self.input.security_list_id.value
        }

      }

    }

    container {

      width = 6

      table {
        title = "Ingress Rules"
        query = query.oci_vcn_network_security_list_ingress_rule
        args = {
          id = self.input.security_list_id.value
        }
      }

      table {
        title = "Egress Rules"
        query = query.oci_vcn_network_security_list_egress_rule
        args = {
          id = self.input.security_list_id.value
        }
      }

    }

  }

}

query "oci_vcn_security_list_input" {
  sql = <<EOQ
    select
      l.display_name as label,
      l.id as value,
      json_build_object(
        'c.name', coalesce(c.title, 'root'),
        'l.region', region,
        't.name', t.name
      ) as tags
    from
      oci_core_security_list as l
      left join oci_identity_compartment as c on l.compartment_id = c.id
      left join oci_identity_tenancy as t on l.tenant_id = t.id
    where
      l.lifecycle_state <> 'TERMINATED'
    order by
      l.display_name;
EOQ
}

query "oci_vcn_security_list_ingress_ssh" {
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

  param "id" {}
}

query "oci_vcn_security_list_ingress_rdp" {
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

  param "id" {}
}

query "oci_vcn_security_list_overview" {
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

  param "id" {}
}

query "oci_vcn_security_list_tag" {
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

  param "id" {}
}

query "oci_vcn_network_security_list_ingress_rule" {
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

  param "id" {}
}

query "oci_vcn_network_security_list_egress_rule" {
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

  param "id" {}
}
