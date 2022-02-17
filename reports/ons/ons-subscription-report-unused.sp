dashboard "oci_ons_subscription_unused_report" {

  title = "OCI ONS Subscription Unused Report"

  container {

    card {
      sql = query.oci_ons_subscription_unused_count.sql
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
        s.id as "Id",
        s.created_time as "Time Created",
        s.endpoint as "Subscription Endpoint",
        s.lifecycle_state as "Subscription State",
        s.protocol as "Subscription Protocol",
        c.title as "Compartment",
        s.region as "Region"
      from
        oci_ons_subscription as s
        left join compartments as c on c.id = s.Compartment_id
      where
        s.lifecycle_state <> 'DELETED'
    EOQ
  }

}