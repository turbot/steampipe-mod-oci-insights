dashboard "kms_vault_age_report" {

  title         = "OCI KMS Vault Age Report"
  documentation = file("./dashboards/kms/docs/kms_vault_report_age.md")

  tags = merge(local.kms_common_tags, {
    type     = "Report"
    category = "Age"
  })

  container {

    card {
      query = query.kms_vault_count
      width = 2
    }

    card {
      query = query.kms_vault_24_hrs
      width = 2
      type  = "info"
    }

    card {
      query = query.kms_vault_30_days
      width = 2
      type  = "info"
    }

    card {
      query = query.kms_vault_90_days
      width = 2
      type  = "info"
    }

    card {
      query = query.kms_vault_365_days
      width = 2
      type  = "info"
    }

    card {
      query = query.kms_vault_1_year
      width = 2
      type  = "info"
    }

  }

  table {
    column "OCID" {
      display = "none"
    }

    column "Display Name" {
      href = "${dashboard.kms_vault_detail.url_path}?input.kms_vault_id={{.OCID | @uri}}"
    }

    query = query.kms_vault_age_report
  }

}

query "kms_vault_24_hrs" {
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

query "kms_vault_30_days" {
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

query "kms_vault_90_days" {
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

query "kms_vault_365_days" {
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

query "kms_vault_1_year" {
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

query "kms_vault_age_report" {
  sql = <<-EOQ
    select
      v.display_name as "Display Name",
      now()::date - v.time_created::date as "Age in Days",
      v.time_created as "Create Time",
      v.lifecycle_state as "Lifecycle State",
      v.title as "Tenancy",
      coalesce(c.title, 'root') as "Compartment",
      v.region as "Region",
      v.id as "OCID"
    from
      oci_kms_vault as v
      left join oci_identity_compartment as c on v.compartment_id = c.id
      left join oci_identity_tenancy as t on v.tenant_id = t.id
    where
      v.lifecycle_state <> 'DELETED'
    order by
      v.display_name;
  EOQ
}
