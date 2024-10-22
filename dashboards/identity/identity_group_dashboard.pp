dashboard "identity_group_dashboard" {

  title         = "OCI Identity Group Dashboard"
  documentation = file("./dashboards/identity/docs/identity_group_dashboard.md")


  tags = merge(local.identity_common_tags, {
    type = "Dashboard"
  })

  container {

    # Analysis
    card {
      query = query.identity_group_count
      width = 3
    }

    # Assessments
    card {
      query = query.identity_groups_without_users_count
      width = 3
    }

    card {
      query = query.identity_groups_without_policies_count
      width = 3
    }

  }

  container {

    title = "Assessments"

    chart {
      title = "Groups Without Users"
      query = query.identity_groups_without_users
      type  = "donut"
      width = 3

      series "count" {
        point "with users" {
          color = "ok"
        }
        point "no users" {
          color = "alert"
        }
      }
    }

    chart {
      title = "Groups Without Policies"
      query = query.identity_groups_with_policy
      type  = "donut"
      width = 3

      series "count" {
        point "with policies" {
          color = "ok"
        }
        point "no policies" {
          color = "alert"
        }
      }
    }

  }

  container {

    title = "Analysis"

    chart {
      title = "Groups by Tenancy"
      query = query.identity_groups_by_tenancy
      type  = "column"
      width = 4
    }

    chart {
      title = "Groups by Age"
      query = query.identity_groups_by_creation_month
      type  = "column"
      width = 4
    }

  }

}

# Card Queries

query "identity_group_count" {
  sql = <<-EOQ
    select count(*) as "Groups" from oci_identity_group;
  EOQ
}

query "identity_groups_without_users_count" {
  sql = <<-EOQ
    with user_group as (
      select
        jsonb_array_elements(user_groups) ->> 'groupId' as g_id
      from
        oci_identity_user
    )
    select
      count(*) as value,
      'Without Users' as label,
      case when count(*) = 0 then 'ok' else 'alert' end as type
    from
      oci_identity_group
    where
      id not in (select distinct g_id from user_group);
  EOQ
}


query "identity_groups_without_policies_count" {
  sql = <<-EOQ
    with group_with_policy as (
      select
        distinct g.name as group_name,
        g.id as group_id
      from
        oci_identity_policy as p,
        jsonb_array_elements_text(statements) as s,
        oci_identity_group as g
      where
        s ilike '%' || g.name || '%'
    )
    select
      count(*) as value,
      'Without policies' as label,
      case when count(*) = 0 then 'ok' else 'alert' end as type
    from
      oci_identity_group
    where
      id not in (select distinct group_id from group_with_policy);
  EOQ
}



# Assessment Queries

query "identity_groups_without_users" {
  sql = <<-EOQ
    with user_group as (
      select
        jsonb_array_elements(user_groups) ->> 'groupId' as g_id
      from
        oci_identity_user
    ), groups_without_users as (
        select
          id,
          case
            when id not in (select distinct g_id from user_group) then 'no users'
            else 'with users'
          end as has_users
        from
          oci_identity_group
        )
      select
        has_users,
        count(*)
      from
        groups_without_users
      group by
        has_users;
  EOQ
}

query "identity_groups_with_policy" {
  sql = <<-EOQ
    with group_with_policy as (
      select
        distinct g.name as group_name,
        g.id as group_id
      from
        oci_identity_policy as p,
        jsonb_array_elements_text(statements) as s,
        oci_identity_group as g
      where
        s ilike '%' || g.name || '%'
    ),group_without_policy as (
      select
        id,
        case
          when id not in (select distinct group_id from group_with_policy) then 'no policies'
          else 'with policies'
        end as has_policies
      from
        oci_identity_group
    )
      select
        has_policies,
        count(*)
      from
        group_without_policy
      group by
        has_policies;
  EOQ
}

# Analysis Queries

query "identity_groups_by_tenancy" {
  sql = <<-EOQ
    select
      t.name as "Tenancy",
      count(g.*) as "Total"
    from
      oci_identity_group as g,
      oci_identity_tenancy as t
    where
      t.id = g.tenant_id
    group by
      t.name
    order by count(g.*) desc;
  EOQ
}

query "identity_groups_by_creation_month" {
  sql = <<-EOQ
    with groups as (
      select
        title,
        time_created,
        to_char(time_created,
          'YYYY-MM') as creation_month
      from
        oci_identity_group
    ),
    months as (
      select
        to_char(d,
          'YYYY-MM') as month
      from
        generate_series(date_trunc('month',
          (
            select
              min(time_created)
              from groups)),
          date_trunc('month',
            current_date),
          interval '1 month') as d
    ),
    groups_by_month as (
      select
        creation_month,
        count(*)
      from
        groups
      group by
        creation_month
    )
    select
      months.month,
      groups_by_month.count
    from
      months
      left join groups_by_month on months.month = groups_by_month.creation_month
    order by
      months.month;
  EOQ
}
