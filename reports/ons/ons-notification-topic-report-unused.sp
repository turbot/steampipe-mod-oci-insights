dashboard "oci_ons_notification_topic_unused_report" {

  title = "OCI ONS Notification Topic Unused Report"

  container {

    card {
      sql = query.oci_ons_notification_topic_unused_count.sql
      width = 2
    }
  }

  table {
    sql = <<-EOQ
      select
        v.id as "Subscription Id",
        now()::date - v.created_time::date as "Age in Days",
        v.created_time as "Create Time",
        v.lifecycle_state as "Lifecycle State",
        coalesce(c.title, 'root') as "Compartment",
        t.title as "Tenancy",
        v.region as "Region" 
      from
        oci_ons_notification_topic as v
        left join oci_identity_compartment as c on v.compartment_id = c.id
        left join oci_identity_tenancy as t on v.tenant_id = t.id
      order by
        v.created_time,
        v.title
    EOQ
  }

}