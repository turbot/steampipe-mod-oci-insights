dashboard "mysql_backup_dashboard" {

  title         = "OCI MySQL Backup Dashboard"
  documentation = file("./dashboards/mysql/docs/mysql_backup_dashboard.md")

  tags = merge(local.mysql_common_tags, {
    type = "Dashboard"
  })

  container {

    card {
      query = query.mysql_backup_count
      width = 3
    }

    card {
      query = query.mysql_backup_storage_total
      width = 3
    }

    card {
      query = query.mysql_automatic_backup_count
      width = 3
    }

    card {
      query = query.mysql_full_backup_count
      width = 3
    }

  }

  container {
    title = "Analysis"

    chart {
      title = "Backups by Tenancy"
      query = query.mysql_backup_by_tenancy
      type  = "column"
      width = 4
    }

    chart {
      title = "Backups by Compartment"
      query = query.mysql_backup_by_compartment
      type  = "column"
      width = 4
    }

    chart {
      title = "Backups by Region"
      query = query.mysql_backup_by_region
      type  = "column"
      width = 4
    }

    chart {
      title = "Backups by Age"
      query = query.mysql_backup_by_creation_month
      type  = "column"
      width = 4
    }

    chart {
      title = "Backups by Creation Type"
      query = query.mysql_backup_by_creation_type
      type  = "column"
      width = 4
    }

    chart {
      title = "Backups by Backup Type"
      query = query.mysql_backup_by_backup_type
      type  = "column"
      width = 4
    }

  }

  container {

    chart {
      title = "Storage by Tenancy (GB)"
      query = query.mysql_backup_storage_by_tenancy
      type  = "column"
      width = 4

      series "GB" {
        color = "tan"
      }
    }

    chart {
      title = "Storage by Compartment (GB)"
      query = query.mysql_backup_storage_by_compartment
      type  = "column"
      width = 4

      series "GB" {
        color = "tan"
      }
    }

    chart {
      title = "Storage by Region (GB)"
      query = query.mysql_backup_storage_by_region
      type  = "column"
      width = 4

      series "GB" {
        color = "tan"
      }
    }

    chart {
      title = "Storage by Age (GB)"
      query = query.mysql_backup_storage_by_creation_month
      type  = "column"
      width = 4

      series "GB" {
        color = "tan"
      }
    }

    chart {
      title = "Storage by Creation Type"
      query = query.mysql_backup_storage_by_creation_type
      type  = "column"
      width = 4

      series "GB" {
        color = "tan"
      }
    }

    chart {
      title = "Storage by Backup Type"
      query = query.mysql_backup_storage_by_backup_type
      type  = "column"
      width = 2

      series "GB" {
        color = "tan"
      }
    }

  }

}

# Card Queries

query "mysql_backup_count" {
  sql = <<-EOQ
  select
    count(*) as "Backups"
  from
    oci_mysql_backup
  where
    lifecycle_state <> 'DELETED';
  EOQ
}

query "mysql_automatic_backup_count" {
  sql = <<-EOQ
   select
      count(*) as "Automatic Backups"
    from
      oci_mysql_backup
    where
      creation_type = 'AUTOMATIC' and lifecycle_state <> 'DELETED';
  EOQ
}

query "mysql_backup_storage_total" {
  sql = <<-EOQ
    select
      sum(backup_size_in_gbs) as "Total Storage (GB)"
    from
      oci_mysql_backup
    where
      lifecycle_state <> 'DELETED';
  EOQ
}

query "mysql_full_backup_count" {
  sql = <<-EOQ
   select
      count(*) as "Full Backups"
    from
      oci_mysql_backup
    where
      backup_type = 'FULL' and lifecycle_state <> 'DELETED';
  EOQ
}

# Analysis Queries

query "mysql_backup_by_tenancy" {
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

query "mysql_backup_by_compartment" {
  sql = <<-EOQ
    with compartments as (
      select
        id,
        'root [' || title || ']' as title
      from
        oci_identity_tenancy
      union (
      select
        c.id,
        c.title || ' [' || t.title || ']' as title
      from
        oci_identity_compartment c,
        oci_identity_tenancy t
      where
        c.tenant_id = t.id and c.lifecycle_state = 'ACTIVE'
      )
    )
    select
      c.title as "Title",
      count(b.*) as "MySQL Backups"
    from
      oci_mysql_backup as b,
      compartments as c
    where
      c.id = b.compartment_id and b.lifecycle_state <> 'DELETED'
    group by
      c.title
    order by
      c.title;
  EOQ
}

query "mysql_backup_by_region" {
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

query "mysql_backup_by_creation_month" {
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

query "mysql_backup_by_creation_type" {
  sql = <<-EOQ
   select
      creation_type,
      count(*) as "MySQL Backups"
    from
      oci_mysql_backup
    where
      lifecycle_state <> 'DELETED'
    group by
      creation_type
    order by
      creation_type;
  EOQ
}

query "mysql_backup_by_backup_type" {
  sql = <<-EOQ
    select
      backup_type,
      count(*) as "MySQL Backups"
    from
      oci_mysql_backup
    where
      lifecycle_state <> 'DELETED'
    group by
      backup_type
    order by
      backup_type;
  EOQ
}

query "mysql_backup_storage_by_tenancy" {
  sql = <<-EOQ
    select
      t.title as "Tenancy",
      sum(backup_size_in_gbs) as "GB"
    from
      oci_mysql_backup as b,
      oci_identity_tenancy as t
    where
      t.id = b.tenant_id and lifecycle_state <> 'DELETED'
    group by
      t.title
    order by
      t.title;
  EOQ
}

query "mysql_backup_storage_by_compartment" {
  sql = <<-EOQ
    with compartments as (
      select
        id,
        'root [' || title || ']' as title
      from
        oci_identity_tenancy
      union (
      select
        c.id,
        c.title || ' [' || t.title || ']' as title
      from
        oci_identity_compartment c,
        oci_identity_tenancy t
      where
        c.tenant_id = t.id and c.lifecycle_state = 'ACTIVE'
      )
    )
    select
      c.title as "Title",
      sum(b.backup_size_in_gbs) as "GB"
    from
      oci_mysql_backup as b,
      compartments as c
    where
      c.id = b.compartment_id and b.lifecycle_state <> 'DELETED'
    group by
      c.title
    order by
      c.title;
  EOQ
}

query "mysql_backup_storage_by_region" {
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

query "mysql_backup_storage_by_creation_month" {
  sql = <<-EOQ
    with backups as (
      select
        title,
        backup_size_in_gbs,
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
        sum(backup_size_in_gbs) as size
      from
        backups
      group by
        creation_month
    )
    select
      months.month,
      backups_by_month.size as "GB"
    from
      months
      left join backups_by_month on months.month = backups_by_month.creation_month
    order by
      months.month;
  EOQ
}

query "mysql_backup_storage_by_creation_type" {
  sql = <<-EOQ
   select
      creation_type,
      sum(backup_size_in_gbs) as "GB"
    from
      oci_mysql_backup
    where
      lifecycle_state <> 'DELETED'
    group by
      creation_type
    order by
      creation_type;
  EOQ
}

query "mysql_backup_storage_by_backup_type" {
  sql = <<-EOQ
    select
      backup_type,
      sum(backup_size_in_gbs) as "GB"
    from
      oci_mysql_backup
    where
      lifecycle_state <> 'DELETED'
    group by
      backup_type
    order by
      backup_type;
  EOQ
}
