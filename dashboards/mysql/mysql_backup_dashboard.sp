query "oci_mysql_backup_count" {
  sql = <<-EOQ
  select
    count(*) as "Backups"
  from
    oci_mysql_backup
  where
    lifecycle_state <> 'DELETED';
  EOQ
}

query "oci_mysql_automatic_backup_count" {
  sql = <<-EOQ
   select
      count(*) as "Automatic Backups"
    from
      oci_mysql_backup
    where
      creation_type = 'AUTOMATIC' and lifecycle_state <> 'DELETED';
  EOQ
}

query "oci_mysql_backup_storage_total" {
  sql = <<-EOQ
    select
      sum(backup_size_in_gbs) as "Total Storage (GB)"
    from
      oci_mysql_backup
    where
      lifecycle_state <> 'DELETED';
  EOQ
}

query "oci_mysql_full_backup_count" {
  sql = <<-EOQ
   select
      count(*) as "Full Backups"
    from
      oci_mysql_backup
    where
      backup_type = 'FULL' and lifecycle_state <> 'DELETED';
  EOQ
}

query "oci_mysql_backup_failed_lifecycle_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Failed' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      oci_mysql_backup
    where
      lifecycle_state = 'FAILED';
  EOQ
}

# Assessments

# query "oci_mysql_backup_by_lifecycle_state" {
#   sql = <<-EOQ
#     select
#       lifecycle_state,
#       count(lifecycle_state)
#     from
#       oci_mysql_backup
#     where
#       lifecycle_state <> 'DELETED'
#     group by
#       lifecycle_state;
#   EOQ
# }

query "oci_mysql_backup_by_lifecycle_state" {
  sql = <<-EOQ
    with lifecycle_stat as (
      select
        case
          when lifecycle_state = 'FAILED' then 'failed'
          when lifecycle_state = 'INACTIVE' then 'inactive'
          when lifecycle_state = 'CREATING' then 'creating'
          when lifecycle_state = 'DELETING' then 'deleting'
          when lifecycle_state = 'UPDATING' then 'updating'
          else 'active'
        end as lifecycle_stat
      from
        oci_mysql_backup
      where lifecycle_state <> 'DELETED'
    )
      select
        lifecycle_stat,
        count(*)
      from
        lifecycle_stat
      group by
        lifecycle_stat
  EOQ
}

# Analysis

query "oci_mysql_backup_by_tenancy" {
  sql = <<-EOQ
    select
      c.title as "Tenancy",
      count(b.*) as "MySQL Backups"
    from
      oci_mysql_backup as b,
      oci_identity_tenancy as c
    where
      c.id = b.tenant_id and lifecycle_state <> 'DELETED'
    group by
      c.title
    order by
      c.title;
  EOQ
}

query "oci_mysql_backup_by_compartment" {
  sql = <<-EOQ
    with compartments as (
      select
        id, title
      from
        oci_identity_tenancy
      union (
      select
        id,title
      from
        oci_identity_compartment
      where
        lifecycle_state = 'ACTIVE'
        )
       )
    select
      b.title as "Tenancy",
      case when b.title = c.title then 'root' else c.title end as "Compartment",
      count(a.*) as "MySQL Backups"
    from
      oci_mysql_backup as a,
      oci_identity_tenancy as b,
      compartments as c
    where
      c.id = a.compartment_id and a.tenant_id = b.id and lifecycle_state <> 'DELETED'
    group by
      b.title,
      c.title
    order by
      b.title,
      c.title;
  EOQ
}

query "oci_mysql_backup_by_region" {
  sql = <<-EOQ
    select
      region as "Region",
      count(*) as "MySQL Backups"
    from
      oci_mysql_backup
    where
      lifecycle_state <> 'DELETED'
    group by
      region
    order by
      region;
  EOQ
}

