# Added to report
query "oci_objectstorage_bucket_report_public_access_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Has Public Access' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      oci_objectstorage_bucket
    where
      public_access_type <> 'NoPublicAccess'  
  EOQ
}

query "oci_objectstorage_bucket_not_read_only_access_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Buckets Without Read Only Access' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      oci_objectstorage_bucket
    where
      not is_read_only
  EOQ
}

report "oci_objectstorage_bucket_public_access_report" {

  title = "OCI Object Storage Bucket Public Access Report"

  container {

    card {
      sql = query.oci_objectstorage_bucket_report_public_access_count.sql
      width = 2
    }

    card {
      sql = query.oci_objectstorage_bucket_not_read_only_access_count.sql
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
    )
      select
        b.name as "Bucket",
        case when b.public_access_type = 'NoPublicAccess' then 'Not Public' else 'Public' end as "Bucket Access",
        b.is_read_only as "Read Only Access",
        c.title as "Compartment",
        b.region as "Region",
        b.id as "Bucket ID"
      from
        oci_objectstorage_bucket as b
        left join compartments as c on c.id = b.Compartment_id;
    EOQ
  }

}