
dashboard "oci_identity_customer_key_aging_report" {
  title = "OCI Identity Customer Key Aging Report"

  input "threshold_in_days" {
    title = "Threshold (days)"
    //type  = "text"
    width   = 2
    //default = "90"
  }

  container {

     # Analysis
    card {
      sql   = <<-EOQ
        select
          count(*) as value,
          'Customer Keys' as label
        from
          oci_identity_customer_secret_key
      EOQ
      width = 2
    }

    # Assessments
    card {
      sql   = <<-EOQ
        select
          count(*) as value,
          'Aged Keys' as label,
          case when count(*) = 0 then 'ok' else 'alert' end as type
        from
          oci_identity_customer_secret_key
        where
          time_created < now() - '90 days' :: interval;  -- should use the threshold value from input
      EOQ
      width = 2
    }
  }

  container {

   table {
      title = "Aged Customer Keys"

      sql   = <<-EOQ
        select
          k.user_name as "user",
          date_trunc('day',age(now(),k.time_created))::text as "Age",
          k.time_created,
          k.lifecycle_state,
          t.name as "tenancy"
        from
          oci_identity_customer_secret_key as k,
          -- left join oci_identity_tenancy as t on k.tenant_id = t.id
          oci_identity_tenancy as t
        where
          t.id = k.tenant_id
          and k.time_created < now() - '90 days' :: interval
        order by
          time_created
      EOQ
    }
  }

}