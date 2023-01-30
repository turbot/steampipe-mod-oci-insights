dashboard "kms_vault_dashboard" {

  title         = "OCI KMS Vault Dashboard"
  documentation = file("./dashboards/kms/docs/kms_vault_dashboard.md")

  tags = merge(local.kms_common_tags, {
    type = "Dashboard"
  })

  container {

    card {
      query = query.kms_vault_count
      width = 3
    }

    card {
      query = query.kms_vault_disabled_count
      width = 3
    }

  }

  container {
    title = "Assessments"

    chart {
      title = "Lifecycle State"
      query = query.kms_vault_lifecycle_state
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
      title = "Vaults by Type"
      query = query.kms_vault_by_type
      type  = "column"
      width = 4
    }

    chart {
      title = "Vaults by Tenancy"
      query = query.kms_vault_by_tenancy
      type  = "column"
      width = 4
    }

    chart {
      title = "Vaults by Compartment"
      query = query.kms_vault_by_compartment
      type  = "column"
      width = 4
    }


    chart {
      title = "Vaults by Region"
      query = query.kms_vault_by_region
      type  = "column"
      width = 4
    }

    chart {
      title = "Vaults by Age"
      query = query.kms_vault_by_creation_month
      type  = "column"
      width = 4
    }

  }

}

# Card Queries

query "kms_vault_count" {
  sql = <<-EOQ
    select count(*) as "Vaults" from oci_kms_vault;
  EOQ
}

query "kms_vault_disabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Disabled Vaults' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      oci_kms_vault
    where
      lifecycle_state = 'DELETED';
  EOQ
}

# # Assessment Queries

query "kms_vault_lifecycle_state" {
  sql = <<-EOQ
    select
      case when lifecycle_state = 'DISABLED' then 'disabled' else 'enabled' end as status,
      count(*)
    from
      oci_kms_vault
    where
      lifecycle_state <> 'DELETED'
    group by
      status;
  EOQ
}

# # Analysis Queries

query "kms_vault_by_type" {
  sql = <<-EOQ
    select
      vault_type,
      count(k.*) as total
    from
      oci_kms_vault as k
    group by
      vault_type;
  EOQ
}

query "kms_vault_by_tenancy" {
  sql = <<-EOQ
    select
       t.name as "Tenancy",
       count(k.id)::numeric as "Keys"
    from
      oci_kms_vault as k,
      oci_identity_tenancy as t
    where
      t.id = k.tenant_id
    group by
      t.name
    order by
      t.name;
  EOQ
}

query "kms_vault_by_compartment" {
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
      oci_kms_vault as k,
      compartments as c
    where
      c.id = k.compartment_id
    group by
      c.title
    order by
      c.title;
  EOQ
}

query "kms_vault_by_region" {
  sql = <<-EOQ
    select
      region,
      count(k.*) as total
    from
      oci_kms_vault as k
    group by
      region;
  EOQ
}

query "kms_vault_by_creation_month" {
  sql = <<-EOQ
    with vaults as (
      select
        title,
        time_created,
        to_char(time_created,
          'YYYY-MM') as creation_month
      from
        oci_kms_vault
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
                from vaults)),
            date_trunc('month',
              current_date),
            interval '1 month') as d
    ),
    vaults_by_month as (
      select
        creation_month,
        count(*)
      from
        vaults
      group by
        creation_month
    )
    select
      months.month,
      vaults_by_month.count
    from
      months
      left join vaults_by_month on months.month = vaults_by_month.creation_month
    order by
      months.month desc;
  EOQ
}
