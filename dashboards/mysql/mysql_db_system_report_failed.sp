dashboard "oci_mysql_db_system_failed_report" {

  title = "OCI MySQL DB System Failed Report"

  tags = merge(local.mysql_common_tags, {
    type = "Report"
  })

  container {

    card {
      sql   = query.oci_mysql_db_system_count.sql
      width = 2
    }

    card {
      sql   = query.oci_mysql_db_system_failed_lifecycle_count.sql
      width = 2
    }
  }

  table {
    sql = query.oci_mysql_db_system_failed_table.sql
  }

}

query "oci_mysql_db_system_failed_table" {
  sql = <<-EOQ
      select
        s.display_name as "Name",
        s.lifecycle_state as "Lifecycle State",
        coalesce(c.title, 'root') as "Compartment",
        t.title as "Tenancy",
        s.region as "Region",
        s.id as "OCID"
      from
        oci_mysql_db_system as s
        left join oci_identity_compartment as c on s.compartment_id = c.id
        left join oci_identity_tenancy as t on s.tenant_id = t.id
      where
        s.lifecycle_state <> 'DELETED'
      order by
        s.time_created,
        s.title;
  EOQ
}
