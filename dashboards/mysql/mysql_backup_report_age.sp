dashboard "oci_mysql_backup_age_report" {

  title = "OCI MySQL Backup Age Report"

  tags = merge(local.mysql_common_tags, {
    type     = "Report"
    category = "Age"
  })

  container {

    card {
      sql   = query.oci_mysql_backup_count.sql
      width = 2
    }

    card {
      sql   = query.oci_mysql_backup_24_hrs.sql
      width = 2
      type  = "info"
    }

    card {
      sql   = query.oci_mysql_backup_30_days.sql
      width = 2
      type  = "info"
    }

    card {
      sql   = query.oci_mysql_backup_90_days.sql
      width = 2
      type  = "info"
    }

    card {
      sql   = query.oci_mysql_backup_365_days.sql
      width = 2
      type  = "info"
    }

    card {
      sql   = query.oci_mysql_backup_1_year.sql
      width = 2
      type  = "info"
    }

  }

  container {


    table {

      sql = query.oci_mysql_backup_age_table.sql
    }


  }

}

query "oci_mysql_backup_24_hrs" {
  sql = <<-EOQ
    select
      count(*) as value,
      '< 24 hours' as label
    from
      oci_mysql_backup
    where
      lifecycle_state <> 'DELETED' and time_created > now() - '1 days' :: interval;
  EOQ
}

query "oci_mysql_backup_30_days" {
  sql = <<-EOQ
    select
      count(*) as value,
      '1-30 Days' as label
    from
      oci_mysql_backup
    where
      lifecycle_state <> 'DELETED' and time_created between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval;
  EOQ
}

query "oci_mysql_backup_90_days" {
  sql = <<-EOQ
    select
      count(*) as value,
      '30-90 Days' as label
    from
      oci_mysql_backup
    where
      lifecycle_state <> 'DELETED' and time_created between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval;
  EOQ
}

query "oci_mysql_backup_365_days" {
  sql = <<-EOQ
    select
      count(*) as value,
      '90-365 Days' as label
    from
      oci_mysql_backup
    where
      lifecycle_state <> 'DELETED' and time_created between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval);
  EOQ
}

query "oci_mysql_backup_1_year" {
  sql = <<-EOQ
    select
      count(*) as value,
      '> 1 Year' as label
    from
      oci_mysql_backup
    where
      lifecycle_state <> 'DELETED' and time_created <= now() - '1 year' :: interval;
  EOQ
}

query "oci_mysql_backup_age_table" {
  sql = <<-EOQ
    select
      b.display_name as "Name",
      now()::date - b.time_created::date as "Age in Days",
      b.time_created as "Create Time",
      b.lifecycle_state as "Lifecycle State",
      coalesce(c.title, 'root') as "Compartment",
      t.title as "Tenancy",
      b.region as "Region",
      b.id as "OCID"
    from
      oci_mysql_backup as b
      left join oci_identity_compartment as c on b.compartment_id = c.id
      left join oci_identity_tenancy as t on b.tenant_id = t.id
    where
      b.lifecycle_state <> 'DELETED'
    order by
      b.display_name;
  EOQ
}
