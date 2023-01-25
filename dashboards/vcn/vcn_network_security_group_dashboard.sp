dashboard "oci_vcn_network_security_group_dashboard" {

  title         = "OCI VCN Network Security Group Dashboard"
  documentation = file("./dashboards/vcn/docs/vcn_network_security_group_dashboard.md")

  tags = merge(local.vcn_common_tags, {
    type = "Dashboard"
  })

  container {

    card {
      width = 3
      sql   = query.oci_vcn_security_group_count.sql
    }

    card {
      width = 3
      sql   = query.oci_vcn_security_group_unrestricted_ingress_ssh_count.sql
    }

    card {
      width = 3
      sql   = query.oci_vcn_security_group_unrestricted_ingress_rdp_count.sql
    }

  }

  container {

    title = "Assessments"

    chart {
      title = "Ingress SSH Status"
      type  = "donut"
      width = 3
      sql   = query.oci_vcn_security_group_by_ingress_rdp.sql

      series "count" {
        point "restricted" {
          color = "ok"
        }
        point "unrestricted" {
          color = "alert"
        }
      }
    }

    chart {
      title = "Ingress RDP Status"
      type  = "donut"
      width = 3
      sql   = query.oci_vcn_security_group_by_ingress_rdp.sql

      series "count" {
        point "restricted" {
          color = "ok"
        }
        point "unrestricted" {
          color = "alert"
        }
      }
    }

  }

  container {

    title = "Analysis"

    chart {
      title = "Security Groups by Tenancy"
      sql   = query.oci_vcn_security_groups_by_tenancy.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Security Groups by Compartment"
      sql   = query.oci_vcn_security_groups_by_compartment.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Security Groups by Region"
      sql   = query.oci_vcn_security_groups_by_region.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Security Groups by VCN"
      sql   = query.oci_vcn_security_groups_by_vcn.sql
      type  = "column"
      width = 3
    }

  }

}

# Card Queries

query "oci_vcn_security_group_count" {
  sql = <<-EOQ
    select count(*) as "Security Groups" from oci_core_network_security_group where lifecycle_state <> 'TERMINATED';
  EOQ
}

query "oci_vcn_security_group_unrestricted_ingress_ssh_count" {
  sql = <<-EOQ
   with non_compliant_rules as (
      select
        id,
        count(*) as num_noncompliant_rules
      from
        oci_core_network_security_group,
        jsonb_array_elements(rules) as r
      where
        r ->> 'direction' = 'INGRESS'
        and r ->> 'sourceType' = 'CIDR_BLOCK'
        and r ->> 'source' = '0.0.0.0/0'
        and (
        r ->> 'protocol' = 'all'
        or (
        (r -> 'tcpOptions' -> 'destinationPortRange' ->> 'min')::integer <= 22
        and (r -> 'tcpOptions' -> 'destinationPortRange' ->> 'max')::integer >= 22
        )
      )
      and lifecycle_state <> 'TERMINATED'
      group by id
    ),
    sg_list as (
      select
        nsg.id,
        case
          when non_compliant_rules.id is null then true
          else false
        end as restricted
      from
        oci_core_network_security_group as nsg
        left join non_compliant_rules on non_compliant_rules.id = nsg.id
        left join oci_identity_compartment c on c.id = nsg.compartment_id
      where
        nsg.lifecycle_state <> 'TERMINATED'
    )
    select
      count(*) as value,
      'Unrestricted Ingress SSH' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      sg_list
    where not restricted;
  EOQ
}

query "oci_vcn_security_group_unrestricted_ingress_rdp_count" {
  sql = <<-EOQ
    with non_compliant_rules as (
      select
        id,
        count(*) as num_noncompliant_rules
      from
        oci_core_network_security_group,
        jsonb_array_elements(rules) as r
      where
        r ->> 'direction' = 'INGRESS'
        and r ->> 'sourceType' = 'CIDR_BLOCK'
        and r ->> 'source' = '0.0.0.0/0'
        and (
        r ->> 'protocol' = 'all'
        or (
        (r -> 'tcpOptions' -> 'destinationPortRange' ->> 'min')::integer <= 22
        and (r -> 'tcpOptions' -> 'destinationPortRange' ->> 'max')::integer >= 22
        )
      )
      and lifecycle_state <> 'TERMINATED'
      group by id
    ),
    sg_list as (
      select
        nsg.id,
        case
          when non_compliant_rules.id is null then true
          else false
        end as restricted
      from
        oci_core_network_security_group as nsg
        left join non_compliant_rules on non_compliant_rules.id = nsg.id
        left join oci_identity_compartment c on c.id = nsg.compartment_id
      where
        nsg.lifecycle_state <> 'TERMINATED'
    )
    select
      count(*) as value,
      'Unrestricted Ingress RDP' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      sg_list
    where not restricted;
  EOQ
}

