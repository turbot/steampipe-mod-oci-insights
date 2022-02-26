dashboard "oci_ons_subscription_age_report" {

  title = "OCI ONS Subscription Age Report"


  container {

    card {
      sql   = query.oci_ons_subscription_count.sql
      width = 2
    }

    card {
      sql   = <<-EOQ
        select
          count(*) as value,
          '< 24 hours' as label
        from
          oci_ons_subscription
        where
          created_time > now() - '1 days' :: interval;
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
          oci_ons_subscription
        where
          created_time between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval;
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
          oci_ons_subscription
        where
          created_time between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval;
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
          oci_ons_subscription
        where
          created_time between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval);
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
          oci_ons_subscription
        where
          created_time <= now() - '1 year' :: interval;
      EOQ
      width = 2
      type  = "info"
    }

  }

  container {

    table {

      sql = <<-EOQ
        select
          v.id as "OCID",
          now()::date - v.created_time::date as "Age in Days",
          v.created_time as "Create Time",
          v.lifecycle_state as "Lifecycle State",
          coalesce(c.title, 'root') as "Compartment",
          t.title as "Tenancy",
          v.region as "Region"
        from
          oci_ons_subscription as v
          left join oci_identity_compartment as c on v.compartment_id = c.id
          left join oci_identity_tenancy as t on v.tenant_id = t.id
        order by
          v.created_time,
          v.title;
      EOQ
    }

  }

}
