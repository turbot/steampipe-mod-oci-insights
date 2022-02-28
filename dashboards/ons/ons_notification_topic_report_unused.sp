dashboard "oci_ons_notification_topic_unused_report" {

  title = "OCI ONS Notification Topic Unused Report"

  tags = merge(local.ons_common_tags, {
    type = "Report"
    category = "Unused"
  })

  container {

    card {
      sql   = query.oci_ons_notification_topic_count.sql
      width = 2
    }

    card {
      sql   = query.oci_ons_notification_topic_unused_count.sql
      width = 2
    }
  }

  table {
    sql = <<-EOQ
      select
        a.name,
        now()::date - a.time_created::date as "Age in Days",
        a.time_created as "Create Time",
        a.lifecycle_state as "Lifecycle State",
        coalesce(c.title, 'root') as "Compartment",
        t.title as "Tenancy",
        a.region as "Region",
        a.topic_id as "OCID"
      from
        oci_ons_notification_topic as a
        left join oci_identity_compartment as c on a.compartment_id = c.id
        left join oci_identity_tenancy as t on a.tenant_id = t.id
      order by
        a.time_created,
        a.title;
    EOQ
  }

}
