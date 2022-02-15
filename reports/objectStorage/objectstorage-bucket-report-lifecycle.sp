query "oci_objectstorage_bucket_report_versioning_disabled_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Versioning Disabled' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      oci_objectstorage_bucket
    where
      versioning = 'Disabled'
  EOQ
}

report "oci_objectstorage_bucket_lifecycle_report" {

  title = "OCI Object Storage Bucket Lifecycle Report"

  container {

    card {
      sql = query.oci_objectstorage_bucket_report_versioning_disabled_count.sql
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
          where 
            lifecycle_state = 'ACTIVE'
          )  
       )
      select
        b.name as "Bucket",
        b.versioning as "Versioning",
        c.title as "Compartment",
        b.region as "Region",
        b.id as "Bucket ID"
      from
        oci_objectstorage_bucket as b
        left join compartments as c on c.id = b.Compartment_id;
    EOQ
  }

}