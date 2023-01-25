dashboard "oci_vcn_dashboard" {

  title         = "OCI VCN Dashboard"
  documentation = file("./dashboards/vcn/docs/vcn_dashboard.md")

  tags = merge(local.vcn_common_tags, {
    type = "Dashboard"
  })

  container {

    card {
      sql   = query.oci_vcn_count.sql
      width = 3
    }

    card {
      sql   = query.oci_vcn_no_subnet_count.sql
      width = 3
    }

  }

  container {

    title = "Assessments"

    chart {
      title = "Empty VCNs (No Subnets)"
      sql   = query.oci_vcn_no_subnet.sql
      type  = "donut"
      width = 3

      series "count" {
        point "non-empty" {
          color = "ok"
        }
        point "empty" {
          color = "alert"
        }
      }
    }

  }

  container {

    title = "Analysis"

    chart {
      title = "VCNs by Tenancy"
      sql   = query.oci_vcn_by_tenancy.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "VCNs by Compartment"
      sql   = query.oci_vcn_by_compartment.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "VCNs by Region"
      sql   = query.oci_vcn_by_region.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "VCNs by RFC1918 Range"
      sql   = query.oci_vcn_by_rfc1918_range.sql
      type  = "column"
      width = 3
    }

  }

}

# Card Queries

query "oci_vcn_count" {
  sql = <<-EOQ
    select count(*) as "VCNs" from oci_core_vcn where lifecycle_state <> 'TERMINATED';
  EOQ
}

query "oci_vcn_no_subnet_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'VCNs Without Subnets' as label,
      case when count(*) = 0 then 'ok' else 'alert' end as type
    from
      oci_core_vcn as vcn
    where
      vcn.id not in (select oci_core_subnet.vcn_id from oci_core_subnet) and lifecycle_state <> 'TERMINATED';
  EOQ
}

# Assessment Queries

query "oci_vcn_no_subnet" {
  sql = <<-EOQ
    select
      case when s.id is null then 'empty' else 'non-empty' end as status,
      count(distinct v.id)
    from
      oci_core_vcn v
      left join oci_core_subnet s on s.vcn_id = v.id
    where
      v.lifecycle_state <> 'TERMINATED'
    group by
      status;
  EOQ
}

# Analysis Queries

query "oci_vcn_by_tenancy" {
  sql = <<-EOQ
    select
      c.title as "Compartment",
      count(v.*) as "VCNs"
    from
      oci_core_vcn as v,
      oci_identity_tenancy as c
    where
      c.id = v.tenant_id and lifecycle_state <> 'TERMINATED'
    group by
      c.title
    order by
      c.title;
  EOQ
}

query "oci_vcn_by_compartment" {
  sql = <<-EOQ
    with compartments as (
      select
        id,
        'root [' || title || ']' as title
      from
        oci_identity_tenancy
      union (
      select
        c.id,
        c.title || ' [' || t.title || ']' as title
      from
        oci_identity_compartment c,
        oci_identity_tenancy t
      where
        c.tenant_id = t.id and c.lifecycle_state = 'ACTIVE'
      )
    )
    select
      c.title as "Title",
      count(v.*) as "VCNs"
    from
      oci_core_vcn as v,
      compartments as c
    where
      c.id = v.compartment_id and v.lifecycle_state <> 'TERMINATED'
    group by
      c.title
    order by
      c.title;
  EOQ
}

query "oci_vcn_by_region" {
  sql = <<-EOQ
    select
      region as "region",
      count(*) as "VCNs"
    from
      oci_core_vcn
    where
      lifecycle_state <> 'TERMINATED'
    group by
      region;
  EOQ
}

query "oci_vcn_by_rfc1918_range" {
  sql = <<-EOQ
    with cidr_buckets as (
      select
        id,
        title,
        b,
        case
          when (b)::cidr <<= '10.0.0.0/16'::cidr then '10.0.0.0/16'
          when (b)::cidr <<= '172.16.0.0/16'::cidr then '172.16.0.0/16'
          when (b)::cidr <<= '192.168.0.0/16'::cidr then '192.168.0.0/16'
          else 'Public Range'
        end as rfc1918_bucket
      from
        oci_core_vcn,
        jsonb_array_elements_text(cidr_blocks) as b
      where
        lifecycle_state <> 'TERMINATED'
    )
    select
      rfc1918_bucket,
      count(*) as "VCNs"
    from
      cidr_buckets
    group by
      rfc1918_bucket
    order by
      rfc1918_bucket;
  EOQ
}
