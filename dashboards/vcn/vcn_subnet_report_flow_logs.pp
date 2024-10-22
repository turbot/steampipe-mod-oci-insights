dashboard "oci_vcn_subnet_flow_logs_report" {

  title         = "OCI VCN Subnet Flow Logs Report"
  documentation = file("./dashboards/vcn/docs/vcn_subnet_report_flow_logs.md")

  tags = merge(local.vcn_common_tags, {
    type     = "Report"
    category = "Logging"
  })

  container {

    card {
      width = 3
      query = query.oci_vcn_subnet_count
    }

    card {
      query = query.oci_vcn_subnet_flow_logs_not_configured_count
      width = 3
    }

  }

  table {
    column "OCID" {
      display = "none"
    }

    column "Name" {
      href = "${dashboard.vcn_subnet_detail.url_path}?input.subnet_id={{.OCID | @uri}}"
    }

    query = query.oci_vcn_subnet_flow_logs_report
  }

}

query "oci_vcn_subnet_flow_logs_report" {
  sql = <<-EOQ
      select
        s.display_name as "Name",
        case
          when l.is_enabled is null or not l.is_enabled then null
          else 'Enabled'
        end as "Flow Logs Status",
        t.title as "Tenancy",
        coalesce(c.title, 'root') as "Compartment",
        s.region as "Region",
        s.id as "OCID"
      from
        oci_core_subnet as s
        left join oci_logging_log as l on s.id = l.configuration -> 'source' ->> 'resource'
        left join oci_identity_compartment as c on s.compartment_id = c.id
        left join oci_identity_tenancy as t on s.tenant_id = t.id
      where
        s.lifecycle_state <> 'TERMINATED'
      order by
        s.display_name;
   EOQ
}
