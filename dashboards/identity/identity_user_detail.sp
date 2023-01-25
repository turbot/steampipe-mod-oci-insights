dashboard "identity_user_detail" {

  title = "OCI Identity User Detail"
  documentation = file("./dashboards/identity/docs/identity_user_detail.md")

  tags = merge(local.identity_common_tags, {
    type = "Detail"
  })

  input "user_id" {
    title = "Select a user:"
    query = query.identity_user_input
    width = 4
  }

  container {

    card {
      width = 2

      query = query.identity_user_email
      args = [self.input.user_id.value]
    }

    card {
      query = query.identity_user_mfa
      width = 2

      args = [self.input.user_id.value]
    }

  }

  with "identity_groups_for_identity_user" {
    query = query.identity_groups_for_identity_user
    args  = [self.input.user_id.value]
  }

  with "identity_api_key_for_identity_user" {
    query = query.identity_api_key_for_identity_user
    args  = [self.input.user_id.value]
  }

  with "identity_auth_token_for_identity_user" {
    query = query.identity_auth_token_for_identity_user
    args  = [self.input.user_id.value]
  }

  with "identity_customer_secret_key_for_identity_user" {
    query = query.identity_customer_secret_key_for_identity_user
    args  = [self.input.user_id.value]
  }


  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.identity_api_key
        args = {
          identity_api_key_ids = with.identity_api_key_for_identity_user.rows[*].api_key_id
        }
      }

      node {
        base = node.identity_auth_token
        args = {
          identity_auth_token_ids = with.identity_auth_token_for_identity_user.rows[*].auth_token_id
        }
      }

      node {
        base = node.identity_customer_secret_key
        args = {
          identity_customer_secret_key_ids = with.identity_customer_secret_key_for_identity_user.rows[*].customer_secret_key_id
        }
      }

      node {
        base = node.identity_group
        args = {
          identity_group_ids = with.identity_groups_for_identity_user.rows[*].group_id
        }
      }

      node {
        base = node.identity_user
        args = {
          identity_user_ids = [self.input.user_id.value]
        }
      }

      edge {
        base = edge.identity_group_to_identity_user
        args = {
          identity_group_ids = with.identity_groups_for_identity_user.rows[*].group_id
        }
      }

      edge {
        base = edge.identity_user_to_identity_api_key
        args = {
          identity_api_key_ids = with.identity_api_key_for_identity_user.rows[*].api_key_id
        }
      }

      edge {
        base = edge.identity_user_to_identity_auth_token
        args = {
          identity_auth_token_ids = with.identity_auth_token_for_identity_user.rows[*].auth_token_id
        }
      }

      edge {
        base = edge.identity_user_to_identity_customer_secret_key
        args = {
          identity_customer_secret_key_ids = with.identity_customer_secret_key_for_identity_user.rows[*].customer_secret_key_id
        }
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
        query = query.identity_user_overview
        args = [self.input.user_id.value]

      }

      table {
        title = "Tags"
        width = 6
        query = query.identity_user_tag
        args = [self.input.user_id.value]

      }
    }

    container {
      width = 6

      table {
        title = "Access Keys"
        query = query.identity_user_access_key
        args = [self.input.user_id.value]
      }

      table {
        title = "Console Password"
        query = query.identity_user_password
        args = [self.input.user_id.value]
      }

      table {
        title = "Group Details"
        query = query.identity_user_group
        args = [self.input.user_id.value]


        column "Group Name" {
          href = "/oci_insights.dashboard.identity_group_detail?input.group_id={{.ID | @uri}}"
        }
      }
    }

  }
}

# Input queries

query "identity_user_input" {
  sql = <<-EOQ
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

# With queries

query "identity_groups_for_identity_user" {
  sql = <<-EOQ
    select
      jsonb_array_elements(user_groups)->> 'groupId' as group_id
    from
      oci_identity_user
    where
      id  = $1;
  EOQ
}

query "identity_api_key_for_identity_user" {
  sql = <<-EOQ
    select
      key_id as api_key_id
    from
      oci_identity_api_key
    where
      key_id is not null
      and user_id  = $1;
  EOQ
}

query "identity_auth_token_for_identity_user" {
  sql = <<-EOQ
    select
      id as auth_token_id
    from
      oci_identity_auth_token
    where
      id is not null
      and user_id = $1;
  EOQ
}

query "identity_customer_secret_key_for_identity_user" {
  sql = <<-EOQ
    select
      id as customer_secret_key_id
    from
      oci_identity_customer_secret_key
    where
      user_id = $1;
  EOQ
}

# Card queries

query "identity_user_email" {
  sql = <<-EOQ
    select
      case when email_verified then 'Verified' else 'Unverified' end as "Email Verification"
    from
      oci_identity_user
    where
      id = $1;
  EOQ
}

query "identity_user_mfa" {
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
}

# other detail page queries

query "identity_user_overview" {
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
}

query "identity_user_tag" {
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
}

query "identity_user_access_key" {
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
}

query "identity_user_password" {
  sql = <<-EOQ
    select
      can_use_console_password as "Can Use Console Password",
      is_mfa_activated as "MFA Activated"
    from
      oci_identity_user
    where
      id  = $1;
  EOQ
}

query "identity_user_group" {
  sql = <<-EOQ
    select
      i.name as "Group Name",
      i.time_created as "Time Created",
      i.id as "ID"
    from
      oci_identity_user as u,
      jsonb_array_elements(user_groups) as g
      inner join oci_identity_group as i on i.id = g ->> 'groupId'
    where
      u.id  = $1;
  EOQ
}
