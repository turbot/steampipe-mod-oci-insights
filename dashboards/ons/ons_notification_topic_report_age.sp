dashboard "ons_notification_topic_age_report" {

  title         = "OCI ONS Notification Topic Age Report"
  documentation = file("./dashboards/ons/docs/ons_notification_topic_report_age.md")

  tags = merge(local.ons_common_tags, {
    type     = "Report"
    category = "Age"
  })

  container {

    card {
      query = query.ons_notification_topic_count
      width = 2
    }

    card {
      query = query.ons_notification_topic_24_hrs
      width = 2
      type  = "info"
    }

    card {
      query = query.ons_notification_topic_30_days
      width = 2
      type  = "info"
    }

    card {
      query = query.ons_notification_topic_90_days
      width = 2
      type  = "info"
    }

    card {
      query = query.ons_notification_topic_365_days
      width = 2
      type  = "info"
    }

    card {
      query = query.ons_notification_topic_1_year
      width = 2
      type  = "info"
    }

  }

  table {
    column "OCID" {
      display = "none"
    }

    column "Name" {
      href = "${dashboard.ons_notification_topic_detail.url_path}?input.topic_id={{.OCID | @uri}}"
    }

    query = query.ons_notification_topic_age_report
  }

}

query "ons_notification_topic_24_hrs" {
  sql = <<-EOQ
    select
      count(*) as value,
      '< 24 hours' as label
    from
      oci_ons_notification_topic
    where
      time_created > now() - '1 days' :: interval;
  EOQ
}

query "ons_notification_topic_30_days" {
  sql = <<-EOQ
    select
      count(*) as value,
      '1-30 Days' as label
    from
      oci_ons_notification_topic
    where
      time_created between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval;
  EOQ
}

query "ons_notification_topic_90_days" {
  sql = <<-EOQ
    select
      count(*) as value,
      '30-90 Days' as label
    from
      oci_ons_notification_topic
    where
      time_created between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval;
  EOQ
}

query "ons_notification_topic_365_days" {
  sql = <<-EOQ
    select
      count(*) as value,
      '90-365 Days' as label
    from
      oci_ons_notification_topic
    where
      time_created between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval);
  EOQ
}

query "ons_notification_topic_1_year" {
  sql = <<-EOQ
    select
      count(*) as value,
      '> 1 Year' as label
    from
      oci_ons_notification_topic
    where
      time_created <= now() - '1 year' :: interval;
  EOQ
}

query "ons_notification_topic_age_report" {
  sql = <<-EOQ
    select
      n.name as "Name",
      n.topic_id as "OCID",
      now()::date - n.time_created::date as "Age in Days",
      n.time_created as "Create Time",
      n.lifecycle_state as "Lifecycle State",
      t.title as "Tenancy",
      coalesce(c.title, 'root') as "Compartment",
      n.region as "Region"
    from
      oci_ons_notification_topic as n
      left join oci_identity_compartment as c on n.compartment_id = c.id
      left join oci_identity_tenancy as t on n.tenant_id = t.id
    order by
      n.time_created,
      n.name;
  EOQ
}
