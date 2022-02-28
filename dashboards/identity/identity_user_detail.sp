query "oci_identity_user_input" {
  sql = <<EOQ
    select
      id as label,
      id as value
    from
      oci_identity_user
    order by
      id;
EOQ
}

query "oci_identity_user_name_for_user" {
  sql = <<-EOQ
    select
      name as "User"
    from
      oci_identity_user
    where
      id = $1;
  EOQ

  param "id" {}
}

query "oci_identity_user_email_for_user" {
  sql = <<-EOQ
    select
      case when email_verified then 'true' else 'false' end as value,
      'Email Verified' as label,
      case when email_verified then 'ok' else 'alert' end as type
    from
      oci_identity_user
    where
      id = $1;
  EOQ

  param "id" {}
}

query "oci_identity_user_mfa_for_user" {
  sql = <<-EOQ
    select
      case when is_mfa_activated then 'true' else 'false' end as value,
      'MFA Activated' as label,
      case when is_mfa_activated then 'ok' else 'alert' end as type
    from
      oci_identity_user
    where
      id = $1;
  EOQ

  param "id" {}
}

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

    # Assessments
    card {
      width = 3

      query = query.oci_identity_user_name_for_user
      args = {
        id = self.input.user_id.value
      }
    }

    card {
      width = 2

      query = query.oci_identity_user_email_for_user
      args = {
        id = self.input.user_id.value
      }
    }

    card {
      query = query.oci_identity_user_mfa_for_user
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

        args = {
          id = self.input.user_id.value
        }

      }

      table {
        title = "Tags"
        width = 6

        sql = <<-EOQ
          WITH jsondata AS (
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

        args = {
          id = self.input.user_id.value
        }

      }
    }

    container {
      width = 6

      table {
        title = "Access Keys"
        sql   = <<-EOQ
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

        args = {
          id = self.input.user_id.value
        }
      }

      table {
        title = "Console Password"
        sql   = <<-EOQ
          select
            name as "Name",
            can_use_console_password as "Can Use Console Password",
            is_mfa_activated as "MFA Activated"
          from
            oci_identity_user
          where
           id  = $1
        EOQ

        param "id" {}

        args = {
          id = self.input.user_id.value
        }
      }

      table {
        title = "Group Details"
        sql   = <<-EOQ
          select
            u.name as "User Name",
            i.name as "Group Name",
            i.time_created as "Time Created"
          from
            oci_identity_user as u,
            jsonb_array_elements(user_groups) as g
            inner join oci_identity_group as i ON i.id = g ->> 'groupId'
          where
           u.id  = $1
        EOQ

        param "id" {}

        args = {
          id = self.input.user_id.value
        }
      }
    }

  }
}
