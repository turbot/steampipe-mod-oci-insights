dashboard "oci_vcn_network_security_list_dashboard" {

  title         = "OCI VCN Network Security List Dashboard"
  documentation = file("./dashboards/vcn/docs/vcn_security_list_dashboard.md")

  tags = merge(local.vcn_common_tags, {
    type = "Dashboard"
  })

  container {

    card {
      width = 3

      query = query.oci_vcn_security_list_count
    }

    card {
      width = 3

      query = query.oci_vcn_security_list_unrestricted_ingress_ssh_count
    }

    card {
      width = 3

      query = query.oci_vcn_security_list_unrestricted_ingress_rdp_count
    }

  }

  container {

    title = "Assessments"

    chart {
      title = "Ingress SSH Status"
      type  = "donut"
      width = 3
      query = query.oci_vcn_security_list_by_ingress_ssh

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
      query = query.oci_vcn_security_list_by_ingress_rdp

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
      title = "Security Lists by Tenancy"
      query = query.oci_vcn_security_list_by_tenancy
      type  = "column"
      width = 3
    }

    chart {
      title = "Security Lists by Compartment"
      query = query.oci_vcn_security_list_by_compartment
      type  = "column"
      width = 3
    }

    chart {
      title = "Security Lists by Region"
      query = query.oci_vcn_security_list_by_region
      type  = "column"
      width = 3
    }

    chart {
      title = "Network Security Lists by VCN"
      query = query.oci_vcn_security_list_by_vcn
      type  = "column"
      width = 3
    }
  }

}

# Card Queries

query "oci_vcn_security_list_count" {
  sql = <<-EOQ
    select count(*) as "Security Lists" from oci_core_security_list where lifecycle_state <> 'TERMINATED';
  EOQ
}

query "oci_vcn_security_list_unrestricted_ingress_ssh_count" {
  sql = <<-EOQ
    with non_compliant_rules as (
      select
        id,
        count(*) as num_noncompliant_rules
      from
        oci_core_security_list,
        jsonb_array_elements(ingress_security_rules) as p
      where
        p ->> 'source' = '0.0.0.0/0'
        and (
        (
          p ->> 'protocol' = 'all'
          and (p -> 'tcpOptions' -> 'destinationPortRange' -> 'min') is null
        )
        or (
          p ->> 'protocol' = '6' and
          (p -> 'tcpOptions' -> 'destinationPortRange' ->> 'min')::integer <= 22
          and (p -> 'tcpOptions' -> 'destinationPortRange' ->> 'max')::integer >= 22
          )
        )
        and lifecycle_state <> 'TERMINATED'
        group by id
    ),
    sl_list as (
      select
        sl.id,
        case
          when non_compliant_rules.id is null then true
          else false
        end as restricted
      from
        oci_core_security_list as sl
        left join non_compliant_rules on non_compliant_rules.id = sl.id
        left join oci_identity_compartment c on c.id = sl.compartment_id
      where
        sl.lifecycle_state <> 'TERMINATED'
    )
    select
      count(*) as value,
      'Unrestricted Ingress SSH' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      sl_list
    where not restricted;
  EOQ
}

query "oci_vcn_security_list_unrestricted_ingress_rdp_count" {
  sql = <<-EOQ
    with non_compliant_rules as (
      select
        id,
        count(*) as num_noncompliant_rules
      from
        oci_core_security_list,
        jsonb_array_elements(ingress_security_rules) as p
      where
        p ->> 'source' = '0.0.0.0/0'
        and (
        (
          p ->> 'protocol' = 'all'
          and (p -> 'tcpOptions' -> 'destinationPortRange' -> 'min') is null
        )
        or (
          p ->> 'protocol' = '6' and
          (p -> 'tcpOptions' -> 'destinationPortRange' ->> 'min')::integer <= 3389
          and (p -> 'tcpOptions' -> 'destinationPortRange' ->> 'max')::integer >= 3389
          )
        )
        and lifecycle_state <> 'TERMINATED'
        group by id
    ),
    sl_list as (
      select
        sl.id,
        case
          when non_compliant_rules.id is null then true
          else false
        end as restricted
      from
        oci_core_security_list as sl
        left join non_compliant_rules on non_compliant_rules.id = sl.id
        left join oci_identity_compartment c on c.id = sl.compartment_id
      where
        sl.lifecycle_state <> 'TERMINATED'
    )
    select
      count(*) as value,
      'Unrestricted Ingress RDP' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      sl_list
    where not restricted;
  EOQ
}

