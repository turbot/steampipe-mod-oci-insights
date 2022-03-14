dashboard "oci_identity_user_detail" {

  title = "OCI Identity User Detail"

  tags = merge(local.identity_common_tags, {
    type     = "Report"
    category = "Detail"
  })

  input "user_id" {
    title = "Select a user:"
    sql   = query.oci_identity_user_input.sql
    width = 4
  }

  container {

    card {
      width = 2

      query = query.oci_identity_user_email
      args = {
        id = self.input.user_id.value
      }
    }

    card {
      query = query.oci_identity_user_mfa
      width = 2

      args = {
        id = self.input.user_id.value
      }
    }

  }

  container {

    container {
      width = 6

      table {
        title = "Overview"
        type  = "line"
        width = 6
        query = query.oci_identity_user_overview
        args = {
          id = self.input.user_id.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.oci_identity_user_tag
        args = {
          id = self.input.user_id.value
        }

      }
    }

    container {
      width = 6

      table {
        title = "Access Keys"
        query = query.oci_identity_user_access_key
        args = {
          id = self.input.user_id.value
        }
      }

      table {
        title = "Console Password"
        query = query.oci_identity_user_password
        args = {
          id = self.input.user_id.value
        }
      }

      table {
        title = "Group Details"
        query = query.oci_identity_user_group
        args = {
          id = self.input.user_id.value
        }
      }
    }

  }
}

query "oci_identity_user_input" {
  sql = <<EOQ
    select
      u.name as label,
      u.id as value,
      json_build_object(
        't.name', t.name
      ) as tags
    from
      oci_identity_user as u
      left join oci_identity_tenancy as t on u.tenant_id = t.id
    order by
      u.name;
EOQ
}

query "oci_identity_user_email" {
  sql = <<-EOQ
    select
      case when email_verified then 'Verified' else 'Unverified' end as "Email Verification"
    from
      oci_identity_user
    where
      id = $1;
  EOQ

  param "id" {}
}

query "oci_identity_user_mfa" {
  sql = <<-EOQ
    select
      case when is_mfa_activated then 'Activated' else 'Inactive' end as value,
      'MFA Status' as label,
      case when is_mfa_activated then 'ok' else 'alert' end as type
    from
      oci_identity_user
    where
      id = $1;
  EOQ

  param "id" {}
}

query "oci_identity_user_overview" {
  sql = <<-EOQ
    select
      name as "Name",
      time_created as "Time Created",
      user_type as "User Type",
      email as "Email",
      id as "OCID",
      tenant_id as "Tenancy ID"
    from
      oci_identity_user
    where
      id = $1;
  EOQ

  param "id" {}
}

query "oci_identity_user_tag" {
  sql = <<-EOQ
    with jsondata as (
    select
      tags::json as tags
    from
      oci_identity_user
    where
      id = $1
    )
    select
      key as "Key",
      value as "Value"
    from
      jsondata,
      json_each_text(tags);
  EOQ

  param "id" {}
}

query "oci_identity_user_access_key" {
  sql = <<-EOQ
    select
      fingerprint as "Fingerprint",
      time_created as "Time Created",
      inactive_status as "Inactive Status"
    from
      oci_identity_api_key
    where
      user_id = $1;
  EOQ

  param "id" {}
}

query "oci_identity_user_password" {
  sql = <<-EOQ
    select
      can_use_console_password as "Can Use Console Password",
      is_mfa_activated as "MFA Activated"
    from
      oci_identity_user
    where
      id  = $1
  EOQ

  param "id" {}
}

query "oci_identity_user_group" {
  sql = <<-EOQ
    select
      i.name as "Group Name",
      i.time_created as "Time Created"
    from
      oci_identity_user as u,
      jsonb_array_elements(user_groups) as g
      inner join oci_identity_group as i on i.id = g ->> 'groupId'
    where
      u.id  = $1
  EOQ

  param "id" {}
}

