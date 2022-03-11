dashboard "oci_compartment_report" {

  title         = "OCI Compartment Report"
  documentation = file("./dashboards/oci/docs/oci_compartment_report.md")

  tags = merge(local.oci_common_tags, {
    type     = "Report"
    category = "Compartments"
  })

  container {

    card {
      sql   = query.oci_tenancy_count.sql
      width = 2
    }

    card {
      sql   = query.oci_compartment_count.sql
      width = 2
    }

  }

  table {
    sql = query.oci_tenancy_table.sql
  }

}

query "oci_tenancy_count" {
  sql = <<-EOQ
    select
      count(*) as "Tenancies"
    from
      oci_identity_tenancy;
  EOQ
}

query "oci_compartment_count" {
  sql = <<-EOQ
    select
      count(*) as "Compartments"
    from
      oci_identity_compartment
    where
      lifecycle_state = 'ACTIVE';
  EOQ
}

query "oci_tenancy_table" {
  sql = <<-EOQ
    select
      c.name as "Compartment Name",
      t.name as "Tenancy Name",
      c.lifecycle_state as "Lifecycle State",
      t.home_region_key as "Home Region Key"
    from
      oci_identity_compartment as c
      left join oci_identity_tenancy as t on t.id = c.tenant_id;
  EOQ
}
