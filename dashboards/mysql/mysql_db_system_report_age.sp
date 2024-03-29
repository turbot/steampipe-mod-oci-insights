dashboard "mysql_db_system_age_report" {

  title         = "OCI MySQL DB System Age Report"
  documentation = file("./dashboards/mysql/docs/mysql_db_system_report_age.md")

  tags = merge(local.mysql_common_tags, {
    type     = "Report"
    category = "Age"
  })

  container {

    card {
      query = query.mysql_db_system_count
      width = 2
    }

    card {
      query = query.mysql_db_system_24_hrs
      width = 2
      type  = "info"
    }

    card {
      query = query.mysql_db_system_30_days
      width = 2
      type  = "info"
    }

    card {
      query = query.mysql_db_system_90_days
      width = 2
      type  = "info"
    }

    card {
      query = query.mysql_db_system_365_days
      width = 2
      type  = "info"
    }

    card {
      query = query.mysql_db_system_1_year
      width = 2
      type  = "info"
    }

  }
  table {
    column "OCID" {
      display = "none"
    }

    column "Name" {
      href = "${dashboard.mysql_db_system_detail.url_path}?input.db_system_id={{.OCID | @uri}}"
    }

    query = query.mysql_db_system_age_report
  }

}

query "mysql_db_system_24_hrs" {
  sql = <<-EOQ
    select
      count(*) as value,
      '< 24 hours' as label
    from
      oci_mysql_db_system
    where
      lifecycle_state <> 'DELETED' and time_created > now() - '1 days' :: interval;
  EOQ
}

query "mysql_db_system_30_days" {
  sql = <<-EOQ
    select
      count(*) as value,
      '1-30 Days' as label
    from
      oci_mysql_db_system
    where
      lifecycle_state <> 'DELETED' and time_created between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval;
  EOQ
}

query "mysql_db_system_90_days" {
  sql = <<-EOQ
    select
      count(*) as value,
      '30-90 Days' as label
    from
      oci_mysql_db_system
    where
      lifecycle_state <> 'DELETED' and time_created between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval;
  EOQ
}

query "mysql_db_system_365_days" {
  sql = <<-EOQ
    select
      count(*) as value,
      '90-365 Days' as label
    from
      oci_mysql_db_system
    where
      lifecycle_state <> 'DELETED' and time_created between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval);
  EOQ
}

query "mysql_db_system_1_year" {
  sql = <<-EOQ
    select
      count(*) as value,
      '> 1 Year' as label
    from
      oci_mysql_db_system
    where
      lifecycle_state <> 'DELETED' and time_created <= now() - '1 year' :: interval;
  EOQ
}

query "mysql_db_system_age_report" {
  sql = <<-EOQ
    select
      s.display_name as "Name",
      s.id as "OCID",
      now()::date - s.time_created::date as "Age in Days",
      s.time_created as "Create Time",
      s.lifecycle_state as "Lifecycle State",
      t.title as "Tenancy",
      coalesce(c.title, 'root') as "Compartment",
      s.region as "Region"
    from
      oci_mysql_db_system as s
      left join oci_identity_compartment as c on s.compartment_id = c.id
      left join oci_identity_tenancy as t on s.tenant_id = t.id
    where
      s.lifecycle_state <> 'DELETED'
    order by
      s.time_created,
      s.display_name;
  EOQ
}
