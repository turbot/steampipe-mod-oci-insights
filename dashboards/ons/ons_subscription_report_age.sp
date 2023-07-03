dashboard "ons_subscription_age_report" {

  title         = "OCI ONS Subscription Age Report"
  documentation = file("./dashboards/ons/docs/ons_subscription_report_age.md")

  tags = merge(local.ons_common_tags, {
    type     = "Report"
    category = "Age"
  })

  container {

    card {
      query = query.ons_subscription_count
      width = 2
    }

    card {
      query = query.ons_subscription_24_hrs
      width = 2
      type  = "info"
    }

    card {
      query = query.ons_subscription_30_days
      width = 2
      type  = "info"
    }

    card {
      query = query.ons_subscription_90_days
      width = 2
      type  = "info"
    }

    card {
      query = query.ons_subscription_365_days
      width = 2
      type  = "info"
    }

    card {
      query = query.ons_subscription_1_year
      width = 2
      type  = "info"
    }

  }


  table {
    column "OCID" {
      display = "none"
    }

    query = query.ons_subscription_age_report
  }

}

query "ons_subscription_24_hrs" {
  sql = <<-EOQ
    select
      count(*) as value,
      '< 24 hours' as label
    from
      oci_ons_subscription
    where
      created_time > now() - '1 days' :: interval;
  EOQ
}

query "ons_subscription_30_days" {
  sql = <<-EOQ
    select
      count(*) as value,
      '1-30 Days' as label
    from
      oci_ons_subscription
    where
      created_time between symmetric now() - '1 days' :: interval and now() - '30 days' :: interval;
  EOQ
}

query "ons_subscription_90_days" {
  sql = <<-EOQ
    select
      count(*) as value,
      '30-90 Days' as label
    from
      oci_ons_subscription
    where
      created_time between symmetric now() - '30 days' :: interval and now() - '90 days' :: interval;
  EOQ
}

query "ons_subscription_365_days" {
  sql = <<-EOQ
    select
      count(*) as value,
      '90-365 Days' as label
    from
      oci_ons_subscription
    where
      created_time between symmetric (now() - '90 days'::interval) and (now() - '365 days'::interval);
  EOQ
}

query "ons_subscription_1_year" {
  sql = <<-EOQ
    select
      count(*) as value,
      '> 1 Year' as label
    from
      oci_ons_subscription
    where
      created_time <= now() - '1 year' :: interval;
  EOQ
}

query "ons_subscription_age_report" {
  sql = <<-EOQ
    select
      s.endpoint as "Endpoint",
      s.id as "OCID",
      now()::date - s.created_time::date as "Age in Days",
      s.created_time as "Create Time",
      s.lifecycle_state as "Lifecycle State",
      t.title as "Tenancy",
      coalesce(c.title, 'root') as "Compartment",
      s.region as "Region"
    from
      oci_ons_subscription as s
      left join oci_identity_compartment as c on s.compartment_id = c.id
      left join oci_identity_tenancy as t on s.tenant_id = t.id
    order by
      s.created_time,
      s.endpoint;
  EOQ
}
