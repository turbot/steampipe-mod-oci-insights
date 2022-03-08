dashboard "oci_vcn_subnet_dashboard" {

  title         = "OCI VCN Subnet Dashboard"
  documentation = file("./dashboards/vcn/docs/vcn_subnet_dashboard.md")

  tags = merge(local.vcn_common_tags, {
    type = "Dashboard"
  })

  container {

    card {
      width = 2
      sql   = query.oci_vcn_subnet_count.sql
    }

    card {
      width = 2
      sql   = query.oci_vcn_subnet_flowlog_not_configured_count.sql
    }

  }

  container {

    title = "Assessments"

    chart {
      title = "Flow Log Status"
      type  = "donut"
      width = 3
      sql   = query.oci_vcn_subnet_by_flowlog.sql

      series "count" {
        point "enabled" {
          color = "ok"
        }
        point "disabled" {
          color = "alert"
        }
      }
    }

  }

  container {
    title = "Analysis"

    chart {
      title = "Subnets by Tenancy"
      sql   = query.oci_vcn_subnet_by_tenancy.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Subnets by Compartment"
      sql   = query.oci_vcn_subnet_by_compartment.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Subnets by Region"
      sql   = query.oci_vcn_subnet_by_region.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Subnets by VCN"
      sql   = query.oci_vcn_subnet_by_vcn.sql
      type  = "column"
      width = 3
    }

  }

}

# Card Queries

query "oci_vcn_subnet_count" {
  sql = <<-EOQ
    select count(*) as "Subnets" from oci_core_subnet where lifecycle_state <> 'TERMINATED';
  EOQ
}

query "oci_vcn_subnet_flowlog_not_configured_count" {
  sql = <<-EOQ
    select
      count(s.*) as value,
      'Flow Log Disabled' as label,
      case count(s.*) when 0 then 'ok' else 'alert' end as type
    from
      oci_core_subnet as s
      left join oci_logging_log as l
      on s.id = l.configuration -> 'source' ->> 'resource'
    where
      l.is_enabled is null or not l.is_enabled and s.lifecycle_state <> 'TERMINATED';
  EOQ
}

# Assessment Queries

query "oci_vcn_subnet_by_flowlog" {
  sql = <<-EOQ
    with subnet_logs as (
      select
        s.id as subnet_id,
        case
          when l.is_enabled is null or not l.is_enabled then 'disabled'
          else 'enabled'
        end as flow_logs_configured
      from
        oci_core_subnet as s
        left join oci_logging_log as l
        on s.id = l.configuration -> 'source' ->> 'resource'
      where
        s.lifecycle_state <> 'TERMINATED'
    )
    select
      flow_logs_configured,
      count(distinct subnet_id)
    from
      subnet_logs
    group by
      flow_logs_configured;
  EOQ
}

# Analysis Queries

query "oci_vcn_subnet_by_tenancy" {
  sql = <<-EOQ
    select
      c.title as "Tenancy",
      count(s.*) as "Subnets"
    from
      oci_core_subnet as s,
      oci_identity_tenancy as c
    where
      c.id = s.tenant_id and s.lifecycle_state <> 'TERMINATED'
    group by
      c.title
    order by
      c.title;
  EOQ
}

query "oci_vcn_subnet_by_compartment" {
  sql = <<-EOQ
    with compartments as (
      select
        id, title
      from
        oci_identity_tenancy
      union (
      select
        id,title
      from
        oci_identity_compartment
      where
        lifecycle_state = 'ACTIVE'
        )
       )
    select
      t.title as "Tenancy",
      case when t.title = c.title then 'root' else c.title end as "Compartment",
      count(s.*) as "Subnets"
    from
      oci_core_subnet as s,
      oci_identity_tenancy as t,
      compartments as c
    where
      c.id = s.compartment_id and s.tenant_id = t.id and s.lifecycle_state <> 'DELETED'
    group by
      t.title,
      c.title
    order by
      t.title,
      c.title;
  EOQ
}

query "oci_vcn_subnet_by_region" {
  sql = <<-EOQ
    select
      region as "Region",
      count(*) as "Subnets"
    from
      oci_core_subnet
    where
      lifecycle_state <> 'TERMINATED'
    group by
      region
    order by
      region;
  EOQ
}

query "oci_vcn_subnet_by_vcn" {
  sql = <<-EOQ
    select
      v.display_name as "VCN",
      count(*) as "subnets"
    from
      oci_core_subnet s
      left join oci_core_vcn v on s.vcn_id = v.id
    where
      s.lifecycle_state <> 'TERMINATED'
      group by v.display_name
      order by v.display_name;
  EOQ
}
