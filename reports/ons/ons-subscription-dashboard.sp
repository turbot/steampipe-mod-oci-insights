query "oci_ons_subscription_count" {
  sql = <<-EOQ
    select count(*) as "Subscriptions" from oci_ons_subscription
  EOQ
}

query "oci_ons_subscription_unused_count" {
  sql = <<-EOQ
    select 
      count(*) as value,
      'Unused' as label,
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
    select 
      c.title as "Compartment",
      count(t.*) as "Topics" 
    from 
      oci_ons_subscription as t,
      oci_identity_compartment as c 
    where 
      c.id = t.compartment_id
    group by 
      c.title
    order by 
      c.title
  EOQ
}

query "oci_ons_subscription_by_tenancy" {
  sql = <<-EOQ
    select 
      c.title as "Tenancy",
      count(t.*) as "Topics" 
    from 
      oci_ons_subscription as t,
      oci_identity_tenancy as c 
    where 
      c.id = t.compartment_id
    group by 
      c.title
    order by 
      c.title
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
      title = "Assessments"

      chart {
        title = "Lifecycle State"
        sql = query.oci_ons_subscription_by_lifecycle_state.sql
        type  = "donut"
        width = 3
      }

    }

  container {
      title = "Analysis"  

    chart {
      title = "Subscriptions by Tenancy"
      sql = query.oci_ons_subscription_by_tenancy.sql
      type  = "column"
      width = 3
    }    

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

    chart {
      title = "Subscriptions by Age"
      sql = query.oci_ons_subscription_by_creation_month.sql
      type  = "column"
      width = 3
    }

  }

}