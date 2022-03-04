dashboard "oci_core_vcn_dashboard" {

  title = "OCI VCN Dashboard"

  tags = merge(local.vcn_common_tags, {
    type = "Dashboard"
  })

  container {

    card {
      sql   = query.oci_core_vcn_count.sql
      width = 2
    }

    card {
      sql   = query.oci_core_vcn_no_subnet_count.sql
      width = 2
    }

  }

  container {

    title = "Assessments"

    chart {
      title = "Empty VCN (No Subnets)"
      sql   = query.oci_core_vcn_no_subnet.sql
      type  = "donut"
      width = 3

      series "count" {
        point "has_subnet" {
          color = "ok"
        }
        point "no_subnet" {
          color = "alert"
        }
      }
    }

  }

  container {

    title = "Analysis"

    chart {
      title = "VCNs by Tenancy"
      sql   = query.oci_core_vcn_by_tenancy.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "VCNs by Compartment"
      sql   = query.oci_core_vcn_by_compartment.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "VCNs by Region"
      sql   = query.oci_core_vcn_by_region.sql
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

query "oci_core_vcn_count" {
  sql = <<-EOQ
    select count(*) as "VCNs" from oci_core_vcn where lifecycle_state <> 'TERMINATED';
  EOQ
}

query "oci_core_vcn_no_subnet_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'No Subnets' as label,
      case when count(*) = 0 then 'ok' else 'alert' end as type
    from
      oci_core_vcn as vcn
    where
      vcn.id not in (select oci_core_subnet.vcn_id from oci_core_subnet) and lifecycle_state <> 'TERMINATED';
  EOQ
}

# Assessment Queries

query "oci_core_vcn_no_subnet" {
  sql = <<-EOQ
    select
      case when s.id is null then 'no_subnet' else 'has_subnet' end as status,
      count(*)
    from
       oci_core_subnet s
      left join oci_core_vcn v on s.vcn_id = v.id
    where
      v.lifecycle_state <> 'TERMINATED'
    group by
      status;
  EOQ
}

# Analysis Queries

query "oci_core_vcn_by_tenancy" {
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

query "oci_core_vcn_by_compartment" {
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
      t.title as "Tenancy",
      case when t.title = c.title then 'root' else c.title end as "Compartment",
      count(v.*) as "File Systems"
    from
      oci_core_vcn as v,
      oci_identity_tenancy as t,
      compartments as c
    where
      c.id = v.compartment_id and v.tenant_id = t.id and v.lifecycle_state <> 'DELETED'
    group by
      t.title,
      c.title
    order by
      t.title,
      c.title;
  EOQ
}

query "oci_core_vcn_by_region" {
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
