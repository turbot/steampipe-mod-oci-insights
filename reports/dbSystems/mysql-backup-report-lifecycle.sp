dashboard "oci_mysql_backup_lifecycle_report" {

  title = "OCI MySQL Backup Lifecycle Report"

  container {

    card {
      sql = query.oci_mysql_backup_inactive_lifecycle_count.sql
      width = 2
    }

    card {
      sql = query.oci_mysql_backup_failed_lifecycle_count.sql
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
        b.display_name as "Name",
        b.lifecycle_state as "Lifecycle State",
        b.time_created as "Time Created",
        c.title as "Compartment",
        b.region as "Region"
      from
        oci_mysql_backup as b
        left join compartments as c on c.id = b.Compartment_id
      where 
        b.lifecycle_state <> 'DELETED'  
    EOQ
  }

}