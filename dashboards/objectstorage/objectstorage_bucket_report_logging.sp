dashboard "oci_objectstorage_bucket_logging_report" {

  title         = "OCI Object Storage Bucket Logging Report"
  documentation = file("./dashboards/objectstorage/docs/objectstorage_bucket_report_logging.md")

  tags = merge(local.objectstorage_common_tags, {
    type     = "Report"
    category = "Logging"
  })

  container {

    card {
      sql   = query.oci_objectstorage_bucket_count.sql
      width = 2
    }

    card {
      sql   = query.oci_objectstorage_bucket_logging_disabled_count.sql
      width = 2
    }
  }

  table {
    column "OCID" {
      display = "none"
    }

    sql = query.oci_objectstorage_bucket_logging_table.sql
  }

}

query "oci_objectstorage_bucket_logging_disabled_count" {
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

query "oci_objectstorage_bucket_logging_table" {
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
      b.name as "Name",
      case when n.is_enabled then 'Enabled' else null end as "Logging Status",
      coalesce(c.title, 'root') as "Compartment",
      t.title as "Tenancy",
      b.region as "Region",
      b.id as "OCID"
    from
      oci_objectstorage_bucket as b
      left join name_with_region as n on concat(b.name, b.region) = n.name_with_region
      left join oci_identity_compartment as c on b.compartment_id = c.id
      left join oci_identity_tenancy as t on b.tenant_id = t.id
    order by
      b.name;
  EOQ
}
