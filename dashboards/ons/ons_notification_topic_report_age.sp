dashboard "oci_ons_notification_topic_age_report" {

  title = "OCI ONS Notification Topic Age Report"


  container {

    # Analysis
    card {
      sql   = query.oci_ons_notification_topic_count.sql
      width = 2
    }

    card {
      sql   = <<-EOQ
        select
          count(*) as value,
          '< 24 hours' as label
        from
          oci_ons_notification_topic
        where
          time_created > now() - '1 days' :: interval
      EOQ
      width = 2
      type  = "info"
    }

    card {
      sql   = <<-EOQ
        select
          count(*) as value,
          '1-30 Days' as label
        from
          oci_ons_notification_topic
        where
          time_created between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval
      EOQ
      width = 2
      type  = "info"
    }

    card {
      sql   = <<-EOQ
        select
          count(*) as value,
          '30-90 Days' as label
        from
          oci_ons_notification_topic
        where
          time_created between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval
      EOQ
      width = 2
      type  = "info"
    }

    card {
      sql   = <<-EOQ
        select
          count(*) as value,
          '90-365 Days' as label
        from
          oci_ons_notification_topic
        where
          time_created between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval)
      EOQ
      width = 2
      type  = "info"
    }

    card {
      sql   = <<-EOQ
        select
          count(*) as value,
          '> 1 Year' as label
        from
          oci_ons_notification_topic
        where
          time_created <= now() - '1 year' :: interval
      EOQ
      width = 2
      type  = "info"
    }

  }

  container {


    table {

      sql = <<-EOQ
        select
          v.name as "Name",
          now()::date - v.time_created::date as "Age in Days",
          v.time_created as "Create Time",
          v.lifecycle_state as "Lifecycle State",
          coalesce(c.title, 'root') as "Compartment",
          t.title as "Tenancy",
          v.region as "Region",
          v.topic_id as "OCID" 
        from
          oci_ons_notification_topic as v
          left join oci_identity_compartment as c on v.compartment_id = c.id
          left join oci_identity_tenancy as t on v.tenant_id = t.id
        order by
          v.time_created,
          v.title
      EOQ
    }


  }

}
