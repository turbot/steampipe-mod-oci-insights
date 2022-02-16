report "oci_filestorage_file_system_lifecycle_report" {

  title = "OCI File Storage File System Report"

  # container {

  #   card {
  #     sql = <<-EOQ
  #     select "TO DO"
  #     EOQ
  #     width = 2
  #   }

  # }

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
        a.display_name as "Name",
        a.lifecycle_state as "File Sytem State",
        a.time_created as "Time Created",
        b.title as "Compartment",
        a.region as "Region"
      from
          oci_file_storage_file_system as a
          left join compartments as b on b.id = a.Compartment_id
    EOQ
  }

}
