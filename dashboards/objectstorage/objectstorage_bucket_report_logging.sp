query "oci_objectstorage_bucket_disabled_count" {
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

dashboard "oci_objectstorage_bucket_logging_report" {

  title = "OCI Object Storage Bucket Logging Report"

  container {

    card {
      sql   = query.oci_objectstorage_bucket_count.sql
      width = 2
    }

    card {
      sql = query.oci_objectstorage_bucket_disabled_count.sql
      width = 2
    }
  }

  table {
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
        v.name as "Name",
        case when n.is_enabled then 'Enabled' else 'Disabled' end as "Logging Status",
        v.time_created as "Create Time",
        coalesce(c.title, 'root') as "Compartment",
        t.title as "Tenancy",
        v.region as "Region",
        v.id as "OCID"
      from
        oci_objectstorage_bucket as v
        left join name_with_region as n on concat(v.name, v.region) = n.name_with_region
        left join oci_identity_compartment as c on v.compartment_id = c.id
        left join oci_identity_tenancy as t on v.tenant_id = t.id
        order by
          v.time_created,
          v.title;
    EOQ
  }
}

