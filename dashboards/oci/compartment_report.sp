dashboard "compartment_report" {

  title         = "OCI Compartment Report"
  documentation = file("./dashboards/oci/docs/compartment_report.md")

  tags = merge(local.oci_common_tags, {
    type     = "Report"
    category = "Compartment"
  })

  container {

    card {
      query = query.compartment_count
      width = 2
    }

  }

  table {
    query = query.compartment_table
  }

}

query "compartment_count" {
  sql = <<-EOQ
    select
      count(*) as "Compartments"
    from
      oci_identity_compartment
    where
      lifecycle_state = 'ACTIVE';
  EOQ
}

query "compartment_table" {
  sql = <<-EOQ
    select
      c.name as "Name",
      c.lifecycle_state as "Lifecycle State",
      c.time_created as "Time Created",
      t.name as "Tenancy Name"
    from
      oci_identity_compartment as c
      left join oci_identity_tenancy as t on t.id = c.tenant_id;
  EOQ
}
