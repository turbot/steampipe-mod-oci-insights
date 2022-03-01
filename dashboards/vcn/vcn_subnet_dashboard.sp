query "oci_vcn_subnet_count" {
  sql = <<-EOQ
    select count(*) as "Subnets" from oci_core_vcn where lifecycle_state <> 'TERMINATED';
  EOQ
}

query "oci_vcn_subnet_flowlog_not_configured_count" {
  sql = <<-EOQ
    select
      count(s.*) as value,
      'Flow Log Not Configured' as label,
      case count(s.*) when 0 then 'ok' else 'alert' end as type
    from
      oci_core_subnet as s
      left join oci_logging_log as l
      on s.id = l.configuration -> 'source' ->> 'resource'
    where
      l.is_enabled is null or not l.is_enabled and s.lifecycle_state <> 'TERMINATED';
  EOQ
}

# Analysis

query "oci_vcn_subnets_by_tenancy" {
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

query "oci_vcn_subnets_by_compartment" {
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
      b.title as "Tenancy",
      case when b.title = c.title then 'root' else c.title end as "Compartment",
      count(a.*) as "Subnets"
    from
      oci_core_subnet as a,
      oci_identity_tenancy as b,
      compartments as c
    where
      c.id = a.compartment_id and a.tenant_id = b.id and a.lifecycle_state <> 'DELETED'
    group by
      b.title,
      c.title
    order by
      b.title,
      c.title;
  EOQ
}

query "oci_vcn_subnets_by_region" {
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

dashboard "oci_vcn_subnet_dashboard" {

  title = "OCI VCN Subnet Dashboard"

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
    width = 6

    chart {
      title = "Subnet Flow Log Status"
      type  = "donut"
      width = 3
      sql   = <<-EOQ
        with subnet_logs as (
          select
           s.id,
           case
             when l.is_enabled is null or not l.is_enabled then 'Not Configured'
             else 'Configured'
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
          count(*)
        from
          subnet_logs
        group by
          flow_logs_configured;
      EOQ
    }

  }

  container {
    title = "Analysis"

    chart {
      title = "Subnets by Tenancy"
      sql   = query.oci_vcn_subnets_by_tenancy.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Subnets by Compartment"
      sql   = query.oci_vcn_subnets_by_compartment.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Subnets by Region"
      sql   = query.oci_vcn_subnets_by_region.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Subnets by VCN"
      sql   = <<-EOQ
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
      type  = "column"
      width = 3
    }
  }
}
