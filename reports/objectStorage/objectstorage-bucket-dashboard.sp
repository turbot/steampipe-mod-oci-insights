# Added to report
query "oci_objectstorage_bucket_count" {
  sql = <<-EOQ
    select count(*) as "Buckets" from oci_objectstorage_bucket
  EOQ
}

# Added to report
query "oci_objectstorage_bucket_read_only_access_count" {
  sql = <<-EOQ
    select
      count(*) as "Read Only Access"
    from
      oci_objectstorage_bucket
    where
      is_read_only  
  EOQ
}

# Added to report
query "oci_objectstorage_bucket_public_access_blocked_count" {
  sql = <<-EOQ
    select
      count(*) as "Public Access Blocked"
    from
      oci_objectstorage_bucket
    where
      public_access_type = 'NoPublicAccess'  
  EOQ
}

# Added to report
query "oci_objectstorage_bucket_versioning_disabled_count" {
  sql = <<-EOQ
    select count(*) as "Versioned Disabled"
    from 
      oci_objectstorage_bucket 
    where 
      versioning = 'Disabled'
  EOQ
}

# Added to report
query "oci_objectstorage_bucket_unencrypted_count" {
  sql = <<-EOQ
    select count(*) as "Unencrypted"
    from 
      oci_objectstorage_bucket 
    where 
    kms_key_id is null
  EOQ
}

# Added to report
query "oci_objectstorage_bucket_archived_count" {
  sql = <<-EOQ
    select count(*) as "Archive"
    from 
      oci_objectstorage_bucket 
    where 
    storage_tier = 'Archive'
  EOQ
}

# Added to report
query "oci_objectstorage_bucket_by_region" {
  sql = <<-EOQ
    select region as "Region", count(*) as "Buckets" 
    from 
      oci_objectstorage_bucket 
    group by 
      region 
    order by 
      region
  EOQ
}

# Added to report
query "oci_objectstorage_bucket_by_compartment" {
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
      count(b.*) as "buckets" 
    from 
      oci_objectstorage_bucket as b,
      compartments as c 
    where 
      c.id = b.compartment_id
    group by 
      compartment
    order by 
      compartment
  EOQ
}

#Added to report
query "oci_objectstorage_bucket_encryption_status" {
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
        oci_objectstorage_bucket) as b
    group by
      encryption_status
    order by
      encryption_status desc
  EOQ
}

# Added
query "oci_objectstorage_bucket_by_creation_month" {
  sql = <<-EOQ
    with buckets as (
      select
        name,
        time_created,
        to_char(time_created,
          'YYYY-MM') as creation_month
      from
        oci_objectstorage_bucket
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
                from buckets)),
            date_trunc('month',
              current_date),
            interval '1 month') as d
    ),
    buckets_by_month as (
      select
        creation_month,
        count(*)
      from
        buckets
      group by
        creation_month
    )
    select
      months.month,
      buckets_by_month.count
    from
      months
      left join buckets_by_month on months.month = buckets_by_month.creation_month
    order by
      months.month;
  EOQ
}

report "oci_objectstorage_bucket_dashboard" {

  title = "OCI ObjectStorage Bucket Dashboard"

  container {
    ## Analysis ...

    card {
      sql = query.oci_objectstorage_bucket_count.sql
      width = 2
    }

    card {
      sql = query.oci_objectstorage_bucket_read_only_access_count.sql
      width = 2
    }

    card {
      sql = query.oci_objectstorage_bucket_public_access_blocked_count.sql
      width = 2
    }

    card {
      sql = query.oci_objectstorage_bucket_versioning_disabled_count.sql
      width = 2
    }

    card {
      sql = query.oci_objectstorage_bucket_unencrypted_count.sql
      width = 2
    }

    card {
      sql = query.oci_objectstorage_bucket_archived_count.sql
      width = 2
    }
  }

  container {
      title = "Analysis"      

    chart {
      title = "Buckets by Compartment"
      sql = query.oci_objectstorage_bucket_by_compartment.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Buckets by Region"
      sql = query.oci_objectstorage_bucket_by_region.sql
      type  = "column"
      width = 3
    }
  }

    # donut charts in a 2 x 2 layout
    container {
      title = "Assessments"

      chart {
        title = "Encryption Status"
        sql = query.oci_objectstorage_bucket_encryption_status.sql
        type  = "donut"
        width = 3

        series "Enabled" {
           color = "green"
        }
      }
    }

  container {
    title = "Resources by Age" 

    chart {
      title = "Bucket by Creation Month"
      sql = query.oci_objectstorage_bucket_by_creation_month.sql
      type  = "column"
      width = 4
      series "month" {
        color = "green"
      }
    }

    table {
      title = "Oldest buckets"
      width = 4

      sql = <<-EOQ
        select
          title as "bucket",
          current_date - time_created::date as "Age in Days",
          compartment_id as "Compartment"
        from
          oci_objectstorage_bucket
        order by
          "Age in Days" desc,
          title
        limit 5
      EOQ
    }

    table {
      title = "Newest buckets"
      width = 4

      sql = <<-EOQ
        select
          title as "bucket",
          current_date - time_created::date as "Age in Days",
          compartment_id as "Compartment"
        from
          oci_objectstorage_bucket
        order by
          "Age in Days" asc,
          title
        limit 5
      EOQ
    }

  }

}