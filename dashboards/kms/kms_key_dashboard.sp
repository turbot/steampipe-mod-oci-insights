dashboard "oci_kms_key_dashboard" {

  title         = "OCI KMS Key Dashboard"
  documentation = file("./dashboards/kms/docs/kms_key_dashboard.md")

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
        point "ok" {
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
      title = "Keys by Tenancy"
      sql   = query.oci_kms_key_by_tenancy.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "Keys by Compartment"
      sql   = query.oci_kms_key_by_compartment.sql
      type  = "column"
      width = 4
    }


    chart {
      title = "Keys by Region"
      sql   = query.oci_kms_key_by_region.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "Keys by Age"
      sql   = query.oci_kms_key_by_creation_month.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "Keys by Protection Mode"
      sql   = query.oci_kms_key_by_protection_mode.sql
      type  = "column"
      width = 4
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

# Assessment Queries

query "oci_kms_key_lifecycle_state" {
  sql = <<-EOQ
    select
      case when lifecycle_state = 'DISABLED' then 'disabled' else 'ok' end as status,
      count(*)
    from
      oci_kms_key
    where
      lifecycle_state <> 'DELETED'
    group by
      status;
  EOQ
}

# Analysis Queries

query "oci_kms_key_by_tenancy" {
  sql = <<-EOQ
    select
       t.name as "Tenancy",
       count(k.id)::numeric as "Keys"
    from
      oci_kms_key as k,
      oci_identity_tenancy as t
    where
      t.id = k.tenant_id
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
      count(k.*) as "Keys"
    from
      oci_kms_key as k,
      compartments as c
    where
      c.id = k.compartment_id
    group by
      c.title
    order by
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

query "oci_kms_key_by_protection_mode" {
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

