query "oci_mysql_db_system_not_active_lifecycle_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Lifecycle State Not Active' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      oci_mysql_db_system
    where
      lifecycle_state not in ('ACTIVE','DELETED')
  EOQ
}

report "oci_mysql_db_system_lifecycle_report" {

  title = "OCI MySQL DB Systems Lifecycle Report"

  container {

    card {
      sql = query.oci_mysql_db_system_not_active_lifecycle_count.sql
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
        oci_mysql_db_system as b
        left join compartments as c on c.id = b.Compartment_id
      where 
        t.lifecycle_state <> 'DELETED'  
    EOQ
  }

}