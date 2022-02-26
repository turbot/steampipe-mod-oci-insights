dashboard "oci_vcn_subnet_flowlog_report" {

  title = "OCI VCN Subnet Flow Log Report"

  container {

    card {
      width = 2
      sql   = query.oci_vcn_subnet_count.sql
    }

    card {
      sql   = query.oci_vcn_subnet_flowlog_not_configured_count.sql
      width = 2
    }
  }

  table {
    sql = <<-EOQ
      select
        v.display_name as "Name",
        case
          when l.is_enabled is null or not l.is_enabled then 'Not Configured'
          else 'Configured'
        end as "Flow Log Status",
        v.lifecycle_state as "Lifecycle State",
        v.time_created as "Create Time",
        coalesce(c.title, 'root') as "Compartment",
        t.title as "Tenancy",
        v.region as "Region",
        v.id as "OCID"
      from
        oci_core_subnet as v
        left join oci_logging_log as l on v.id = l.configuration -> 'source' ->> 'resource'
        left join oci_identity_compartment as c on v.compartment_id = c.id
        left join oci_identity_tenancy as t on v.tenant_id = t.id
      where
        v.lifecycle_state <> 'TERMINATED'
      order by
        v.time_created,
        v.title;
    EOQ
  }

}
