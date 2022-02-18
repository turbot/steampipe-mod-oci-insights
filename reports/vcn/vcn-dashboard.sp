
query "oci_core_vcn_count" {
  sql = <<-EOQ
    select count(*) as "VCNs" from oci_core_vcn
  EOQ
}

query "oci_core_vcn_no_subnet_count" {
  sql = <<-EOQ
    select 
      count(*) as value,
      'VCNs with no Subnets' as label,
      case when count(*) = 0 then 'ok' else 'alert' end as type    
    from 
      oci_core_vcn as vcn
    where
      vcn.id not in (select oci_core_subnet.vcn_id from oci_core_subnet)
  EOQ
}

query "oci_core_vcn_no_internet_gateway" {
  sql = <<-EOQ
    select 
      count(*) as value,
      'VCNs with no Internet Gateways' as label,
      case when count(*) = 0 then 'ok' else 'alert' end as type    
    from 
      oci_core_vcn as vcn
    where
      vcn.id not in (select oci_core_internet_gateway.vcn_id from oci_core_internet_gateway)
  EOQ
}

query "oci_core_vcn_no_nat_gateway" {
  sql = <<-EOQ
    select 
      count(*) as value,
      'VCNs with no Nat Gateways' as label,
      case when count(*) = 0 then 'ok' else 'alert' end as type    
    from 
      oci_core_vcn as vcn
    where
      vcn.id not in (select oci_core_nat_gateway.vcn_id from oci_core_nat_gateway)
  EOQ
}

query "oci_core_vcn_by_account" {
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
      c.title as "compartment",
      count(v.*) as "VCNs"
    from
      oci_core_vcn as v,
      compartments as c
    where
      c.id = v.compartment_id
    group by
      compartment
    order by
      compartment
  EOQ
}


query "oci_core_vcn_by_region" {
  sql = <<-EOQ
    select
      region as "region",
      count(*) as "VCNs"
    from
      oci_core_vcn
    group by
      region
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
    )
    select 
      rfc1918_bucket,
      count(*) as "VCNs"
    from 
      cidr_buckets
    group by 
      rfc1918_bucket
    order by
      rfc1918_bucket
  EOQ
}


dashboard "oci_core_vcn_dashboard" {

  title = "OCI Core VCN Dashboard"

  container {

  # Analysis

    card {
      sql   = query.oci_core_vcn_count.sql
      width = 3
    }
  
  # Assessments

    card {
      sql = query.oci_core_vcn_no_subnet_count.sql
      width = 3
    }

    card {
      sql = query.oci_core_vcn_no_internet_gateway.sql
      width = 3
    }

    card {
      sql = query.oci_core_vcn_no_nat_gateway.sql
      width = 3
    }

  }

  container {
    title = "Analysis"

    chart {
      title = "VCNs by Compartment"
      sql   = query.oci_core_vcn_by_account.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "VCNs by Region"
      sql   = query.oci_core_vcn_by_region.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "VCNs by RFC1918 Range"
      sql   = query.oci_vcn_by_rfc1918_range.sql
      type  = "column"
      width = 4
    }
  }

}