query "oci_mysql_backup_by_creation_month" {
  sql = <<-EOQ
    with backups as (
      select
        display_name as name,
        time_created,
        to_char(time_created,
          'YYYY-MM') as creation_month
      from
        oci_mysql_backup
      where
      lifecycle_state <> 'DELETED'
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
                from backups)),
            date_trunc('month',
              current_date),
            interval '1 month') as d
    ),
    backups_by_month as (
      select
        creation_month,
        count(*)
      from
        backups
      group by
        creation_month
    )
    select
      months.month,
      backups_by_month.count
    from
      months
      left join backups_by_month on months.month = backups_by_month.creation_month
    order by
      months.month;
  EOQ
}

# Analysis Storage

query "oci_mysql_backup_storage_by_tenancy" {
  sql = <<-EOQ
    select
      c.title as "Tenancy",
      sum(backup_size_in_gbs) as "GB"
    from
      oci_mysql_backup as b,
      oci_identity_tenancy as c
    where
      c.id = b.tenant_id and lifecycle_state <> 'DELETED'
    group by
      c.title
    order by
      c.title;
  EOQ
}

query "oci_mysql_backup_storage_by_compartment" {
  sql = <<-EOQ
    with compartments as (
      select
        id, title
      from
        oci_identity_tenancy
      union (
      select
        id,title
      from
        oci_identity_compartment
      where
        lifecycle_state <> 'DELETED'
        )
      )
    select
      b.title as "Tenancy",
      case when b.title = c.title then 'root' else c.title end as "Compartment",
      sum(a.backup_size_in_gbs) as "GB"
    from
      oci_mysql_backup as a,
      oci_identity_tenancy as b,
      compartments as c
    where
      c.id = a.compartment_id and a.tenant_id = b.id and a.lifecycle_state <> 'DELETED'
    group by
      b.title,
      c.title
    order by
      b.title,
      c.title;

  EOQ
}

query "oci_mysql_backup_storage_by_region" {
  sql = <<-EOQ
    select
      region as "Region",
      sum(backup_size_in_gbs) as "GB"
    from
      oci_mysql_backup
    where
      lifecycle_state <> 'DELETED'
    group by
      region
    order by
      region;
  EOQ
}


dashboard "oci_mysql_backup_dashboard" {

  title = "OCI MySQL Backup Dashboard"

  tags = merge(local.mysql_common_tags, {
    type = "Dashboard"
  })

  container {

    card {
      sql   = query.oci_mysql_backup_count.sql
      width = 2
    }

    card {
      sql   = query.oci_mysql_backup_storage_total.sql
      width = 2
    }

    card {
      sql   = query.oci_mysql_automatic_backup_count.sql
      width = 2
    }

    card {
      sql   = query.oci_mysql_full_backup_count.sql
      width = 2
    }

    card {
      sql   = query.oci_mysql_backup_failed_lifecycle_count.sql
      width = 2
    }
  }

  container {
    title = "Assessments"
    width = 3

    chart {
      title = "Lifecycle State"
      sql   = query.oci_mysql_backup_by_lifecycle_state.sql
      type  = "donut"

      series "count" {
        point "active" {
          color = "green"
        }
        point "failed" {
          color = "red"
        }
      }
    }
  }

  container {
    title = "Analysis"

    chart {
      title = "Backups by Tenancy"
      sql   = query.oci_mysql_backup_by_tenancy.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Backups by Compartment"
      sql   = query.oci_mysql_backup_by_compartment.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Backups by Region"
      sql   = query.oci_mysql_backup_by_region.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Backups by Age"
      sql   = query.oci_mysql_backup_by_creation_month.sql
      type  = "column"
      width = 3
    }

  }

  container {

    chart {
      title = "Storage by Tenancy (GB)"
      sql   = query.oci_mysql_backup_storage_by_tenancy.sql
      type  = "column"
      width = 3

      series "GB" {
        color = "tan"
      }
    }

    chart {
      title = "Storage by Compartment (GB)"
      sql   = query.oci_mysql_backup_storage_by_compartment.sql
      type  = "column"
      width = 3

      series "GB" {
        color = "tan"
      }
    }

    chart {
      title = "Storage by Region (GB)"
      sql   = query.oci_mysql_backup_storage_by_region.sql
      type  = "column"
      width = 3

      series "GB" {
        color = "tan"
      }
    }

  }

}
