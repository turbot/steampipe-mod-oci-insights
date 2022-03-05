dashboard "oci_identity_customer_key_age_report" {

  title = "OCI Identity Customer Key Age Report"

  tags = merge(local.identity_common_tags, {
    type     = "Report"
    category = "Age"
  })

  container {

    card {
      sql   = query.oci_identity_customer_secret_key_count.sql
      width = 2
    }

    card {
      sql   = query.oci_identity_customer_secret_key_24_hrs.sql
      width = 2
      type  = "info"
    }

    card {
      sql   = query.oci_identity_customer_secret_key_30_days.sql
      width = 2
      type  = "info"
    }

    card {
      sql   = query.oci_identity_customer_secret_key_90_days.sql
      width = 2
      type  = "info"
    }

    card {
      sql   = query.oci_identity_customer_secret_key_365_days.sql
      width = 2
      type  = "info"
    }

    card {
      sql   = query.oci_identity_customer_secret_key_1_year.sql
      width = 2
      type  = "info"
    }

  }

  table {
    column "OCID" {
      display = "none"
    }

    sql = query.oci_identity_customer_secret_key_age_table.sql
  }

}

query "oci_identity_customer_secret_key_count" {
  sql = <<-EOQ
    select count(*) as "Customer Keys" from oci_identity_customer_secret_key;
  EOQ
}

query "oci_identity_customer_secret_key_24_hrs" {
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

query "oci_identity_customer_secret_key_30_days" {
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

query "oci_identity_customer_secret_key_90_days" {
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

query "oci_identity_customer_secret_key_365_days" {
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

query "oci_identity_customer_secret_key_1_year" {
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

query "oci_identity_customer_secret_key_age_table" {
  sql = <<-EOQ
    select
      k.title as "Customer Secret Key",
      k.user_name as "User",
      now()::date - k.time_created::date as "Age in Days",
      k.time_created as "Create Time",
      k.time_expires as "Expiry Time",
      k.lifecycle_state as "State",
      t.name as "Tenancy",
      k.id as "OCID"
    from
      oci_identity_customer_secret_key as k,
      oci_identity_tenancy as t
    where
      t.id = k.tenant_id
    order by
      k.title;
  EOQ
}
