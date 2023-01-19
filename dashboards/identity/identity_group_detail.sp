dashboard "identity_group_detail" {

  title = "OCI Identity Group Detail"

  tags = merge(local.identity_common_tags, {
    type = "Detail"
  })

  input "group_id" {
    title = "Select a group:"
    query = query.identity_group_input
    width = 4
  }

  container {

    card {
      width = 2

      query = query.identity_group_lifecycle_state
      args = [self.input.group_id.value]
    }

  }

  with "identity_users_for_identity_group" {
    query = query.identity_users_for_identity_group
    args  = [self.input.group_id.value]
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.identity_group
        args = {
          identity_group_ids = [self.input.group_id.value]
        }
      }

      node {
        base = node.identity_user
        args = {
          identity_user_ids = with.identity_users_for_identity_group.rows[*].user_id
        }
      }

      edge {
        base = edge.identity_group_to_identity_user
        args = {
          identity_group_ids = [self.input.group_id.value]
        }
      }

    }
  }

  container {

    container {

      title = "Overview"

      table {
        type  = "line"
        width = 6
        query = query.identity_group_overview
        args  = [self.input.group_id.value]

      }

    }
  }

    container {

    title = "OCI Identity Group Analysis"

    table {
      title = "Users"
      width = 6
      column "User Name" {
        href = "${dashboard.identity_user_detail.url_path}?input.user_id={{.'User ID' | @uri}}"
      }

      query = query.identity_group_user
      args  = [self.input.group_id.value]
    }

  }
  }

# input queries

query "identity_group_input" {
  sql = <<-EOQ
    select
      g.name as label,
      g.id as value,
      json_build_object(
        't.name', t.name
      ) as tags
    from
      oci_identity_group as g
      left join oci_identity_tenancy as t on g.tenant_id = t.id
    order by
      g.name;
  EOQ
}

# With queries

query "identity_users_for_identity_group" {
  sql = <<-EOQ
    select
      id as user_id
    from
      oci_identity_user,
      jsonb_array_elements(user_groups) as gid
    where
      gid ->> 'groupId' = $1;
  EOQ
}

# Card queries

query "identity_group_lifecycle_state" {
  sql = <<-EOQ
    select
      'Lifecycle State' as label,
      lifecycle_state as value
    from
      oci_identity_group
    where
      id = $1;
  EOQ
}

# Other detail page queries

query "identity_group_overview" {
  sql = <<-EOQ
    select
      name as "Name",
      time_created as "Time Created",
      inactive_status as "Inactive Status",
      id as "Group ID",
      tenant_id as "Tenancy ID"
    from
      oci_identity_group
    where
      id = $1;
  EOQ
}

query "identity_group_user" {
  sql = <<-EOQ
    with user_group_id as (
      select
        jsonb_array_elements(user_groups) ->> 'groupId' as g_id,
        name,
        id
      from
        oci_identity_user
    )
    select
      u.name "User Name",
      u.id as "User ID"
    from
      oci_identity_group as g,
      user_group_id as u
    where
      g.id = u.g_id
      and g.id = $1
  EOQ
}
