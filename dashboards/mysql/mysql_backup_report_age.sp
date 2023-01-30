dashboard "mysql_backup_age_report" {

  title         = "OCI MySQL Backup Age Report"
  documentation = file("./dashboards/mysql/docs/mysql_backup_report_age.md")

  tags = merge(local.mysql_common_tags, {
    type     = "Report"
    category = "Age"
  })

  container {

    card {
      query = query.mysql_backup_count
      width = 2
    }

    card {
      query = query.mysql_backup_24_hrs
      width = 2
      type  = "info"
    }

    card {
      query = query.mysql_backup_30_days
      width = 2
      type  = "info"
    }

    card {
      query = query.mysql_backup_90_days
      width = 2
      type  = "info"
    }

    card {
      query = query.mysql_backup_365_days
      width = 2
      type  = "info"
    }

    card {
      query = query.mysql_backup_1_year
      width = 2
      type  = "info"
    }

  }

  table {
    column "OCID" {
      display = "none"
    }

    query = query.mysql_backup_age_report
  }

}

query "mysql_backup_24_hrs" {
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

query "mysql_backup_30_days" {
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

query "mysql_backup_90_days" {
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

query "mysql_backup_365_days" {
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

query "mysql_backup_1_year" {
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

query "mysql_backup_age_report" {
  sql = <<-EOQ
    select
      b.display_name as "Name",
      now()::date - b.time_created::date as "Age in Days",
      b.time_created as "Create Time",
      b.lifecycle_state as "Lifecycle State",
      t.title as "Tenancy",
      coalesce(c.title, 'root') as "Compartment",
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
