# Added to report
query "oci_block_volume_count" {
  sql = <<-EOQ
    select count(*) as "Volumes" from oci_core_volume
  EOQ
}

# Added to report
query "oci_block_volume_storage_total" {
  sql = <<-EOQ
    select
      sum(size_in_gbs) as "Total Storage in GBs"
    from
      oci_core_volume
  EOQ
}

# Added to report
query "oci_block_volume_customer_managed_encrypted_volumes_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Unencrypted Volumes' as label,
      case count(*) when 0 then 'ok' else 'alert' end as style
    from 
      oci_core_volume 
    where 
      kms_key_id is null
  EOQ
}

# Added to report
query "oci_block_volume_unattached_volumes_count" {
  sql = <<-EOQ
   select
      count(*) as value,
      'Unencrypted Volumes' as label,
      case count(*) when 0 then 'ok' else 'alert' end as style
    from 
      oci_core_volume
    where 
      id not in (
        select 
          volume_id
        from
          oci_core_volume_attachment  
      )
  EOQ
}

# Added to report
query "oci_block_volume_by_compartment" {
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
      count(v.*) as "volumes" 
    from 
      oci_core_volume as v,
      compartments as c 
    where 
      c.id = v.compartment_id
    group by 
      compartment
    order by 
      compartment
  EOQ
}

# Added to report
query "oci_block_volume_storage_by_compartment" {
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
      sum(v.size_in_gbs) as "Total Storage in GB" 
    from 
      oci_core_volume as v,
      compartments as c 
    where 
      c.id = v.compartment_id
    group by 
      compartment
    order by 
      compartment
  EOQ
}

#Added to report
query "oci_block_volume_by_region" {
  sql = <<-EOQ
    select
      region as "Region",
      count(*) as "Volumes"
    from
      oci_core_volume
    group by
      region
  EOQ
}

#Added to report
query "oci_block_volume_storage_by_region" {
  sql = <<-EOQ
    select
      region as "Region",
      sum(size_in_gbs) as "Total storage in GB"
    from
      oci_core_volume
    group by
      region
  EOQ
}

#Added to report
query "oci_block_volume_by_state" {
  sql = <<-EOQ
    select
      lifecycle_state,
      count(lifecycle_state)
    from
      oci_core_volume
    group by
      lifecycle_state
  EOQ
}

#Added to report
query "oci_block_volume_by_customer_managed_encryption_status" {
  sql = <<-EOQ
    select
      encryption_status,
      count(*)
    from (
      select
        id,
        case 
         when kms_key_id is null then 'Disabled' 
         else 'Enabled' 
         end as encryption_status
      from
        oci_core_volume) as v
    group by
      encryption_status
    order by
      encryption_status desc
  EOQ
}

#Added to report
query "oci_block_volumes_with_no_backups" {
  sql = <<-EOQ
    select
      v.id,
      v.compartment_id,
      v.region
    from
      oci_core_volume as v
    left join oci_core_volume_backup as b on v.id = b.volume_id
    group by
      v.compartment_id,
      v.region,
      v.id
    having
      count(b.id) = 0
  EOQ
}

# Added
query "oci_core_volume_by_creation_month" {
  sql = <<-EOQ
    with volumes as (
      select
        title,
        time_created,
        to_char(time_created,
          'YYYY-MM') as creation_month
      from
        oci_core_volume
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
                from volumes)),
            date_trunc('month',
              current_date),
            interval '1 month') as d
    ),
    volumes_by_month as (
      select
        creation_month,
        count(*)
      from
        volumes
      group by
        creation_month
    )
    select
      months.month,
      volumes_by_month.count
    from
      months
      left join volumes_by_month on months.month = volumes_by_month.creation_month
    order by
      months.month
  EOQ
}

report "oci_core_volume_dashboard" {

  title = "OCI Core Volume Dashboard"

  container {
    ## Analysis ...

    counter {
      sql = query.oci_block_volume_count.sql
      width = 2
    }

    counter {
      sql = query.oci_block_volume_storage_total.sql
      width = 2
    }

    counter {
      sql = query.oci_block_volume_customer_managed_encrypted_volumes_count.sql
      width = 2
    }

    counter {
      sql = query.oci_block_volume_unattached_volumes_count.sql
      width = 2
    }
  }

  container {
      title = "Analysis"      

    chart {
      title = "Volumes by Compartment"
      sql = query.oci_block_volume_by_compartment.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Volumes by Region"
      sql = query.oci_block_volume_by_region.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Volume Storage by Compartment (GB)"
      sql = query.oci_block_volume_storage_by_compartment.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Volume Storage by Region (GB)"
      sql = query.oci_block_volume_storage_by_region.sql
      type  = "column"
      width = 3
    }
  }

    # donut charts in a 2 x 2 layout
    container {
      title = "Assessments"

      chart {
        title = "Encryption Status"
        sql = query.oci_block_volume_by_customer_managed_encryption_status.sql
        type  = "donut"
        width = 3

        series "Enabled" {
           color = "green"
        }
      }

      chart {
        title = "Volume State"
        sql = query.oci_block_volume_by_state.sql
        type  = "donut"
        width = 3

      }

       table {
         title = "Volumes with no backups"
         sql = query.oci_block_volumes_with_no_backups.sql
         width = 3
       }
    }

  container {
    title = "Resources by Age" 

    chart {
      title = "Volume by Creation Month"
      sql = query.oci_core_volume_by_creation_month.sql
      type  = "column"
      width = 4
      series "month" {
        color = "green"
      }
    }

    table {
      title = "Oldest volumes"
      width = 4

      sql = <<-EOQ
        select
          title as "volume",
          current_date - time_created::date as "Age in Days",
          compartment_id as "Compartment"
        from
          oci_core_volume
        where lifecycle_state <> 'DELETED'
        order by
          "Age in Days" desc,
          title
        limit 5
      EOQ
    }

    table {
      title = "Newest volumes"
      width = 4

      sql = <<-EOQ
        select
          title as "volume",
          current_date - time_created::date as "Age in Days",
          compartment_id as "Compartment"
        from
          oci_core_volume
        order by
          "Age in Days" asc,
          title
        limit 5
      EOQ
    }

  }

}