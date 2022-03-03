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
        name as "User",
        time_created as "Created Time",
        is_mfa_activated as "mfa status",
        id as "ID"
      from
        oci_identity_user
      order by
        is_mfa_activated;
  EOQ
}
