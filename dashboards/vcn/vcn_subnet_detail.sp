dashboard "oci_vcn_subnet_detail" {

  title = "OCI VCN Subnet Detail"

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
      query = query.oci_vcn_subnet_name
      args = {
        id = self.input.subnet_id.value
      }
    }

    card {
      width = 2
      query = query.oci_vcn_subnet_flow_log
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

        args = {
          id = self.input.subnet_id.value
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

        args = {
          id = self.input.subnet_id.value
        }

      }
    }

    container {
      width = 6

      table {
        title = "IPv4 CIDR Block"
        sql   = <<-EOQ
          select
            display_name as "Name",
            time_created as "Time Created",
            cidr_block as "CIDR Block"
          from
            oci_core_subnet
          where
           id  = $1 and lifecycle_state <> 'TERMINATED';
        EOQ

        param "id" {}

        args = {
          id = self.input.subnet_id.value
        }
      }

      table {
        title = "IPv6 CIDR Block"
        sql   = <<-EOQ
          select
            display_name as "Name",
            time_created as "Time Created",
            ipv6_cidr_block as "IPv6 CIDR Block"
          from
            oci_core_subnet
          where
           id  = $1 and lifecycle_state <> 'TERMINATED';
        EOQ

        param "id" {}

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
      id as label,
      id as value
    from
      oci_core_subnet
    where
      lifecycle_state <> 'TERMINATED'
    order by
      id;
EOQ
}

query "oci_vcn_subnet_name" {
  sql = <<-EOQ
    select
      display_name as "Subnet"
    from
      oci_core_subnet
    where
      id = $1 and lifecycle_state <> 'TERMINATED';
  EOQ

  param "id" {}
}

query "oci_vcn_subnet_flow_log" {
  sql = <<-EOQ
    select
      case when is_enabled then 'ENABLED' else 'DISABLED' end as value,
      'Flow Log' as label,
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
