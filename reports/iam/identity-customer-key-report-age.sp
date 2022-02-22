

dashboard "oci_identity_customer_key_age_report" {

  title = "OCI Identity Customer Key Age Report"


  container {

    # Analysis
    card {
      sql   = <<-EOQ
        select count(*) as "Customer Keys" from oci_identity_customer_secret_key
      EOQ
      width = 2
    }

    card {
      sql   = <<-EOQ
        select
          count(*) as value,
          '< 24 hours' as label
        from
          oci_identity_customer_secret_key
        where
          time_created > now() - '1 days' :: interval
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
          oci_identity_customer_secret_key
        where
          time_created between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval
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
          oci_identity_customer_secret_key
        where
          time_created between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval
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
          oci_identity_customer_secret_key
        where
          time_created between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval)
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
          oci_identity_customer_secret_key
        where
          time_created <= now() - '1 year' :: interval
      EOQ
      width = 2
      type  = "info"
    }

  }

  container {


    table {

      sql = <<-EOQ
        select
          k.title as "Customer Secret Key",
          k.user_name as "User",
          now()::date - k.time_created::date as "Age in Days",
          k.time_created as "Create Time",
          k.time_expires as "Expiry Time",
          k.lifecycle_state as "State",
          t.name as "Tenancy",
          k.id as "Key OCID"
        from
          oci_identity_customer_secret_key as k,
          oci_identity_tenancy as t
        where
          t.id = k.tenant_id
        order by
          k.time_created,
          k.title
      EOQ
    }


  }

}
