dashboard "database_autonomous_database_age_report" {

  title         = "OCI Database Autonomous DB Age Report"
  documentation = file("./dashboards/database/docs/database_autonomous_db_report_age.md")

  tags = merge(local.database_common_tags, {
    type     = "Report"
    category = "Age"
  })

  container {

    card {
      query = query.database_autonomous_db_count
      width = 2
    }

    card {
      query = query.database_autonomous_db_24_hrs
      width = 2
      type  = "info"
    }

    card {
      query = query.database_autonomous_db_30_days
      width = 2
      type  = "info"
    }

    card {
      query = query.database_autonomous_db_90_days
      width = 2
      type  = "info"
    }

    card {
      query = query.database_autonomous_db_365_days
      width = 2
      type  = "info"
    }

    card {
      query = query.database_autonomous_db_1_year
      width = 2
      type  = "info"
    }

  }

  table {
    column "OCID" {
      display = "none"
    }

    column "Name" {
      href = "${dashboard.database_autonomous_database_detail.url_path}?input.db_id={{.OCID | @uri}}"
    }

    query = query.database_autonomous_db_age_report
  }

}

query "database_autonomous_db_24_hrs" {
  sql = <<-EOQ
    select
      count(*) as value,
      '< 24 hours' as label
    from
      oci_database_autonomous_database
    where
      lifecycle_state <> 'TERMINATED' and time_created > now() - '1 days' :: interval;
  EOQ
}

query "database_autonomous_db_30_days" {
  sql = <<-EOQ
    select
      count(*) as value,
      '1-30 Days' as label
    from
      oci_database_autonomous_database
    where
      lifecycle_state <> 'TERMINATED' and time_created between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval;
  EOQ
}

query "database_autonomous_db_90_days" {
  sql = <<-EOQ
    select
      count(*) as value,
      '30-90 Days' as label
    from
      oci_database_autonomous_database
    where
      lifecycle_state <> 'TERMINATED' and time_created between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval;
  EOQ
}

query "database_autonomous_db_365_days" {
  sql = <<-EOQ
    select
      count(*) as value,
      '90-365 Days' as label
    from
      oci_database_autonomous_database
    where
      lifecycle_state <> 'TERMINATED' and time_created between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval);
  EOQ
}

query "database_autonomous_db_1_year" {
  sql = <<-EOQ
    select
      count(*) as value,
      '> 1 Year' as label
    from
      oci_database_autonomous_database
    where
      lifecycle_state <> 'TERMINATED' and time_created <= now() - '1 year' :: interval;
  EOQ
}

query "database_autonomous_db_age_report" {
  sql = <<-EOQ
    select
      d.display_name as "Name",
      d.id as "OCID",
      now()::date - d.time_created::date as "Age in Days",
      d.time_created as "Create Time",
      d.lifecycle_state as "Lifecycle State",
      t.title as "Tenancy",
      coalesce(c.title, 'root') as "Compartment",
      d.region as "Region"
    from
      oci_database_autonomous_database as d
      left join oci_identity_compartment as c on d.compartment_id = c.id
      left join oci_identity_tenancy as t on d.tenant_id = t.id
    where
      d.lifecycle_state <> 'TERMINATED'
    order by
      d.time_created,
      d.display_name;
  EOQ
}
