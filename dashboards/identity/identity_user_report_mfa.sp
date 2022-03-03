dashboard "oci_identity_user_mfa_report" {

  title = "OCI Identity User MFA Report"

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
      sql = query.oci_identity_user_mfa_table.sql
    }
  }
}

query "oci_identity_user_mfa_table" {
  sql = <<-EOQ
      select
        u.name as "User",
        u.is_mfa_activated as "mfa status",
        t.name as "Tenancy",
        u.id as "ID"
      from
        oci_identity_user as u,
        oci_identity_tenancy as t
      where
        t.id = u.tenant_id
      order by
        u.name;
  EOQ
}
