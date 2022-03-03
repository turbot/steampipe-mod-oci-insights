dashboard "oci_mysql_backup_failed_report" {

  title = "OCI MySQL Backup Failed Report"

  tags = merge(local.mysql_common_tags, {
    type = "Report"
  })

  container {

    card {
      sql   = query.oci_mysql_backup_count.sql
      width = 2
    }

    card {
      sql   = query.oci_mysql_backup_failed_lifecycle_count.sql
      width = 2
    }

  }

  table {
    sql = query.oci_mysql_backup_failed_table.sql
  }

}

query "oci_mysql_backup_failed_table" {
  sql = <<-EOQ
      select
        b.display_name as "Name",
        b.lifecycle_state as "Lifecycle State",
        coalesce(a.title, 'root') as "Compartment",
        t.title as "Tenancy",
        b.region as "Region",
        b.id as "OCID"
      from
        oci_mysql_backup as b
        left join oci_identity_compartment as a on b.compartment_id = a.id
        left join oci_identity_tenancy as t on b.tenant_id = t.id
      where
        b.lifecycle_state <> 'DELETED'
      order by
        b.display_name;
  EOQ
}
