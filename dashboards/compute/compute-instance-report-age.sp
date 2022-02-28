dashboard "oci_compute_instance_age_report" {

  title = "OCI Compute Instance Age Report"

  container {

    card {
      sql   = query.oci_compute_instance_count.sql
      width = 2
    }

    card {
      sql   = <<-EOQ
        select
          count(*) as value,
          '< 24 hours' as label
        from
          oci_core_instance
        where
          time_created > now() - '1 days' :: interval and lifecycle_state <> 'TERMINATED';
      EOQ
      width = 2
      type  = "info"
    }

    card {
      sql   = <<-EOQ
        select
          count(*) as value,
          '1-30 Days' as label
        from
          oci_core_instance
        where
          time_created between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval
          and lifecycle_state <> 'TERMINATED';
      EOQ
      width = 2
      type  = "info"
    }

    card {
      sql   = <<-EOQ
        select
          count(*) as value,
          '30-90 Days' as label
        from
          oci_core_instance
        where
          time_created between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval
          and lifecycle_state <> 'TERMINATED';
      EOQ
      width = 2
      type  = "info"
    }

    card {
      sql   = <<-EOQ
        select
          count(*) as value,
          '90-365 Days' as label
        from
          oci_core_instance
        where
          time_created between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval)
          and lifecycle_state <> 'TERMINATED';
      EOQ
      width = 2
      type  = "info"
    }

    card {
      sql   = <<-EOQ
        select
          count(*) as value,
          '> 1 Year' as label
        from
          oci_core_instance
        where
          time_created <= now() - '1 year' :: interval and lifecycle_state <> 'TERMINATED';
      EOQ
      width = 2
      type  = "info"
    }
  }

  container {

    table {
      sql = <<-EOQ
        select
          i.display_name as "Name",
          now()::date - i.time_created::date as "Age in Days",
          i.time_created as "Create Time",
          coalesce(c.title, 'root') as "Compartment",
          t.title as "Tenancy",
          i.region as "Region",
          i.id as "OCID"
        from
          oci_core_instance as i
          left join oci_identity_compartment as c on i.compartment_id = c.id
          left join oci_identity_tenancy as t on i.tenant_id = t.id
          where
            i.lifecycle_state <> 'TERMINATED'
        order by
          i.time_created,
          i.title;
      EOQ
    }
  }

}
