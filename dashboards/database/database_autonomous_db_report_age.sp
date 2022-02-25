dashboard "oci_database_autonomous_database_age_report" {

  title = "OCI Autonomous Database Age Report"


  container {

    card {
      sql   = query.oci_database_autonomous_database_count.sql
      width = 2
    }

    card {
      sql   = <<-EOQ
        select
          count(*) as value,
          '< 24 hours' as label
        from
          oci_database_autonomous_database
        where
          time_created > now() - '1 days' :: interval and lifecycle_state <> 'DELETED';
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
          oci_database_autonomous_database
        where
          time_created between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval
          and lifecycle_state <> 'DELETED';
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
          oci_database_autonomous_database
        where
          time_created between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval
          and lifecycle_state <> 'DELETED';
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
          oci_database_autonomous_database
        where
          time_created between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval)
          and lifecycle_state <> 'DELETED';
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
          oci_database_autonomous_database
        where
          time_created <= now() - '1 year' :: interval and lifecycle_state <> 'DELETED';
      EOQ
      width = 2
      type  = "info"
    }

  }

  container {


    table {

      sql = <<-EOQ
        select
          v.display_name as "Name",
          -- date_trunc('day',age(now(),v.time_created))::text as "Age",
          now()::date - v.time_created::date as "Age in Days",
          v.time_created as "Create Time",
          v.lifecycle_state as "Lifecycle State",
          coalesce(a.title,'root') as "Compartment",
          t.title as "Tenancy",
          v.region as "Region",
          v.id as "OCID"
        from
          oci_database_autonomous_database as v
          left join oci_identity_compartment as a on v.compartment_id = a.id
          left join oci_identity_tenancy as t on v.tenant_id = t.id
          -- compartments as a
        where
          v.lifecycle_state <> 'DELETED'
        order by
          v.time_created,
          v.title;
      EOQ
    }

  }

}
