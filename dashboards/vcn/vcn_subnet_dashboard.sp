dashboard "oci_vcn_subnet_dashboard" {

  title         = "OCI VCN Subnet Dashboard"
  documentation = file("./dashboards/vcn/docs/vcn_subnet_dashboard.md")

  tags = merge(local.vcn_common_tags, {
    type = "Dashboard"
  })

  container {

    card {
      width = 3
      query = query.oci_vcn_subnet_count
    }

    card {
      width = 3
      query = query.oci_vcn_subnet_flow_logs_not_configured_count
      href  = dashboard.oci_vcn_subnet_flow_logs_report.url_path
    }

  }

  container {

    title = "Assessments"

    chart {
      title = "Flow Logs Status"
      type  = "donut"
      width = 3
      query = query.oci_vcn_subnet_by_flow_logs

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
      query = query.oci_vcn_subnet_by_tenancy
      type  = "column"
      width = 3
    }

    chart {
      title = "Subnets by Compartment"
      query = query.oci_vcn_subnet_by_compartment
      type  = "column"
      width = 3
    }

    chart {
      title = "Subnets by Region"
      query = query.oci_vcn_subnet_by_region
      type  = "column"
      width = 3
    }

    chart {
      title = "Subnets by VCN"
      query = query.oci_vcn_subnet_by_vcn
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

query "oci_vcn_subnet_flow_logs_not_configured_count" {
  sql = <<-EOQ
    select
      count(s.*) as value,
      'Flow Logs Disabled' as label,
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

query "oci_vcn_subnet_by_flow_logs" {
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
        id,
        'root [' || title || ']' as title
      from
        oci_identity_tenancy
      union (
      select
        c.id,
        c.title || ' [' || t.title || ']' as title
      from
        oci_identity_compartment c,
        oci_identity_tenancy t
      where
        c.tenant_id = t.id and c.lifecycle_state = 'ACTIVE'
      )
    )
    select
      c.title as "Title",
      count(s.*) as "Subnets"
    from
      oci_core_subnet as s,
      compartments as c
    where
      c.id = s.compartment_id and s.lifecycle_state <> 'DELETED'
    group by
      c.title
    order by
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
