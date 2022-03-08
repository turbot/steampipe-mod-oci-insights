dashboard "oci_vcn_subnet_detail" {

  title = "OCI VCN Subnet Detail"
  documentation = file("./dashboards/vcn/docs/vcn_subnet_detail.md")

  tags = merge(local.vcn_common_tags, {
    type = "Detail"
  })

  input "subnet_id" {
    title = "Select a subnet:"
    sql   = query.oci_vcn_subnet_input.sql
    width = 4
  }

  container {

    card {
      width = 2
      query = query.oci_vcn_subnet_flow_logs
      args = {
        id = self.input.subnet_id.value
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
        query = query.oci_vcn_subnet_overview
        args = {
          id = self.input.subnet_id.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.oci_vcn_subnet_tag
        args = {
          id = self.input.subnet_id.value
        }

      }
    }

    container {
      width = 6

      table {
        title = "CIDR Block"
        query = query.oci_vcn_subnet_cidr_block
        args = {
          id = self.input.subnet_id.value
        }
      }

    }

  }
}

query "oci_vcn_subnet_input" {
  sql = <<EOQ
    select
      s.display_name as label,
      s.id as value,
      json_build_object(
        'c.name', coalesce(c.title, 'root'),
        's.region', region,
        't.name', t.name
      ) as tags
    from
      oci_core_subnet as s
      left join oci_identity_compartment as c on s.compartment_id = c.id
      left join oci_identity_tenancy as t on s.tenant_id = t.id
    where
      s.lifecycle_state <> 'TERMINATED'
    order by
      s.display_name;
EOQ
}

query "oci_vcn_subnet_overview" {
  sql = <<-EOQ
    select
      display_name as "Name",
      time_created as "Time Created",
      subnet_domain_name as "Subnet Domain Name",
      region as "Region",
      id as "OCID",
      compartment_id as "Compartment ID"
    from
      oci_core_subnet
    where
      id = $1 and lifecycle_state <> 'TERMINATED';
  EOQ

  param "id" {}
}

query "oci_vcn_subnet_tag" {
  sql = <<-EOQ
    with jsondata as (
      select
        tags::json as tags
      from
        oci_core_subnet
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

query "oci_vcn_subnet_flow_logs" {
  sql = <<-EOQ
    select
      case when is_enabled then 'Enabled' else 'Disabled' end as value,
      'Flow Logs' as label,
      case when is_enabled then 'ok' else 'alert' end as type
    from
      oci_core_subnet as s
      left join oci_logging_log as l
      on s.id = l.configuration -> 'source' ->> 'resource'
    where
      s.id = $1 and s.lifecycle_state <> 'TERMINATED';
  EOQ

  param "id" {}
}

query "oci_vcn_subnet_cidr_block" {
  sql = <<-EOQ
    select
      cidr_block as "IPv4 CIDR Block",
      ipv6_cidr_block as "IPv6 CIDR Block"
    from
      oci_core_subnet
    where
      id  = $1 and lifecycle_state <> 'TERMINATED';
  EOQ

  param "id" {}
}
