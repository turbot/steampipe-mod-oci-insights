query "oci_ons_subscription_count" {
  sql = <<-EOQ
    select count(*) as "Subscriptions" from oci_ons_subscription
  EOQ
}

query "oci_ons_subscription_unused_count" {
  sql = <<-EOQ
    select 
      count(*) as value,
      'Unused Subscriptions' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from 
      oci_ons_subscription
    where
      lifecycle_state <> 'ACTIVE'          
  EOQ
}

query "oci_ons_subscription_by_region" {
  sql = <<-EOQ
    select 
    region as "Region", 
    count(*) as "Subscriptions" 
    from 
      oci_ons_subscription 
    group by 
      region 
    order by 
      region
  EOQ
}

query "oci_ons_subscription_by_compartment" {
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
      count(t.*) as "Subscriptions" 
    from 
      oci_ons_subscription as t,
      compartments as c 
    where 
      c.id = t.compartment_id
    group by 
      compartment
    order by 
      compartment
  EOQ
}

query "oci_ons_subscription_by_lifecycle_state" {
  sql = <<-EOQ
    select
      lifecycle_state,
      count(lifecycle_state)
    from
      oci_ons_subscription     
    group by
      lifecycle_state
  EOQ
}

query "oci_ons_subscription_by_creation_month" {
  sql = <<-EOQ
    with subscriptions as (
      select
        id,
        created_time,
        to_char(created_time,
          'YYYY-MM') as creation_month
      from
        oci_ons_subscription    
    ),
    months as (
      select
        to_char(d,
          'YYYY-MM') as month
      from
        generate_series(date_trunc('month',
            (
              select
                min(created_time)
                from subscriptions)),
            date_trunc('month',
              current_date),
            interval '1 month') as d
    ),
    subscriptions_by_month as (
      select
        creation_month,
        count(*)
      from
        subscriptions
      group by
        creation_month
    )
    select
      months.month,
      subscriptions_by_month.count
    from
      months
      left join subscriptions_by_month on months.month = subscriptions_by_month.creation_month
    order by
      months.month;
  EOQ
}

dashboard "oci_ons_subscription_dashboard" {

  title = "OCI ONS Subscription Dashboard"

  container {
    card {
      sql = query.oci_ons_subscription_count.sql
      width = 2
    }

    card {
      sql = query.oci_ons_subscription_unused_count.sql
      width = 2
    }
  }

  container {
      title = "Analysis"      

    chart {
      title = "Subscriptions by Compartment"
      sql = query.oci_ons_subscription_by_compartment.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Subscriptions by Region"
      sql = query.oci_ons_subscription_by_region.sql
      type  = "column"
      width = 3
    }
  }

  container {
      title = "Assessments"

      chart {
        title = "Lifecycle State"
        sql = query.oci_ons_subscription_by_lifecycle_state.sql
        type  = "donut"
        width = 3
      }

    }

  container {
    title = "Resources by Age" 

    chart {
      title = "Subscriptions by Creation Month"
      sql = query.oci_ons_subscription_by_creation_month.sql
      type  = "column"
      width = 4
      series "month" {
        color = "green"
      }
    }

    table {
      title = "Oldest Subscriptions"
      width = 4

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
          t.title as "Subscriptions",
          current_date - t.created_time::date as "Age in Days",
          c.title as "Compartment"
        from
          oci_ons_subscription as t
          left join compartments as c on c.id = t.compartment_id   
        order by
          "Age in Days" desc,
          t.title
        limit 5
      EOQ
    }

    table {
      title = "Newest Subscriptions"
      width = 4

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
          t.title as "Subscriptions",
          current_date - t.created_time::date as "Age in Days",
          c.title as "Compartment"
        from
          oci_ons_subscription as t
          left join compartments as c on c.id = t.compartment_id  
        order by
          "Age in Days" asc,
          t.title
        limit 5
      EOQ
    }

  }

}