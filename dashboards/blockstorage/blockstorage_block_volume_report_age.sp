dashboard "blockstorage_block_volume_age_report" {

  title         = "OCI Block Storage Block Volume Age Report"
  documentation = file("./dashboards/blockstorage/docs/blockstorage_block_volume_report_age.md")

  tags = merge(local.blockstorage_common_tags, {
    type     = "Report"
    category = "Age"
  })

  container {

    card {
      query = query.blockstorage_block_volume_count
      width = 2
    }

    card {
      query = query.blockstorage_block_volume_24_hrs
      width = 2
      type  = "info"
    }

    card {
      query = query.blockstorage_block_volume_30_days
      width = 2
      type  = "info"
    }

    card {
      query = query.blockstorage_block_volume_90_days
      width = 2
      type  = "info"
    }

    card {
      query = query.blockstorage_block_volume_365_days
      width = 2
      type  = "info"
    }

    card {
      query = query.blockstorage_block_volume_1_year
      width = 2
      type  = "info"
    }

  }

  table {
    column "OCID" {
      display = "none"
    }

    column "Name" {
      href = "${dashboard.blockstorage_block_volume_detail.url_path}?input.block_volume_id={{.OCID | @uri}}"
    }

    query = query.blockstorage_block_volume_age_report
  }

}

query "blockstorage_block_volume_24_hrs" {
  sql = <<-EOQ
    select
      count(*) as value,
      '< 24 hours' as label
    from
      oci_core_volume
    where
      lifecycle_state <> 'TERMINATED' and time_created > now() - '1 days' :: interval;
  EOQ
}

query "blockstorage_block_volume_30_days" {
  sql = <<-EOQ
    select
      count(*) as value,
      '1-30 Days' as label
    from
      oci_core_volume
    where
      lifecycle_state <> 'TERMINATED' and time_created between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval;
  EOQ
}

query "blockstorage_block_volume_90_days" {
  sql = <<-EOQ
    select
      count(*) as value,
      '30-90 Days' as label
    from
      oci_core_volume
    where
      lifecycle_state <> 'TERMINATED' and time_created between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval;
  EOQ
}

query "blockstorage_block_volume_365_days" {
  sql = <<-EOQ
    select
      count(*) as value,
      '90-365 Days' as label
    from
      oci_core_volume
    where
      lifecycle_state <> 'TERMINATED' and time_created between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval);
  EOQ
}

query "blockstorage_block_volume_1_year" {
  sql = <<-EOQ
    select
      count(*) as value,
      '> 1 Year' as label
    from
      oci_core_volume
    where
      lifecycle_state <> 'TERMINATED' and time_created <= now() - '1 year' :: interval;
  EOQ
}

query "blockstorage_block_volume_age_report" {
  sql = <<-EOQ
    select
      v.display_name as "Name",
      v.id as "OCID",
      now()::date - v.time_created::date as "Age in Days",
      v.time_created as "Create Time",
      v.lifecycle_state as "Lifecycle State",
      t.title as "Tenancy",
      coalesce(c.title, 'root') as "Compartment",
      v.region as "Region"
    from
      oci_core_volume as v
      left join oci_identity_compartment as c on v.compartment_id = c.id
      left join oci_identity_tenancy as t on v.tenant_id = t.id
    where
      v.lifecycle_state <> 'TERMINATED'
    order by
      v.time_created,
      v.display_name;
  EOQ
}
