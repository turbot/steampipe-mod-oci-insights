query "oci_objectstorage_bucket_disabled_count" {
  sql = <<-EOQ
    with namewithregion as (
      select
        concat(configuration -> 'source' ->> 'resource', region) as namewithregion,
        is_enabled
      from
        oci_logging_log
      where 
        lifecycle_state = 'ACTIVE' 
    )
   select 
      count(b.*) as value,
      'Logging Disabled' as label,
      case count(b.*) when 0 then 'ok' else 'alert' end as "type" 
    from 
      oci_objectstorage_bucket as b
      left join namewithregion as n on concat(b.name, b.region) = n.namewithregion
    where
      not n.is_enabled or n.is_enabled is null
  EOQ
}

report "oci_objectstorage_bucket_logging_report" {

  title = "OCI Object Storage Bucket Logging Report"

  container {

    card {
      sql = query.oci_objectstorage_bucket_disabled_count.sql
      width = 2
    }
  }

  table {
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
    ),
      namewithregion as (
      select
        concat(configuration -> 'source' ->> 'resource', region) as namewithregion,
        is_enabled,
        retention_duration
      from
        oci_logging_log
      where 
        lifecycle_state = 'ACTIVE' 
    )
      select
        b.name as "Bucket",
        n.is_enabled as "Logging Status",
        n.retention_duration as "Retention Duration",
        c.title as "Compartment",
        b.region as "Region",
        b.id as "Bucket ID"
      from
        oci_objectstorage_bucket as b
        left join namewithregion as n on concat(b.name, b.region) = n.namewithregion
        left join compartments as c on c.id = b.Compartment_id;
    EOQ
  }

}