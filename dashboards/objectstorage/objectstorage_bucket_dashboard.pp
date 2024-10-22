dashboard "objectstorage_bucket_dashboard" {

  title         = "OCI Object Storage Bucket Dashboard"
  documentation = file("./dashboards/objectstorage/docs/objectstorage_bucket_dashboard.md")

  tags = merge(local.objectstorage_common_tags, {
    type = "Dashboard"
  })

  container {

    card {
      query = query.objectstorage_bucket_count
      width = 2
    }

    card {
      query = query.objectstorage_bucket_read_only_access_count
      width = 2
    }

    card {
      query = query.objectstorage_bucket_archived_count
      width = 2
    }

    card {
      query = query.objectstorage_bucket_public_access_count
      width = 2
      href  = dashboard.objectstorage_bucket_public_access_report.url_path
    }

    card {
      query = query.objectstorage_bucket_versioning_disabled_count
      width = 2
      href  = dashboard.objectstorage_bucket_lifecycle_report.url_path
    }

    card {
      query = query.objectstorage_bucket_logging_disabled_count
      width = 2
      href  = dashboard.objectstorage_bucket_logging_report.url_path
    }

  }

  container {
    title = "Assessments"

    chart {
      title = "Public Access"
      query = query.objectstorage_bucket_public_access_status
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

    chart {
      title = "Versioning Status"
      query = query.objectstorage_bucket_versioning_status
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
      title = "Logging Status"
      query = query.objectstorage_bucket_logging_status
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

  }

  container {
    title = "Analysis"

    chart {
      title = "Buckets by Tenancy"
      query = query.objectstorage_bucket_by_tenancy
      type  = "column"
      width = 4
    }

    chart {
      title = "Buckets by Compartment"
      query = query.objectstorage_bucket_by_compartment
      type  = "column"
      width = 4
    }

    chart {
      title = "Buckets by Region"
      query = query.objectstorage_bucket_by_region
      type  = "column"
      width = 4
    }

    chart {
      title = "Buckets by Age"
      query = query.objectstorage_bucket_by_creation_month
      type  = "column"
      width = 4
    }

    chart {
      title = "Buckets by Encryption Type"
      query = query.objectstorage_bucket_encryption_status
      type  = "column"
      width = 4
    }
  }

}

# Card Queries

query "objectstorage_bucket_count" {
  sql = <<-EOQ
    select count(*) as "Buckets" from oci_objectstorage_bucket;
  EOQ
}

query "objectstorage_bucket_read_only_access_count" {
  sql = <<-EOQ
    select
      count(*) as "Read-Only Access"
    from
      oci_objectstorage_bucket
    where
      is_read_only;
  EOQ
}

query "objectstorage_bucket_default_encryption_count" {
  sql = <<-EOQ
    select count(*) as "Oracle-Managed Encryption"
    from
      oci_objectstorage_bucket
    where
    kms_key_id is null;
  EOQ
}

query "objectstorage_bucket_archived_count" {
  sql = <<-EOQ
    select count(*) as "Archived"
    from
      oci_objectstorage_bucket
    where
    storage_tier = 'Archive';
  EOQ
}

query "objectstorage_bucket_public_access_count" {
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

query "objectstorage_bucket_versioning_disabled_count" {
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

query "objectstorage_bucket_logging_disabled_count" {
  sql = <<-EOQ
    with name_with_region as (
      select
        concat(configuration -> 'source' ->> 'resource', region) as name_with_region,
        is_enabled
      from
        oci_logging_log
      where
        lifecycle_state = 'ACTIVE'
    )
   select
      count(b.*) as value,
      'Logging Disabled' as label,
      case count(b.*) when 0 then 'ok' else 'alert' end as type
    from
      oci_objectstorage_bucket as b
      left join name_with_region as n on concat(b.name, b.region) = n.name_with_region
    where
      not n.is_enabled or n.is_enabled is null;
  EOQ
}

# Assessment Queries

query "objectstorage_bucket_public_access_status" {
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

query "objectstorage_bucket_versioning_status" {
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
      versioning_stat;
  EOQ
}

query "objectstorage_bucket_logging_status" {
  sql = <<-EOQ
    with name_with_region as (
      select
        concat(configuration -> 'source' ->> 'resource', region) as name_with_region,
        is_enabled
      from
        oci_logging_log
      where
        lifecycle_state = 'ACTIVE'
    ),
    logging_stat as (
      select
      case
        when not n.is_enabled or n.is_enabled is null then 'disabled'
        else 'enabled'
      end as logging_stat
    from
      oci_objectstorage_bucket as b
      left join name_with_region as n on concat(b.name, b.region) = n.name_with_region
    )
    select
      logging_stat,
      count(*)
    from
      logging_stat
    group by
      logging_stat;
  EOQ
}

# Analysis Queries

query "objectstorage_bucket_by_tenancy" {
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

query "objectstorage_bucket_by_compartment" {
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
      count(b.*) as "Buckets"
    from
      oci_objectstorage_bucket as b,
      compartments as c
    where
      c.id = b.compartment_id
    group by
      c.title
    order by
      c.title;
  EOQ
}

query "objectstorage_bucket_by_region" {
  sql = <<-EOQ
    select
      region as "Region", count(*) as "Buckets"
    from
      oci_objectstorage_bucket
    group by
      region
    order by
      region;
  EOQ
}

query "objectstorage_bucket_by_creation_month" {
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

query "objectstorage_bucket_encryption_status" {
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
