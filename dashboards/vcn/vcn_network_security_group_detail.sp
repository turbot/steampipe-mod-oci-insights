dashboard "oci_vcn_network_security_group_detail" {

  title = "OCI VCN Network Security Group Detail"

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

      query = query.oci_vcn_network_security_group_name_for_security_group
      args = {
        id = self.input.security_group_id.value
      }
    }

    card {
      width = 2

      query = query.oci_vcn_network_security_group_ingress_ssh_for_security_group
      args = {
        id = self.input.security_group_id.value
      }
    }

    card {
      width = 2

      query = query.oci_vcn_network_security_group_ingress_rdp_for_security_group
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

        args = {
          id = self.input.security_group_id.value
        }

      }

      table {
        title = "Tags"
        width = 6

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

        args = {
          id = self.input.security_group_id.value
        }

      }

    }

    container {
      width = 6

      table {
        title = "Ingress Rules"
        sql   = <<-EOQ
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

        args = {
          id = self.input.security_group_id.value
        }
      }

      table {
        title = "Egress Rules"
        sql   = <<-EOQ
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
      id as label,
      id as value
    from
      oci_core_network_security_group
    where
      lifecycle_state <> 'TERMINATED'
    order by
      id;
  EOQ
}

query "oci_vcn_network_security_group_name_for_security_group" {
  sql = <<-EOQ
    select
      display_name as "Security Group"
    from
      oci_core_network_security_group
    where
      id = $1 and lifecycle_state <> 'TERMINATED';
  EOQ

  param "id" {}
}

query "oci_vcn_network_security_group_ingress_ssh_for_security_group" {
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
        case when non_compliant_rules.id is null then 'RESTRICTED' else 'UNRESTRICTED' end as value,
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

query "oci_vcn_network_security_group_ingress_rdp_for_security_group" {
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
        case when non_compliant_rules.id is null then 'RESTRICTED' else 'UNRESTRICTED' end as value,
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