# Assessment Queries

query "oci_vcn_security_list_by_ingress_ssh" {
  sql = <<-EOQ
    with non_compliant_rules as (
      select
        id,
        count(*) as num_noncompliant_rules
      from
        oci_core_security_list,
        jsonb_array_elements(ingress_security_rules) as p
      where
        p ->> 'source' = '0.0.0.0/0'
        and (
        (
          p ->> 'protocol' = 'all'
          and (p -> 'tcpOptions' -> 'destinationPortRange' -> 'min') is null
        )
        or (
          p ->> 'protocol' = '6' and
          (p -> 'tcpOptions' -> 'destinationPortRange' ->> 'min')::integer <= 22
          and (p -> 'tcpOptions' -> 'destinationPortRange' ->> 'max')::integer >= 22
          )
        )
        and lifecycle_state <> 'TERMINATED'
        group by id
    ),
    sl_list as (
      select
        sl.id,
        case
          when non_compliant_rules.id is null then true
          else false
        end as restricted
      from
        oci_core_security_list as sl
        left join non_compliant_rules on non_compliant_rules.id = sl.id
        left join oci_identity_compartment c on c.id = sl.compartment_id
      where
        sl.lifecycle_state <> 'TERMINATED'
    )
    select
      case
        when restricted then 'restricted'
        else 'unrestricted'
      end as restrict_ingress_ssh_status,
      count(*)
    from
      sl_list
     group by restricted;
  EOQ
}

query "oci_vcn_security_list_by_ingress_rdp" {
  sql = <<-EOQ
    with non_compliant_rules as (
      select
        id,
        count(*) as num_noncompliant_rules
      from
        oci_core_security_list,
        jsonb_array_elements(ingress_security_rules) as p
      where
        p ->> 'source' = '0.0.0.0/0'
        and (
        (
          p ->> 'protocol' = 'all'
          and (p -> 'tcpOptions' -> 'destinationPortRange' -> 'min') is null
        )
        or (
          p ->> 'protocol' = '6' and
          (p -> 'tcpOptions' -> 'destinationPortRange' ->> 'min')::integer <= 3389
          and (p -> 'tcpOptions' -> 'destinationPortRange' ->> 'max')::integer >= 3389
          )
        )
        and lifecycle_state <> 'TERMINATED'
        group by id
    ),
    sl_list as (
      select
        sl.id,
        case
          when non_compliant_rules.id is null then true
          else false
        end as restricted
      from
        oci_core_security_list as sl
        left join non_compliant_rules on non_compliant_rules.id = sl.id
        left join oci_identity_compartment c on c.id = sl.compartment_id
      where
        sl.lifecycle_state <> 'TERMINATED'
    )
    select
      case
        when restricted then 'restricted'
        else 'unrestricted'
      end as restrict_ingress_rdp_status,
      count(*)
    from
      sl_list
    group by restricted;
  EOQ
}

# Analysis Queries

query "oci_vcn_security_list_by_tenancy" {
  sql = <<-EOQ
    select
      c.title as "Tenancy",
      count(sg.*) as "Security Lists"
    from
      oci_core_security_list as sg,
      oci_identity_tenancy as c
    where
      c.id = sg.tenant_id and lifecycle_state <> 'TERMINATED'
    group by
      c.title
    order by
      c.title;
  EOQ
}

query "oci_vcn_security_list_by_compartment" {
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
      count(l.*) as "Security Lists"
    from
      oci_core_security_list as l,
      compartments as c
    where
      c.id = l.compartment_id and l.lifecycle_state <> 'TERMINATED'
    group by
      c.title
    order by
      c.title;
  EOQ
}

query "oci_vcn_security_list_by_region" {
  sql = <<-EOQ
    select
      region as "Region",
      count(*) as "Security Lists"
    from
      oci_core_security_list
    where
      lifecycle_state <> 'TERMINATED'
    group by
      region
    order by
      region;
  EOQ
}

query "oci_vcn_security_list_by_vcn" {
  sql = <<-EOQ
    select
      v.display_name as "VCN",
      count(*) as "security_lists"
    from
      oci_core_security_list sg
      left join oci_core_vcn v on sg.vcn_id = v.id
    where
      sg.lifecycle_state <> 'TERMINATED'
    group by
      v.display_name
    order by
      v.display_name;
  EOQ
}
