query "oci_identity_user_count" {
  sql = <<-EOQ
    select count(*) as "Users" from oci_identity_user
  EOQ
}

  # can_use_auth_tokens,

query "oci_identity_user_unverified_email_count" {
  sql = <<-EOQ
    select count(*) as "Users With Unverified Email " from oci_identity_user where not email_verified
  EOQ
}

query "oci_identity_user_inactive_customer_key_count" {
  sql = <<-EOQ
    select
      count(*) as  value,
      'Inactive Customer Key' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      oci_identity_customer_secret_key
    where
      lifecycle_state = 'INACTIVE';
  EOQ
}

query "oci_identity_mfa_not_enabled_users_count" {
  sql = <<-EOQ
    select
      count(*) as  value,
      'MFA Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      oci_identity_user
    where
      not is_mfa_activated
  EOQ
}

query "oci_identity_console_login_enabled_users_count" {
  sql = <<-EOQ
  select count(*) as "Console Login Enabled" from oci_identity_user where can_use_api_keys
  EOQ
}

query "oci_identity_users_can_use_api_key_count" {
  sql = <<-EOQ
  select count(*) as "API Key Use Enabled" from oci_identity_user where can_use_api_keys
  EOQ
}

query "oci_identity_user_access_key_age_gt_90_days" {
  sql = <<-EOQ
  select
    count(distinct user_name) as value,
    'Active API Key Age > 90 Days' as label,
    case count(*) when 0 then 'ok' else 'alert' end as type
  from
    oci_identity_api_key
  where
    time_created > now() - interval '90 days' and
    lifecycle_state = 'ACTIVE'
  EOQ
}

query "oci_identity_user_not_attached_to_groups" {
  sql = <<-EOQ
  select
    count(oci_identity_user.name) as  value,
    'Users Without Group' as label,
    case count(*) when 0 then 'ok' else 'alert' end as type
  from
    oci_identity_user,
    jsonb_array_elements(user_groups) as user_group
    inner join oci_identity_group ON (oci_identity_group.id = user_group ->> 'groupId' );
  EOQ
}

query "oci_identity_users_by_tenancy" {
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
    order by count(u.*) desc
  EOQ
}

query "oci_identity_users_by_creation_month" {
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

query "oci_identity_user_mfa_enabled_by_tenancy" {
  sql = <<-EOQ
    select
       t.name as "tenancy",
       count(u.name)::numeric as "MFA Enabled"
    from
      oci_identity_user as u,
      oci_identity_tenancy as t
    where
      t.id = u.tenant_id and is_mfa_activated
    group by
      tenancy
    order by
      tenancy
  EOQ
}

# This can be shown as stacked bar for each tanancy?
query "oci_identity_user_by_type" {
  sql = <<-EOQ
    select
       user_type as "User Type",
       count(name)::numeric as "Users"
    from
      oci_identity_user
    group by
      user_type
    order by
      user_type
  EOQ
}

query "oci_identity_user_by_verified_email" {
  sql = <<-EOQ
    with verified_email_stat as (
      select
      name as name
      from
        oci_identity_user
      where
        email_verified
      )
      select
        'Verified' as "Email Verification Status",
        count(name) as "Users"
      from
        verified_email_stat
    union
    select
      'Unverified' as "Email Verification Status",
      count(name) as "Users"
    from
      oci_identity_user as s where s.name not in (select name from verified_email_stat);
  EOQ
}

// TO DO
# query "oci_identity_user_having_administrator_access" {
#   EOQ
# }


dashboard "oci_identity_user_dashboard" {

  title = "OCI Identity User Dashboard"

  container {

    card {
      sql   = query.oci_identity_user_count.sql
      width = 2
    }

    card {
      sql   = query.oci_identity_mfa_not_enabled_users_count.sql
      width = 2
    }

    card {
      sql   = query.oci_identity_user_unverified_email_count.sql
      width = 2
    }

    card {
      sql   = query.oci_identity_user_inactive_customer_key_count.sql
      width = 2
    }

    card {
      sql   = query.oci_identity_user_not_attached_to_groups.sql
      width = 2
    }

    card {
      sql   = query.oci_identity_user_access_key_age_gt_90_days.sql
      width = 2
    }

  }

  container {
    title = "Analysis"

    chart {
      title = "Users by Tenancy"
      sql   = query.oci_identity_users_by_tenancy.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "Users by Type"
      sql   = query.oci_identity_user_by_type.sql
      type  = "column"
      width = 4
    }

  }

  container {
    title = "Assesments"

    chart {
      title = "MFA Enabled Users by Tenancy"
      sql   = query.oci_identity_user_mfa_enabled_by_tenancy.sql
      type  = "donut"
      width = 4
    }

    chart {
      title = "Users by Verified Email"
      sql   = query.oci_identity_user_by_verified_email.sql
      type  = "donut"
      width = 4
    }

  }

  container {
    title = "Resources by Age"

    chart {
      title = "Users by Creation Month"
      sql   = query.oci_identity_users_by_creation_month.sql
      type  = "column"
      width = 4

      series "month" {
        color = "green"
      }
    }

    table {
      title = "Oldest Users"
      width = 4

      sql = <<-EOQ
        select
          u.name as "user",
          -- now() - time_created as "Age in Days",
          -- date_trunc('day',age(now(),time_created))::text as "Age in Days",
          current_date - time_created::date as "Age in Days",
          t.name as "tenancy"
        from
          oci_identity_user as u
          left join oci_identity_tenancy as t on u.tenant_id = t.id
        order by
          "Age in Days" desc,
          u.name
        limit 5
      EOQ
    }

    table {
      title = "Newest Users"
      width = 4

      sql = <<-EOQ
        select
          u.name as "user",
          -- now() - time_created as "Age in Days",
          -- date_trunc('day',age(now(),time_created))::text as "Age in Days",
          current_date - time_created::date as "Age in Days",
          t.name as "tenancy"
        from
          oci_identity_user as u
          left join oci_identity_tenancy as t on u.tenant_id = t.id
        order by
          "Age in Days" asc,
          u.name
        limit 5
      EOQ
    }
  }
}
