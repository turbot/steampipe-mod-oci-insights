dashboard "oci_ons_subscription_unused_report" {

  title = "OCI ONS Subscription Unused Report"

  tags = merge(local.ons_common_tags, {
    type     = "Report"
    category = "Unused"
  })

  container {

    card {
      sql   = query.oci_ons_subscription_count.sql
      width = 2
    }

    card {
      sql   = query.oci_ons_subscription_unused_count.sql
      width = 2
    }

  }

  table {
    sql = query.oci_ons_subscription_unused_table.sql
  }

}

query "oci_ons_subscription_unused_table" {
  sql = <<-EOQ
      select
        s.id as "OCID",
        s.lifecycle_state as "Lifecycle State",
        coalesce(c.title, 'root') as "Compartment",
        t.title as "Tenancy",
        s.region as "Region"
      from
        oci_ons_subscription as s
        left join oci_identity_compartment as c on s.compartment_id = c.id
        left join oci_identity_tenancy as t on s.tenant_id = t.id
      order by
        s.title;
  EOQ
}
