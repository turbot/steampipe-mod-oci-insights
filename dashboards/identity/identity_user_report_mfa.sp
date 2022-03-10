dashboard "oci_identity_user_mfa_report" {

  title         = "OCI Identity User MFA Report"
  documentation = file("./dashboards/identity/docs/identity_user_report_mfa.md")

  tags = merge(local.identity_common_tags, {
    type = "Report"
  })

  container {

    card {
      sql   = query.oci_identity_user_count.sql
      width = 2
    }

    card {
      sql   = query.oci_identity_user_mfa_disabled_count.sql
      width = 2
    }

  }

  container {

    table {
      column "OCID" {
        display = "none"
      }

      sql = query.oci_identity_user_mfa_report.sql
    }
  }
}

query "oci_identity_user_mfa_report" {
  sql = <<-EOQ
    select
      u.name as "User Name",
      case when u.is_mfa_activated then 'Enabled' else null end as "MFA Status",
      t.name as "Tenancy",
      u.id as "OCID"
    from
      oci_identity_user as u,
      oci_identity_tenancy as t
    where
      t.id = u.tenant_id
    order by
      u.name;
  EOQ
}
