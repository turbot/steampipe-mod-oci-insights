dashboard "identity_user_dashboard" {

  title         = "OCI Identity User Dashboard"
  documentation = file("./dashboards/identity/docs/identity_user_dashboard.md")

  tags = merge(local.identity_common_tags, {
    type = "Dashboard"
  })

  container {

    card {
      sql   = query.identity_user_count.sql
      width = 2
    }

    card {
      sql   = query.identity_user_not_attached_to_group.sql
      width = 2
    }

    card {
      sql   = query.identity_user_mfa_disabled_count.sql
      width = 2
      href  = dashboard.identity_user_mfa_report.url_path
    }

  }

  container {
    title = "Assesments"

    chart {
      title = "MFA Status"
      sql   = query.identity_user_mfa_enabled.sql
      type  = "donut"
      width = 3

      series "count" {
        point "enabled" {
          color = "ok"
        }
        point "disabled" {
          color = "alert"
        }
      }
    }

  }

  container {
    title = "Analysis"

    chart {
      title = "Users by Tenancy"
      sql   = query.identity_users_by_tenancy.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "Users by Group"
      sql   = query.identity_user_by_groups.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "Users by Type"
      sql   = query.identity_user_by_type.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "Users by Age"
      sql   = query.identity_users_by_creation_month.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "Users by Email Verification"
      sql   = query.identity_user_by_verified_email.sql
      type  = "column"
      width = 4
    }

  }

}

# Card Queries

query "identity_user_count" {
  sql = <<-EOQ
    select count(*) as "Users" from oci_identity_user;
  EOQ
}

query "identity_user_not_attached_to_group" {
  sql = <<-EOQ
  select
    count(oci_identity_user.name) as value,
    'Users Without Group' as label
  from
    oci_identity_user,
    jsonb_array_elements(user_groups) as user_group
    inner join oci_identity_group ON (oci_identity_group.id = user_group ->> 'groupId');
  EOQ
}

query "identity_user_mfa_disabled_count" {
  sql = <<-EOQ
    select
      count(*) as  value,
      'MFA Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      oci_identity_user
    where
      not is_mfa_activated;
  EOQ
}

# Assesment Queries

query "identity_user_mfa_enabled" {
  sql = <<-EOQ
    with mfa_stat as (
      select
        case
          when is_mfa_activated then 'enabled'
          else 'disabled'
        end as mfa_stat
      from
        oci_identity_user
    )
    select
      mfa_stat,
      count(*)
    from
      mfa_stat
    group by
      mfa_stat
  EOQ
}

# Analysis Queries

query "identity_users_by_tenancy" {
  sql = <<-EOQ
    select
      t.name as "tenancy",
      count(u.*) as "total"
    from
      oci_identity_user as u,
      oci_identity_tenancy as t
    where
      t.id = u.tenant_id
    group by
      tenancy
    order by count(u.*) desc;
  EOQ
}

query "identity_users_by_creation_month" {
  sql = <<-EOQ
    with users as (
      select
        name,
        time_created,
        to_char(time_created,
          'YYYY-MM') as creation_month
      from
        oci_identity_user
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
                from users)),
            date_trunc('month',
              current_date),
            interval '1 month') as d
    ),
    users_by_month as (
      select
        creation_month,
        count(*)
      from
        users
      group by
        creation_month
    )
    select
      months.month,
      coalesce(users_by_month.count,0)
    from
      months
      left join users_by_month on months.month = users_by_month.creation_month
    order by
      months.month;
  EOQ
}

query "identity_user_by_type" {
  sql = <<-EOQ
    select
       user_type as "User Type",
       count(name)::numeric as "Users"
    from
      oci_identity_user
    group by
      user_type
    order by
      user_type;
  EOQ
}

query "identity_user_by_groups" {
  sql = <<-EOQ
    with users_and_grp as (
      select
        oci_identity_user.name as user_name,
        oci_identity_group.name as group_name,
        user_group ->> 'groupId' as group_id
      from
        oci_identity_user,
        jsonb_array_elements(user_groups) as user_group
        inner join oci_identity_group ON (oci_identity_group.id = user_group ->> 'groupId' )
    )
    select
      group_name as "Group Name",
      count(user_name) as "Users"
    from
      users_and_grp
    group by
      group_name
    order by
      group_name;
  EOQ
}

query "identity_user_by_verified_email" {
  sql = <<-EOQ
    with email_stat as (
      select
        case
          when email_verified then 'verified' else 'unverified'
        end as email_stat
      from
        oci_identity_user
    )
      select
        email_stat,
        count(*)
      from
        email_stat
      group by
        email_stat
  EOQ
}
