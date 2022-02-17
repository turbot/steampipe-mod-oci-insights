dashboard "oci_database_autonomous_db_lifecycle_report" {

  title = "OCI Database Autonomous Database Lifecycle Report"

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
        a.lifecycle_state as "DB State",
        a.data_safe_status as "Data Safe",
        a.data_storage_size_in_gbs as "DB Storage",
        a.db_version as "DB Version",
        a.db_workload as "Workload Type",
        a.time_created as "Time Created",
        b.title as "Compartment",
        a.region as "Region"
      from
          oci_database_autonomous_database as a
          left join compartments as b on b.id = a.Compartment_id
      where a.lifecycle_state in ('AVAILABLE_NEEDS_ATTENTION', 'RESTORE_FAILED', 'UNAVAILABLE', 'AVAILABLE')
    EOQ
  }

}
