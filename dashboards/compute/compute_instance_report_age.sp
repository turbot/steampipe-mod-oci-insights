dashboard "oci_compute_instance_age_report" {

  title         = "OCI Compute Instance Age Report"
  documentation = file("./dashboards/compute/docs/compute_instance_report_age.md")

  tags = merge(local.compute_common_tags, {
    type     = "Report"
    category = "Age"
  })

  container {

    card {
      sql   = query.oci_compute_instance_count.sql
      width = 2
    }

    card {
      sql   = query.oci_compute_instance_24_hrs.sql
      width = 2
      type  = "info"
    }

    card {
      sql   = query.oci_compute_instance_30_days.sql
      width = 2
      type  = "info"
    }

    card {
      sql   = query.oci_compute_instance_90_days.sql
      width = 2
      type  = "info"
    }

    card {
      sql   = query.oci_compute_instance_365_days.sql
      width = 2
      type  = "info"
    }

    card {
      sql   = query.oci_compute_instance_1_year.sql
      width = 2
      type  = "info"
    }

  }

  table {
    column "OCID" {
      display = "none"
    }

    column "Name" {
      href = "${dashboard.oci_compute_instance_detail.url_path}?input.instance_id={{.OCID | @uri}}"
    }

    sql = query.oci_compute_instance_age_report.sql
  }

}

query "oci_compute_instance_24_hrs" {
  sql = <<-EOQ
    select
      count(*) as value,
      '< 24 hours' as label
    from
      oci_core_instance
    where
      lifecycle_state <> 'TERMINATED' and time_created > now() - '1 days' :: interval;
  EOQ
}

query "oci_compute_instance_30_days" {
  sql = <<-EOQ
    select
      count(*) as value,
      '1-30 Days' as label
    from
      oci_core_instance
    where
      lifecycle_state <> 'TERMINATED' and time_created between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval;
  EOQ
}

query "oci_compute_instance_90_days" {
  sql = <<-EOQ
    select
      count(*) as value,
      '30-90 Days' as label
    from
      oci_core_instance
    where
      lifecycle_state <> 'TERMINATED' and time_created between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval;
  EOQ
}

query "oci_compute_instance_365_days" {
  sql = <<-EOQ
    select
      count(*) as value,
      '90-365 Days' as label
    from
      oci_core_instance
    where
      lifecycle_state <> 'TERMINATED' and time_created between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval);
  EOQ
}

query "oci_compute_instance_1_year" {
  sql = <<-EOQ
    select
      count(*) as value,
      '> 1 Year' as label
    from
      oci_core_instance
    where
      lifecycle_state <> 'TERMINATED' and time_created <= now() - '1 year' :: interval;
  EOQ
}

query "oci_compute_instance_age_report" {
  sql = <<-EOQ
    select
      i.display_name as "Name",
      now()::date - i.time_created::date as "Age in Days",
      i.time_created as "Create Time",
      i.lifecycle_state as "Lifecycle State",
      t.title as "Tenancy",
      coalesce(c.title, 'root') as "Compartment",
      i.region as "Region",
      i.id as "OCID"
    from
      oci_core_instance as i
      left join oci_identity_compartment as c on i.compartment_id = c.id
      left join oci_identity_tenancy as t on i.tenant_id = t.id
    where
      i.lifecycle_state <> 'TERMINATED'
    order by
      i.display_name;
  EOQ
}
