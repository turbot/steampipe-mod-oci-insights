query "oci_kms_key_count" {
  sql = <<-EOQ
    select count(*) as "KMS Keys" from oci_kms_key
  EOQ
}

# key count by protection_mode i.e. HSM or Software
query "oci_kms_hsm_key_count" {
  sql = <<-EOQ
    select count(*) as "KMS HSM Based Keys" from oci_kms_key where protection_mode = 'HSM' and lifecycle_state <> 'DELETED'
  EOQ
}

query "oci_kms_software_key_count" {
  sql = <<-EOQ
    select count(*) as "KMS Software Based Keys" from oci_kms_key where protection_mode = 'SOFTWARE' and lifecycle_state <> 'DELETED'
  EOQ
}

query "oci_kms_key_by_type" {
  sql = <<-EOQ
    select
      protection_mode,
      count(protection_mode)
    from
      oci_kms_key
    group by
      protection_mode
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
      where lifecycle_state = 'ACTIVE')
    )
   select
      c.title as "compartment",
      count(k.*) as "keys"
    from
      oci_kms_key as k,
      compartments as c
    where
      c.id = k.compartment_id and k.lifecycle_state <> 'DELETED'
    group by
      compartment
    order by
      compartment
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
      region
  EOQ
}

query "oci_kms_key_by_state" {
  sql = <<-EOQ
    select
      lifecycle_state,
      count(lifecycle_state)
    from
      oci_kms_key
    group by
      lifecycle_state
  EOQ
}

query "oci_kms_key_pending_deletion" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Pending Deletion' as label,
      case count(*) when 0 then 'ok' else 'alert' end as style
    from
      oci_kms_key
    where
      lifecycle_state = 'PENDING_DELETION'
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

report "oci_kms_key_summary" {

  title = "OCI KMS Key Dashboard"

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
      sql   = query.oci_kms_software_key_count.sql
      width = 2
    }

    card {
      sql   = query.oci_kms_key_pending_deletion.sql
      width = 2
    }

  }

  container {
    title = "Analysis"


    chart {
      title = "KMS Keys by Account"
      sql   = query.oci_kms_key_by_compartment.sql
      type  = "column"
      width = 3
    }


    chart {
      title = "KMS Keys by Region"
      sql   = query.oci_kms_key_by_region.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "KMS Keys by State"
      sql   = query.oci_kms_key_by_state.sql
      type  = "column"
      width = 3
    }

    # chart {
    #   title = "KMS Keys Pending Deletion"
    #   sql   = query.oci_kms_key_pending_deletion.sql
    #   type  = "column"
    #   width = 3
    # }

  }

  container {
    title = "Resources by Age"

    chart {
      title = "KMS Keys by Creation Month"
      sql   = query.oci_kms_key_by_creation_month.sql
      type  = "column"
      width = 4

      series "month" {
        color = "green"
      }
    }

    table {
      title = "KMS Keys To Be Deleted within 7 days"
      width = 4
      sql = <<-EOQ
        with compartments as (
          select
            id,
            title
          from
            oci_identity_tenancy
          union (
          select
            id,
            title
          from
            oci_identity_compartment
          where lifecycle_state = 'ACTIVE')
        )
        select
          b.title as "key",
          (time_of_deletion - current_date) as "Age in Days",
          c.title as "Compartment"
        from
          oci_kms_key as b
          left join compartments as c on c.id = b.Compartment_id
        where
          extract(day from time_of_deletion - current_date) <= 7
        order by
          "Age in Days" desc,
          b.title
        limit 5
      EOQ
    }
  }

}
