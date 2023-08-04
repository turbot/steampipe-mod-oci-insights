dashboard "kms_key_age_report" {

  title         = "OCI KMS Key Age Report"
  documentation = file("./dashboards/kms/docs/kms_key_report_age.md")

  tags = merge(local.kms_common_tags, {
    type     = "Report"
    category = "Age"
  })

  container {

    card {
      query = query.kms_key_count
      width = 2
    }

    card {
      query = query.kms_key_24_hrs
      width = 2
      type  = "info"
    }

    card {
      query = query.kms_key_30_days
      width = 2
      type  = "info"
    }

    card {
      query = query.kms_key_90_days
      width = 2
      type  = "info"
    }

    card {
      query = query.kms_key_365_days
      width = 2
      type  = "info"
    }

    card {
      query = query.kms_key_1_year
      width = 2
      type  = "info"
    }

  }

  table {
    column "OCID" {
      display = "none"
    }

    column "Name" {
      href = "${dashboard.kms_key_detail.url_path}?input.key_id={{.OCID | @uri}}"
    }

    query = query.kms_key_age_report
  }

}

query "kms_key_24_hrs" {
  sql = <<-EOQ
    select
      count(*) as value,
      '< 24 hours' as label
    from
      oci_kms_key
    where
      lifecycle_state <> 'DELETED' and time_created > now() - '1 days' :: interval;
  EOQ
}

query "kms_key_30_days" {
  sql = <<-EOQ
    select
      count(*) as value,
      '1-30 Days' as label
    from
      oci_kms_key
    where
      lifecycle_state <> 'DELETED' and time_created between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval;
  EOQ
}

query "kms_key_90_days" {
  sql = <<-EOQ
    select
      count(*) as value,
      '30-90 Days' as label
    from
      oci_kms_key
    where
      lifecycle_state <> 'DELETED' and time_created between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval;
  EOQ
}

query "kms_key_365_days" {
  sql = <<-EOQ
    select
      count(*) as value,
      '90-365 Days' as label
    from
      oci_kms_key
    where
      lifecycle_state <> 'DELETED' and time_created between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval);
  EOQ
}

query "kms_key_1_year" {
  sql = <<-EOQ
    select
      count(*) as value,
      '> 1 Year' as label
    from
      oci_kms_key
    where
      lifecycle_state <> 'DELETED' and time_created <= now() - '1 year' :: interval;
  EOQ
}

query "kms_key_age_report" {
  sql = <<-EOQ
    select
      k.name as "Name",
      k.id as "OCID",
      now()::date - k.time_created::date as "Age in Days",
      k.time_created as "Create Time",
      k.vault_name as "Vault Name",
      k.lifecycle_state as "Lifecycle State",
      t.title as "Tenancy",
      coalesce(c.title, 'root') as "Compartment",
      k.region as "Region"
    from
      oci_kms_key as k
      left join oci_identity_compartment as c on k.compartment_id = c.id
      left join oci_identity_tenancy as t on k.tenant_id = t.id
    where
      k.lifecycle_state <> 'DELETED'
    order by
      k.time_created,
      k.name;
  EOQ
}
