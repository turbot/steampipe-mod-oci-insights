query "oci_identity_user_mfa_not_enabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'MFA Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      oci_identity_user
    where
      not is_mfa_activated
  EOQ
}

dashboard "oci_identity_user_mfa_report" {

  title = "OCI Identity User MFA Report"

  container {

    card {
      sql   = query.oci_identity_user_mfa_not_enabled_count.sql
      width = 2
    }
  }

  container {
    table {
      sql = <<-EOQ
      select
        name as "User",
        time_created as "Created Time",
        is_mfa_activated as "mfa status",
        id as "ID"
      from
        oci_identity_user
      order by
        is_mfa_activated
      EOQ
    }
  }
}
