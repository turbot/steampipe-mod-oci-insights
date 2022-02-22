query "vcn_subnets_by_compartment" {
  sql = <<-EOQ
    select 
      c.title as "Compartment",
      count(s.*) as "Subnets" 
    from 
      oci_core_subnet as s,
      oci_identity_compartment as c 
    where 
      c.id = s.compartment_id and s.lifecycle_state <> 'TERMINATED'
    group by 
      c.title
    order by 
      c.title
  EOQ
}

query "vcn_subnet_flowlog_not_configured_count" {
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
        l.is_enabled is null or not l.is_enabled and s.lifecycle_state <> 'TERMINATED'
  EOQ
}

query "vcn_subnets_by_tenancy" {
  sql = <<-EOQ
    select 
      c.title as "Tenancy",
      count(s.*) as "Subnets" 
    from 
      oci_core_subnet as s,
      oci_identity_tenancy as c 
    where 
      c.id = s.compartment_id and s.lifecycle_state <> 'TERMINATED'
    group by 
      c.title
    order by 
      c.title
  EOQ
}

query "vcn_subnets_by_region" {
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
      region
  EOQ
}

dashboard "vcn_subnet_dashboard" {

  title = "OCI VCN Subnet Dashboard"

  container {

    card {
      width = 2
      sql = <<-EOQ
        select count(*) as "Subnets" from oci_core_subnet where lifecycle_state <> 'TERMINATED'
      EOQ
    }

    card {
      width = 2
      sql = query.vcn_subnet_flowlog_not_configured_count.sql
    }
    
  }
  
  container {
    title = "Assessments"
    
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
          flow_logs_configured
      EOQ
    }

  }  
  container {

    title = "Analysis"  

    chart {
      title = "Subnets by Tenancy"
      sql = query.vcn_subnets_by_tenancy.sql
      type  = "column"
      width = 3
    }    

    chart {
      title = "Subnets by Compartment"
      sql = query.vcn_subnets_by_compartment.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Subnets by Region"
      sql = query.vcn_subnets_by_region.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Subnets by VCN"
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
      type  = "column"
      width = 3
    }
  }
}