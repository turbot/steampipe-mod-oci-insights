dashboard "oci_identity_api_key_age_report" {

  title = "OCI Identity API Key Age Report"

  tags = merge(local.identity_common_tags, {
    type     = "Report"
    category = "Age"
  })

  container {

    card {
      sql   = query.oci_identity_api_key_count.sql
      width = 2
    }

    card {
      sql   = query.oci_identity_api_key_24_hrs.sql
      width = 2
      type  = "info"
    }

    card {
      sql   = query.oci_identity_api_key_30_days.sql
      width = 2
      type  = "info"
    }

    card {
      sql   = query.oci_identity_api_key_90_days.sql
      width = 2
      type  = "info"
    }

    card {
      sql   = query.oci_identity_api_key_365_days.sql
      width = 2
      type  = "info"
    }

    card {
      sql   = query.oci_identity_api_key_1_year.sql
      width = 2
      type  = "info"
    }

  }

  container {

    table {

      sql = query.oci_identity_api_key_age_table.sql
    }

  }

}

query "oci_identity_api_key_count" {
  sql = <<-EOQ
    select count(*) as "API Keys" from oci_identity_api_key;
  EOQ
}

query "oci_identity_api_key_24_hrs" {
  sql = <<-EOQ
    select
      count(*) as value,
      '< 24 hours' as label
    from
      oci_identity_api_key
    where
       time_created > now() - '1 days' :: interval;
  EOQ
}

query "oci_identity_api_key_30_days" {
  sql = <<-EOQ
    select
      count(*) as value,
      '1-30 Days' as label
    from
      oci_identity_api_key
    where
       time_created between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval;
  EOQ
}

query "oci_identity_api_key_90_days" {
  sql = <<-EOQ
    select
      count(*) as value,
      '30-90 Days' as label
    from
      oci_identity_api_key
    where
       time_created between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval;
  EOQ
}

query "oci_identity_api_key_365_days" {
  sql = <<-EOQ
    select
      count(*) as value,
      '90-365 Days' as label
    from
      oci_identity_api_key
    where
       time_created between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval);
  EOQ
}

query "oci_identity_api_key_1_year" {
  sql = <<-EOQ
    select
      count(*) as value,
      '> 1 Year' as label
    from
      oci_identity_api_key
    where
      time_created <= now() - '1 year' :: interval;
  EOQ
}

query "oci_identity_api_key_age_table" {
  sql = <<-EOQ
    select
      k.user_name as "User",
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
      k.title;
  EOQ
}
