query "oci_ons_notification_topic_not_active_lifecycle_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Lifecycle State Not Active' as label,
      case count(*) when 0 then 'ok' else 'alert' end as "type"
    from
      oci_ons_notification_topic
    where
      lifecycle_state not in ('ACTIVE','DELETED')
  EOQ
}

dashboard "oci_ons_notification_topic_lifecycle_report" {

  title = "OCI ONS Notification Topic Lifecycle Report"

  container {

    card {
      sql = query.oci_ons_notification_topic_not_active_lifecycle_count.sql
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
        t.name as "Name",
        t.lifecycle_state as "Lifecycle State",
        t.time_created as "Time Created",
        c.title as "Compartment",
        t.region as "Region"
      from
        oci_ons_notification_topic as t
        left join compartments as c on c.id = t.Compartment_id
      where 
        t.lifecycle_state <> 'DELETED'
    EOQ
  }

}