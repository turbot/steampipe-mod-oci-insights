dashboard "oci_nosql_table_age_report" {

  title = "OCI NoSQL Table Age Report"

  tags = merge(local.nosql_common_tags, {
    type     = "Report"
    category = "Age"
  })

  container {

    card {
      sql   = query.oci_nosql_table_count.sql
      width = 2
    }

    card {
      sql   = query.oci_nosql_table_24_hrs.sql
      width = 2
      type  = "info"
    }

    card {
      sql   = query.oci_nosql_table_30_days.sql
      width = 2
      type  = "info"
    }

    card {
      sql   = query.oci_nosql_table_90_days.sql
      width = 2
      type  = "info"
    }

    card {
      sql   = query.oci_nosql_table_365_days.sql
      width = 2
      type  = "info"
    }

    card {
      sql   = query.oci_nosql_table_1_year.sql
      width = 2
      type  = "info"
    }

  }

  container {


    table {

      sql = query.oci_nosql_table_age_table.sql
    }


  }

}

query "oci_nosql_table_24_hrs" {
  sql = <<-EOQ
    select
      count(*) as value,
      '< 24 hours' as label
    from
      oci_nosql_table
    where
      time_created > now() - '1 days' :: interval;
  EOQ
}

query "oci_nosql_table_30_days" {
  sql = <<-EOQ
    select
      count(*) as value,
      '1-30 Days' as label
    from
      oci_nosql_table
    where
      time_created between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval;
  EOQ
}

query "oci_nosql_table_90_days" {
  sql = <<-EOQ
    select
      count(*) as value,
      '30-90 Days' as label
    from
      oci_nosql_table
    where
      time_created between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval;
  EOQ
}

query "oci_nosql_table_365_days" {
  sql = <<-EOQ
    select
      count(*) as value,
      '90-365 Days' as label
    from
      oci_nosql_table
    where
      time_created between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval);
  EOQ
}

query "oci_nosql_table_1_year" {
  sql = <<-EOQ
    select
      count(*) as value,
      '> 1 Year' as label
    from
      oci_nosql_table
    where
      time_created <= now() - '1 year' :: interval;
  EOQ
}

query "oci_nosql_table_age_table" {
  sql = <<-EOQ
    select
      v.name as "Name",
      now()::date - v.time_created::date as "Age in Days",
      v.time_created as "Create Time",
      v.lifecycle_state as "Lifecycle State",
      coalesce(c.title, 'root') as "Compartment",
      t.title as "Tenancy",
      v.region as "Region",
      v.id as "OCID"
    from
      oci_nosql_table as v
      left join oci_identity_compartment as c on v.compartment_id = c.id
      left join oci_identity_tenancy as t on v.tenant_id = t.id
    where
      v.lifecycle_state <> 'DELETED'
    order by
      v.time_created,
      v.title;
  EOQ
}
