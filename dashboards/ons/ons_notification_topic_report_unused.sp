dashboard "oci_ons_notification_topic_unused_report" {

  title         = "OCI ONS Notification Topic Unused Report"
  documentation = file("./dashboards/ons/docs/ons_notification_topic_report_unused.md")

  tags = merge(local.ons_common_tags, {
    type     = "Report"
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
    column "OCID" {
      display = "none"
    }

    sql = query.oci_ons_notification_topic_unused_table.sql
  }

}

query "oci_ons_notification_topic_unused_table" {
  sql = <<-EOQ
      select
        n.name,
        n.lifecycle_state as "Lifecycle State",
        coalesce(c.title, 'root') as "Compartment",
        t.title as "Tenancy",
        n.region as "Region",
        n.topic_id as "OCID"
      from
        oci_ons_notification_topic as n
        left join oci_identity_compartment as c on n.compartment_id = c.id
        left join oci_identity_tenancy as t on n.tenant_id = t.id
      order by
        n.name;
  EOQ
}
