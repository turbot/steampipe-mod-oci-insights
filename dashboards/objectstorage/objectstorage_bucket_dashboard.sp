dashboard "oci_objectstorage_bucket_dashboard" {

  title         = "OCI Object Storage Bucket Dashboard"
  documentation = file("./dashboards/objectstorage/docs/objectstorage_bucket_dashboard.md")

  tags = merge(local.objectstorage_common_tags, {
    type = "Dashboard"
  })

  container {

    card {
      sql   = query.oci_objectstorage_bucket_count.sql
      width = 2
    }

    card {
      sql   = query.oci_objectstorage_bucket_read_only_access_count.sql
      width = 2
    }

    card {
      sql   = query.oci_objectstorage_bucket_default_encryption_count.sql
      width = 2
    }

    card {
      sql   = query.oci_objectstorage_bucket_archived_count.sql
      width = 2
    }

    card {
      sql   = query.oci_objectstorage_bucket_versioning_disabled_count.sql
      width = 2
    }

    card {
      sql   = query.oci_objectstorage_bucket_public_access_count.sql
      width = 2
    }

  }

  container {
    title = "Assessments"

    chart {
      title = "Versioning Status"
      sql   = query.oci_objectstorage_bucket_versioning_status.sql
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
      title = "Public Access"
      sql   = query.oci_objectstorage_bucket_public_access_status.sql
      type  = "donut"
      width = 3

      series "count" {
        point "enabled" {
          color = "alert"
        }
        point "disabled" {
          color = "ok"
        }
      }
    }

  }

  container {
    title = "Analysis"

    chart {
      title = "Buckets by Tenancy"
      sql   = query.oci_objectstorage_bucket_by_tenancy.sql
      type  = "column"
      width = 2
    }

    chart {
      title = "Buckets by Compartment"
      sql   = query.oci_objectstorage_bucket_by_compartment.sql
      type  = "column"
      width = 2
    }

    chart {
      title = "Buckets by Region"
      sql   = query.oci_objectstorage_bucket_by_region.sql
      type  = "column"
      width = 2
    }

    chart {
      title = "Buckets by Age"
      sql   = query.oci_objectstorage_bucket_by_creation_month.sql
      type  = "column"
      width = 2
    }

    chart {
      title = "Encryption by Type"
      sql   = query.oci_objectstorage_bucket_encryption_status.sql
      type  = "column"
      width = 2
    }
  }

}

# Card Queries

query "oci_objectstorage_bucket_count" {
  sql = <<-EOQ
    select count(*) as "Buckets" from oci_objectstorage_bucket;
  EOQ
}

query "oci_objectstorage_bucket_read_only_access_count" {
  sql = <<-EOQ
    select
      count(*) as "Read-Only Access"
    from
      oci_objectstorage_bucket
    where
      is_read_only;
  EOQ
}

query "oci_objectstorage_bucket_default_encryption_count" {
  sql = <<-EOQ
    select count(*) as "Oracle-Managed Encryption"
    from
      oci_objectstorage_bucket
    where
    kms_key_id is null;
  EOQ
}

query "oci_objectstorage_bucket_archived_count" {
  sql = <<-EOQ
    select count(*) as "Archived"
    from
      oci_objectstorage_bucket
    where
    storage_tier = 'Archive';
  EOQ
}

query "oci_objectstorage_bucket_public_access_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Public Access' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      oci_objectstorage_bucket
    where
      public_access_type <> 'NoPublicAccess';
  EOQ
}

query "oci_objectstorage_bucket_versioning_disabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Versioning Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      oci_objectstorage_bucket
    where
      versioning = 'Disabled';
  EOQ
}

# Assessment Queries

query "oci_objectstorage_bucket_versioning_status" {
  sql = <<-EOQ
    with versioning_stat as (
      select
        case
          when versioning = 'Disabled' then 'disabled'
          else 'enabled'
        end as versioning_stat
      from
        oci_objectstorage_bucket
    )
    select
      versioning_stat,
      count(*)
    from
      versioning_stat
    group by
      versioning_stat
  EOQ
}

query "oci_objectstorage_bucket_public_access_status" {
  sql = <<-EOQ
    with public_access_stat as (
      select
        case
          when public_access_type = 'NoPublicAccess' then 'disabled'
          else 'enabled'
        end as public_access_stat
      from
        oci_objectstorage_bucket
    )
    select
      public_access_stat,
      count(*)
    from
      public_access_stat
    group by
      public_access_stat
  EOQ
}

# Analysis Queries

query "oci_objectstorage_bucket_by_tenancy" {
  sql = <<-EOQ
   select
      t.title as "Tenancy",
      count(b.*) as "Buckets"
    from
      oci_objectstorage_bucket as b,
      oci_identity_tenancy as t
    where
      t.id = b.tenant_id
    group by
      t.title
    order by
      t.title;
  EOQ
}

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
      where
        lifecycle_state = 'ACTIVE'
        )
       )
    select
      t.title as "Tenancy",
      case when t.title = c.title then 'root' else c.title end as "Compartment",
      count(b.*) as "Keys"
    from
      oci_objectstorage_bucket as b,
      oci_identity_tenancy as t,
      compartments as c
    where
      c.id = b.compartment_id and b.tenant_id = t.id
    group by
      t.title,
      c.title
    order by
      t.title,
      c.title;
  EOQ
}

query "oci_objectstorage_bucket_by_region" {
  sql = <<-EOQ
    select region as "Region", count(*) as "Buckets"
    from
      oci_objectstorage_bucket
    group by
      region
    order by
      region;
  EOQ
}

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

query "oci_objectstorage_bucket_encryption_status" {
  sql = <<-EOQ
    select
      encryption_status,
      count(*)
    from (
      select
        id,
        case
         when kms_key_id is null then 'oracle-managed'
         else 'customer-managed'
         end as encryption_status
      from
        oci_objectstorage_bucket) as b
    group by
      encryption_status
    order by
      encryption_status desc;
  EOQ
}
