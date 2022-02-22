query "vcn_subnets_by_compartment" {
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
      c.title as "compartment",
      count(s.*) as "Security Lists" 
    from 
      oci_core_subnet as s,
      compartments as c 
    where 
      c.id = s.compartment_id
    group by 
      compartment
    order by 
      compartment
  EOQ
}

query "vcn_subnets_by_region" {
  sql = <<-EOQ
    select
      region as "Region",
      count(*) as "Security Lists" 
    from 
      oci_core_subnet 
    group by 
      region 
    order by 
      region
  EOQ
}

query "oci_subnet_by_creation_month" {
  sql = <<-EOQ
    with databases as (
      select
        title,
        time_created,
        to_char(time_created,
          'YYYY-MM') as creation_month
      from
        oci_core_subnet
    ),
    months as (
      select
        to_char(d,
          'YYYY-MM') as month
      from
        generate_series(date_trunc('month',
            (
              select
                min(time_created)
                from databases)),
            date_trunc('month',
              current_date),
            interval '1 month') as d
    ),
    databases_by_month as (
      select
        creation_month,
        count(*)
      from
        databases
      group by
        creation_month
    )
    select
      months.month,
      databases_by_month.count
    from
      months
      left join databases_by_month on months.month = databases_by_month.creation_month
    order by
      months.month desc;
  EOQ
}

dashboard "vcn_subnet_dashboard" {

  title = "OCI VCN Subnet Dashboard"

  # input {
  #   title = "Subnet List"
  #   type = "select"
  #   sql = <<-EOQ
  #     select
  #       display_name as label,
  #       id as value
  #     from
  #       oci_core_subnet
  #   EOQ
  #   width = 3
  # }

  container {

    card {
      width = 2
      sql = <<-EOQ
        select count(*) as "Subnets" from oci_core_subnet
      EOQ
    }
    
  }

  container {

    title = "Analysis"      

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
        group by v.display_name
        order by v.display_name;
      EOQ
      type  = "column"
      width = 3
    }
  }

  container {
    
    title = "Resources by Age"

    chart {
      title = "Subnets by Creation Month"
      sql   = query.oci_subnet_by_creation_month.sql
      type  = "column"
      width = 3

      series "month" {
        color = "green"
      }
    }
  }

}