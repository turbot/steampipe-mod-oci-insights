dashboard "oci_kms_key_dashboard" {

  title = "OCI KMS Key Dashboard"

  tags = merge(local.kms_common_tags, {
    type = "Dashboard"
  })

  container {

    card {
      sql   = query.oci_kms_key_count.sql
      width = 2
    }

    card {
      sql   = query.oci_kms_hsm_key_count.sql
      width = 2
      type  = "info"
    }

    card {
      sql   = query.oci_kms_software_key_count.sql
      width = 2
      type  = "info"
    }

    card {
      sql   = query.oci_kms_key_disabled_count.sql
      width = 2
    }

  }

  container {
    title = "Assessments"

    chart {
      title = "Lifecycle State"
      sql   = query.oci_kms_key_lifecycle_state.sql
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

    chart {
      title = "Protection Mode"
      sql   = query.oci_database_autonomous_db_by_protection_mode.sql
      type  = "donut"
      width = 3
    }

  }

  container {
    title = "Analysis"

    chart {
      title = "Keys by Tenancy"
      sql   = query.oci_kms_key_by_tenancy.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Keys by Compartment"
      sql   = query.oci_kms_key_by_compartment.sql
      type  = "column"
      width = 3
    }


    chart {
      title = "Keys by Region"
      sql   = query.oci_kms_key_by_region.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Keys by Age"
      sql   = query.oci_kms_key_by_creation_month.sql
      type  = "column"
      width = 3
    }

  }

}

# Card Queries

query "oci_kms_key_count" {
  sql = <<-EOQ
    select count(*) as "Keys" from oci_kms_key;
  EOQ
}

query "oci_kms_key_disabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Disabled Keys' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      oci_kms_key
    where
      lifecycle_state = 'DISABLED';
  EOQ
}

# Key count by protection_mode i.e. HSM or Software
query "oci_kms_hsm_key_count" {
  sql = <<-EOQ
    select count(*) as "HSM Based Keys" from oci_kms_key where protection_mode = 'HSM' and lifecycle_state <> 'DELETED';
  EOQ
}

query "oci_kms_software_key_count" {
  sql = <<-EOQ
    select count(*) as "Software Based Keys" from oci_kms_key where protection_mode = 'SOFTWARE' and lifecycle_state <> 'DELETED';
  EOQ
}

# Assessment Queries

# query "oci_kms_key_lifecycle_state" {
#   sql = <<-EOQ
#       with lifecycles as (
#         select
#           lifecycle_state
#         from
#           oci_kms_key
#         where lifecycle_state IN ('PENDING_DELETION','DISABLED','ENABLED')
#         )
#         select
#           lifecycle_state,
#           count(lifecycle_state)
#         from
#           lifecycles
#         group by
#           lifecycle_state;
#   EOQ
# }

query "oci_kms_key_lifecycle_state" {
  sql = <<-EOQ
    with lifecycle_stat as (
      select
        case
          when lifecycle_state = 'DISABLED' then 'disabled'
          when lifecycle_state = 'PENDING_DELETION' then 'pending_deletion'
          when lifecycle_state = 'ENABLING' then 'enabling'
          when lifecycle_state = 'CREATING' then 'creating'
          when lifecycle_state = 'DISABLING' then 'disabling'
          when lifecycle_state = 'DELETING' then 'deleting'
          when lifecycle_state = 'SCHEDULING_DELETION' then 'scheduling_deletion'
          when lifecycle_state = 'CANCELLING_DELETION' then 'cancelling_deletion'
          when lifecycle_state = 'UPDATING' then 'updating'
          when lifecycle_state = 'BACKUP_IN_PROGRESS' then 'backup_in_progress'
          when lifecycle_state = 'RESTORING' then 'restoring'
          else 'enabled'
        end as lifecycle_stat
      from
        oci_kms_key
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

query "oci_database_autonomous_db_by_protection_mode" {
  sql = <<-EOQ
    select
      protection_mode,
      count(protection_mode)
    from
      oci_kms_key
    group by
      protection_mode;
  EOQ
}

# Analysis Queries

query "oci_kms_key_by_tenancy" {
  sql = <<-EOQ
    select
       t.name as "Tenancy",
       count(a.id)::numeric as "Keys"
    from
      oci_kms_key as a,
      oci_identity_tenancy as t
    where
      t.id = a.tenant_id
    group by
      t.name
    order by
      t.name;
  EOQ
}

query "oci_kms_key_by_compartment" {
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
      count(a.*) as "Keys"
    from
      oci_kms_key as a,
      oci_identity_tenancy as b,
      compartments as c
    where
      c.id = a.compartment_id and a.tenant_id = b.id
    group by
      b.title,
      c.title
    order by
      b.title,
      c.title;
  EOQ
}

query "oci_kms_key_by_region" {
  sql = <<-EOQ
    select
      region,
      count(k.*) as total
    from
      oci_kms_key as k
    group by
      region;
  EOQ
}

query "oci_kms_key_by_creation_month" {
  sql = <<-EOQ
    with keys as (
      select
        title,
        time_created,
        to_char(time_created,
          'YYYY-MM') as creation_month
      from
        oci_kms_key
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
                from keys)),
            date_trunc('month',
              current_date),
            interval '1 month') as d
    ),
    keys_by_month as (
      select
        creation_month,
        count(*)
      from
        keys
      group by
        creation_month
    )
    select
      months.month,
      keys_by_month.count
    from
      months
      left join keys_by_month on months.month = keys_by_month.creation_month
    order by
      months.month desc;
  EOQ
}
