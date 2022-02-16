query "oci_kms_key_pending_deletion_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Pending Deletion' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      oci_kms_key
    where
      lifecycle_state = 'PENDING_DELETION'
  EOQ
}


report "oci_kms_key_lifecycle_report" {

  title = "OCI KMS Key Lifecycle Report"

  container {

    card {
      sql = query.oci_kms_key_pending_deletion_count.sql
      width = 2
    }

  }

  table {
    sql = <<-EOQ
      with compartments as (
        select
          id,
          title
        from
          oci_identity_tenancy
        union (
          select
            id,
            title
          from
            oci_identity_compartment
          where lifecycle_state = 'ACTIVE')
        )
      select
        a.name as "Name",
        a.protection_mode as "Protection Mode",
        a.lifecycle_state as "Key State",
        a.time_created as "Time Created",
        a.time_of_deletion as "Scheduled Deletion Date",
        b.title as "Compartment",
        a.region as "Region"
      from
          oci_kms_key as a
          left join compartments as b on b.id = a.Compartment_id
      where a.lifecycle_state in ('PENDING_DELETION', 'DISABLED', 'ENABLED')
    EOQ
  }

}
