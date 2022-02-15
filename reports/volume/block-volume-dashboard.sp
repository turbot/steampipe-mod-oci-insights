query "oci_block_volume_count" {
  sql = <<-EOQ
    select count(*) as "Block Volumes" from oci_core_volume where lifecycle_state <> 'DELETED'
  EOQ
}

query "oci_block_volume_storage_total" {
  sql = <<-EOQ
    select
      sum(size_in_gbs) as "Total Storage in GBs"
    from
      oci_core_volume
    where
      lifecycle_state <> 'DELETED'  
  EOQ
}

query "oci_block_volume_default_encrypted_volumes_count" {
  sql = <<-EOQ
    select
      count(*) as "OCI Managed Encryption"
    from 
      oci_core_volume 
    where 
      kms_key_id is null and lifecycle_state <> 'DELETED'
  EOQ
}

query "oci_block_volume_unattached_volumes_count" {
  sql = <<-EOQ
   select
      count(*) as value,
      'Unattached Block Volumes' as label,
      case count(*) when 0 then 'ok' else 'alert' end as style
    from 
      oci_core_volume
    where 
      id not in (
        select 
          volume_id
        from
          oci_core_volume_attachment  
      ) and lifecycle_state <> 'DELETED'
  EOQ
}

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
      count(v.*) as "Block volumes" 
    from 
      oci_core_volume as v,
      compartments as c 
    where 
      c.id = v.compartment_id and v.lifecycle_state <> 'DELETED'
    group by 
      compartment
    order by 
      compartment
  EOQ
}

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
      c.id = v.compartment_id and v.lifecycle_state <> 'DELETED'
    group by 
      compartment
    order by 
      compartment
  EOQ
}

query "oci_block_volume_by_region" {
  sql = <<-EOQ
    select
      region as "Region",
      count(*) as "Volumes"
    from
      oci_core_volume
    where
      lifecycle_state <> 'DELETED'  
    group by
      region
  EOQ
}

query "oci_block_volume_storage_by_region" {
  sql = <<-EOQ
    select
      region as "Region",
      sum(size_in_gbs) as "Total storage in GB"
    from
      oci_core_volume
    where
      lifecycle_state <> 'DELETED'    
    group by
      region
  EOQ
}


query "oci_block_volume_by_lifecycle_state" {
  sql = <<-EOQ
    select
      lifecycle_state,
      count(lifecycle_state)
    from
      oci_core_volume
    where
      lifecycle_state <> 'DELETED'    
    group by
      lifecycle_state
  EOQ
}


query "oci_block_volume_by_encryption_status" {
  sql = <<-EOQ
    select
      encryption_status,
      count(*)
    from (
      select
        id,
        case 
         when kms_key_id is null then 'OCI Managed Encryption' 
         else 'Customer Managed Encryption' 
         end as encryption_status
      from
        oci_core_volume
      where
      lifecycle_state <> 'DELETED') as v
    group by
      encryption_status
    order by
      encryption_status desc
  EOQ
}


query "oci_block_volumes_with_no_backups" {
  sql = <<-EOQ
    select
      v.id,
      v.compartment_id,
      v.region
    from
      oci_core_volume as v
    left join oci_core_volume_backup as b on v.id = b.volume_id
    where 
      v.lifecycle_state <> 'DELETED'
    group by
      v.compartment_id,
      v.region,
      v.id  
    having
      count(b.id) = 0
  EOQ
}

query "oci_block_volume_by_creation_month" {
  sql = <<-EOQ
    with volumes as (
      select
        title,
        time_created,
        to_char(time_created,
          'YYYY-MM') as creation_month
      from
        oci_core_volume
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

report "oci_block_volume_dashboard" {

  title = "OCI Block Volume Dashboard"

  container {
    ## Analysis ...

    card {
      sql = query.oci_block_volume_count.sql
      width = 2
    }

    card {
      sql = query.oci_block_volume_storage_total.sql
      width = 2
    }

    card {
      sql = query.oci_block_volume_default_encrypted_volumes_count.sql
      width = 2
    }

    card {
      sql = query.oci_block_volume_unattached_volumes_count.sql
      width = 2
    }
  }

  container {
      title = "Analysis"      

    chart {
      title = "Block Volumes by Compartment"
      sql = query.oci_block_volume_by_compartment.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Block Volumes by Region"
      sql = query.oci_block_volume_by_region.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Block Volumes Storage by Compartment (GB)"
      sql = query.oci_block_volume_storage_by_compartment.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Block Volumes Storage by Region (GB)"
      sql = query.oci_block_volume_storage_by_region.sql
      type  = "column"
      width = 3
    }
  }

  container {
      title = "Assessments"

      chart {
        title = "Encryption Status"
        sql = query.oci_block_volume_by_encryption_status.sql
        type  = "donut"
        width = 3

        series "Enabled" {
           color = "green"
        }
      }

      chart {
        title = "Block Volumes Lifecycle State"
        sql = query.oci_block_volume_by_lifecycle_state.sql
        type  = "donut"
        width = 3

      }

       table {
         title = "Block Volumes with no backups"
         sql = query.oci_block_volumes_with_no_backups.sql
         width = 3
       }
    }

  container {
    title = "Resources by Age" 

    chart {
      title = "Block Volume by Creation Month"
      sql = query.oci_block_volume_by_creation_month.sql
      type  = "column"
      width = 4
      series "month" {
        color = "green"
      }
    }

    table {
      title = "Oldest Block Volumes"
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
      title = "Newest Block volumes"
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
          "Age in Days" asc,
          title
        limit 5
      EOQ
    }

  }

}