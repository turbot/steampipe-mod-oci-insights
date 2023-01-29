dashboard "identity_customer_secret_key_age_report" {

  title         = "OCI Identity Customer Secret Key Age Report"
  documentation = file("./dashboards/identity/docs/identity_customer_secret_key_report_age.md")

  tags = merge(local.identity_common_tags, {
    type     = "Report"
    category = "Age"
  })

  container {

    card {
      query = query.identity_customer_secret_key_count
      width = 2
    }

    card {
      query = query.identity_customer_secret_key_24_hrs
      width = 2
      type  = "info"
    }

    card {
      query = query.identity_customer_secret_key_30_days
      width = 2
      type  = "info"
    }

    card {
      query = query.identity_customer_secret_key_90_days
      width = 2
      type  = "info"
    }

    card {
      query = query.identity_customer_secret_key_365_days
      width = 2
      type  = "info"
    }

    card {
      query = query.identity_customer_secret_key_1_year
      width = 2
      type  = "info"
    }

  }

  table {
    column "OCID" {
      display = "none"
    }

    query = query.identity_customer_secret_key_age_report
  }

}

query "identity_customer_secret_key_count" {
  sql = <<-EOQ
    select count(*) as "Customer Keys" from oci_identity_customer_secret_key;
  EOQ
}

query "identity_customer_secret_key_24_hrs" {
  sql = <<-EOQ
    select
      count(*) as value,
      '< 24 hours' as label
    from
      oci_identity_customer_secret_key
    where
      lifecycle_state <> 'DELETED' and time_created > now() - '1 days' :: interval;
  EOQ
}

query "identity_customer_secret_key_30_days" {
  sql = <<-EOQ
    select
      count(*) as value,
      '1-30 Days' as label
    from
      oci_identity_customer_secret_key
    where
      lifecycle_state <> 'DELETED' and time_created between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval;
  EOQ
}

query "identity_customer_secret_key_90_days" {
  sql = <<-EOQ
    select
      count(*) as value,
      '30-90 Days' as label
    from
      oci_identity_customer_secret_key
    where
      lifecycle_state <> 'DELETED' and time_created between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval;
  EOQ
}

query "identity_customer_secret_key_365_days" {
  sql = <<-EOQ
    select
      count(*) as value,
      '90-365 Days' as label
    from
      oci_identity_customer_secret_key
    where
      lifecycle_state <> 'DELETED' and time_created between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval);
  EOQ
}

query "identity_customer_secret_key_1_year" {
  sql = <<-EOQ
    select
      count(*) as value,
      '> 1 Year' as label
    from
      oci_identity_customer_secret_key
    where
      lifecycle_state <> 'DELETED' and time_created <= now() - '1 year' :: interval;
  EOQ
}

query "identity_customer_secret_key_age_report" {
  sql = <<-EOQ
    select
      k.display_name as "Customer Secret Key",
      k.user_name as "User Name",
      now()::date - k.time_created::date as "Age in Days",
      k.time_created as "Create Time",
      k.time_expires as "Expiration Time",
      k.lifecycle_state as "Lifecycle State",
      t.name as "Tenancy",
      k.id as "OCID"
    from
      oci_identity_customer_secret_key as k,
      oci_identity_tenancy as t
    where
      t.id = k.tenant_id
    order by
      k.display_name;
  EOQ
}
