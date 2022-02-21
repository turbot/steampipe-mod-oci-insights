query "oci_ons_notification_topic_count" {
  sql = <<-EOQ
    select count(*) as "Topics" from oci_ons_notification_topic
  EOQ
}

query "oci_ons_notification_topic_by_region" {
  sql = <<-EOQ
    select 
    region as "Region", 
    count(*) as "Topics" 
    from 
      oci_ons_notification_topic 
    group by 
      region 
    order by 
      region
  EOQ
}

query "oci_ons_notification_topic_by_compartment" {
  sql = <<-EOQ
    select 
      c.title as "Compartment",
      count(t.*) as "Topics" 
    from 
      oci_ons_notification_topic as t,
      oci_identity_compartment as c 
    where 
      c.id = t.compartment_id
    group by 
      c.title
    order by 
      c.title
  EOQ
}

query "oci_ons_notification_topic_by_tenancy" {
  sql = <<-EOQ
    select 
      c.title as "Tenancy",
      count(t.*) as "Topics" 
    from 
      oci_ons_notification_topic as t,
      oci_identity_tenancy as c 
    where 
      c.id = t.compartment_id
    group by 
      c.title
    order by 
      c.title
  EOQ
}

query "oci_ons_notification_topic_by_lifecycle_state" {
  sql = <<-EOQ
    select
      lifecycle_state,
      count(lifecycle_state)
    from
      oci_ons_notification_topic     
    group by
      lifecycle_state
  EOQ
}

query "oci_ons_notification_topic_by_creation_month" {
  sql = <<-EOQ
    with topics as (
      select
        name,
        time_created,
        to_char(time_created,
          'YYYY-MM') as creation_month
      from
        oci_ons_notification_topic    
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
                from topics)),
            date_trunc('month',
              current_date),
            interval '1 month') as d
    ),
    topics_by_month as (
      select
        creation_month,
        count(*)
      from
        topics
      group by
        creation_month
    )
    select
      months.month,
      topics_by_month.count
    from
      months
      left join topics_by_month on months.month = topics_by_month.creation_month
    order by
      months.month;
  EOQ
}

dashboard "oci_ons_notification_topic_dashboard" {

  title = "OCI ONS Notification Topic Dashboard"

  container {
    card {
      sql = query.oci_ons_notification_topic_count.sql
      width = 2
    }
  }

  container {
      title = "Assessments"

      chart {
        title = "Lifecycle State"
        sql = query.oci_ons_notification_topic_by_lifecycle_state.sql
        type  = "donut"
        width = 3
      }

    }

  container {
      title = "Analysis"  

    chart {
      title = "Notification Topics by Tenancy"
      sql = query.oci_ons_notification_topic_by_tenancy.sql
      type  = "column"
      width = 3
    }      

    chart {
      title = "Notification Topics by Compartment"
      sql = query.oci_ons_notification_topic_by_compartment.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Notification Topics by Region"
      sql = query.oci_ons_notification_topic_by_region.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Notification Topics by Age"
      sql = query.oci_ons_notification_topic_by_creation_month.sql
      type  = "column"
      width = 3
    }
  }

}