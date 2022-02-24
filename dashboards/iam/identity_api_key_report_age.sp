

dashboard "oci_identity_api_key_age_report" {

  title = "OCI Identity API Key Age Report"


  container {

    card {
      sql   = <<-EOQ
        select count(*) as "API Keys" from oci_identity_api_key
      EOQ
      width = 2
    }

    card {
      sql   = <<-EOQ
        select
          count(*) as value,
          '< 24 hours' as label
        from
          oci_identity_api_key
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
          oci_identity_api_key
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
          oci_identity_api_key
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
          oci_identity_api_key
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
          oci_identity_api_key
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
          -- k.title as "API Key",
          k.user_name as "User",
          -- date_trunc('day',age(now(),k.time_created))::text as "Age",
          now()::date - k.time_created::date as "Age in Days",
          k.time_created as "Create Time",
          k.lifecycle_state as "State",
          t.name as "Tenancy",
          k.key_id as "Key OCID"
        from
          oci_identity_api_key as k,
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