# Assessment Queries

query "oci_vcn_security_group_by_ingress_ssh" {
  sql = <<-EOQ
    with non_compliant_rules as (
      select
        id,
        count(*) as num_noncompliant_rules
      from
        oci_core_network_security_group,
        jsonb_array_elements(rules) as r
      where
        r ->> 'direction' = 'INGRESS'
        and r ->> 'sourceType' = 'CIDR_BLOCK'
        and r ->> 'source' = '0.0.0.0/0'
        and (
        r ->> 'protocol' = 'all'
        or (
        (r -> 'tcpOptions' -> 'destinationPortRange' ->> 'min')::integer <= 22
        and (r -> 'tcpOptions' -> 'destinationPortRange' ->> 'max')::integer >= 22
        )
      )
      and lifecycle_state <> 'TERMINATED'
      group by id
    ),
    sg_list as (
      select
        nsg.id,
        case
          when non_compliant_rules.id is null then true
          else false
        end as restricted
      from
        oci_core_network_security_group as nsg
        left join non_compliant_rules on non_compliant_rules.id = nsg.id
        left join oci_identity_compartment c on c.id = nsg.compartment_id
      where
        nsg.lifecycle_state <> 'TERMINATED'
    )
    select
      case
        when restricted then 'restricted'
        else 'unrestricted'
      end as restrict_ingress_ssh_status,
      count(*)
    from
      sg_list
    group by restricted;
  EOQ
}

query "oci_vcn_security_group_by_ingress_rdp" {
  sql = <<-EOQ
    with non_compliant_rules as (
      select
        id,
        count(*) as num_noncompliant_rules
      from
        oci_core_network_security_group,
        jsonb_array_elements(rules) as r
      where
        r ->> 'direction' = 'INGRESS'
        and r ->> 'sourceType' = 'CIDR_BLOCK'
        and r ->> 'source' = '0.0.0.0/0'
        and (
        r ->> 'protocol' = 'all'
        or (
        (r -> 'tcpOptions' -> 'destinationPortRange' ->> 'min')::integer <= 22
        and (r -> 'tcpOptions' -> 'destinationPortRange' ->> 'max')::integer >= 22
        )
      )
      and lifecycle_state <> 'TERMINATED'
      group by id
    ),
    sg_list as (
      select
        nsg.id,
        case
          when non_compliant_rules.id is null then true
          else false
        end as restricted
      from
        oci_core_network_security_group as nsg
        left join non_compliant_rules on non_compliant_rules.id = nsg.id
        left join oci_identity_compartment c on c.id = nsg.compartment_id
      where
        nsg.lifecycle_state <> 'TERMINATED'
    )
    select
      case
        when restricted then 'restricted'
        else 'unrestricted'
      end as restrict_ingress_rdp_status,
      count(*)
    from
      sg_list
    group by restricted;
  EOQ
}

# Analysis Queries

query "oci_vcn_security_groups_by_tenancy" {
  sql = <<-EOQ
    select
      c.title as "Tenancy",
      count(sg.*) as "Security Groups"
    from
      oci_core_network_security_group as sg,
      oci_identity_tenancy as c
    where
      c.id = sg.tenant_id and lifecycle_state <> 'TERMINATED'
    group by
      c.title
    order by
      c.title;
  EOQ
}

query "oci_vcn_security_groups_by_compartment" {
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
      count(g.*) as "Security Groups"
    from
      oci_core_network_security_group as g,
      compartments as c
    where
      c.id = g.compartment_id and g.lifecycle_state <> 'DELETED'
    group by
      c.title
    order by
      c.title;
  EOQ
}

query "oci_vcn_security_groups_by_region" {
  sql = <<-EOQ
    select
      region as "Region",
      count(*) as "Security Groups"
    from
      oci_core_network_security_group
    where
      lifecycle_state <> 'TERMINATED'
    group by
      region
    order by
      region;
  EOQ
}

query "oci_vcn_security_groups_by_vcn" {
  sql = <<-EOQ
    select
      v.display_name as "VCN",
      count(*) as "security_groups"
    from
      oci_core_network_security_group sg
      left join oci_core_vcn v on sg.vcn_id = v.id
    where
      sg.lifecycle_state <> 'TERMINATED'
      group by v.display_name
      order by v.display_name;
  EOQ
}
