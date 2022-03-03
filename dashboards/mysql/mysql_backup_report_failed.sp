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
        v.display_name as "Name",
        now()::date - v.time_created::date as "Age in Days",
        v.time_created as "Create Time",
        v.lifecycle_state as "Lifecycle State",
        coalesce(a.title, 'root') as "Compartment",
        t.title as "Tenancy",
        v.region as "Region",
        v.id as "OCID"
      from
        oci_mysql_backup as v
        left join oci_identity_compartment as a on v.compartment_id = a.id
        left join oci_identity_tenancy as t on v.tenant_id = t.id
      where
        v.lifecycle_state = 'FAILED'
      order by
        v.time_created,
        v.title;
  EOQ
}
