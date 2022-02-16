query "oci_objectstorage_bucket_report_customer_managed_encryption_count" {
  sql = <<-EOQ
    select count(*) as "Customer Managed"
      from 
    oci_objectstorage_bucket 
    where 
    kms_key_id is not null
  EOQ
}

report "oci_objectstorage_bucket_encryption_report" {

  title = "OCI Object Storage Bucket Encryption Report"

  container {

    card {
      sql = query.oci_objectstorage_bucket_report_customer_managed_encryption_count.sql
      width = 2
    }

    card {
      sql = query.oci_objectstorage_bucket_default_encryption_count.sql
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
        case when b.kms_key_id is not null then 'Customer Managed' else 'Oracle Managed' end as "Encryption Status",
        k.algorithm as "Algorithm",
        b.kms_key_id as "KMS Key ID",
        c.title as "Compartment",
        b.region as "Region",
        b.id as "Bucket ID"
      from
        oci_objectstorage_bucket as b
        left join oci_kms_key as k on k.id = b.kms_key_id
        left join compartments as c on c.id = b.Compartment_id;
    EOQ
  }

}