dashboard "objectstorage_bucket_age_report" {

  title         = "OCI Object Storage Bucket Age Report"
  documentation = file("./dashboards/objectstorage/docs/objectstorage_bucket_report_age.md")

  tags = merge(local.objectstorage_common_tags, {
    type     = "Report"
    category = "Age"
  })

  container {

    card {
      query = query.objectstorage_bucket_count
      width = 2
    }

    card {
      query = query.objectstorage_bucket_24_hrs
      width = 2
      type  = "info"
    }

    card {
      query = query.objectstorage_bucket_30_days
      width = 2
      type  = "info"
    }

    card {
      query = query.objectstorage_bucket_90_days
      width = 2
      type  = "info"
    }

    card {
      query = query.objectstorage_bucket_365_days
      width = 2
      type  = "info"
    }

    card {
      query = query.objectstorage_bucket_1_year
      width = 2
      type  = "info"
    }

  }

  table {
    column "OCID" {
      display = "none"
    }

    column "Name" {
      href = "${dashboard.objectstorage_bucket_detail.url_path}?input.bucket_id={{.OCID | @uri}}"
    }

    query = query.objectstorage_bucket_age_report
  }

}

query "objectstorage_bucket_24_hrs" {
  sql = <<-EOQ
    select
      count(*) as value,
      '< 24 hours' as label
    from
      oci_objectstorage_bucket
    where
      time_created > now() - '1 days' :: interval;
  EOQ
}

query "objectstorage_bucket_30_days" {
  sql = <<-EOQ
    select
      count(*) as value,
      '1-30 Days' as label
    from
      oci_objectstorage_bucket
    where
      time_created between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval;
  EOQ
}

query "objectstorage_bucket_90_days" {
  sql = <<-EOQ
    select
      count(*) as value,
      '30-90 Days' as label
    from
      oci_objectstorage_bucket
    where
      time_created between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval;
  EOQ
}

query "objectstorage_bucket_365_days" {
  sql = <<-EOQ
    select
      count(*) as value,
      '90-365 Days' as label
    from
      oci_objectstorage_bucket
    where
      time_created between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval);
  EOQ
}

query "objectstorage_bucket_1_year" {
  sql = <<-EOQ
    select
      count(*) as value,
      '> 1 Year' as label
    from
      oci_objectstorage_bucket
    where
      time_created <= now() - '1 year' :: interval;
  EOQ
}

query "objectstorage_bucket_age_report" {
  sql = <<-EOQ
    select
      b.name as "Name",
      b.id as "OCID",
      now()::date - b.time_created::date as "Age in Days",
      b.time_created as "Create Time",
      t.title as "Tenancy",
      coalesce(c.title, 'root') as "Compartment",
      b.region as "Region"
    from
      oci_objectstorage_bucket as b
      left join oci_identity_compartment as c on b.compartment_id = c.id
      left join oci_identity_tenancy as t on b.tenant_id = t.id
    order by
      b.time_created,
      b.name;
  EOQ
}
