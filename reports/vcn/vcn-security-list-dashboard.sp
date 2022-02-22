query "vcn_security_lists_by_compartment" {
  sql = <<-EOQ
    select 
      c.title as "Compartment",
      count(sg.*) as "Security Lists" 
    from 
      oci_core_security_list as sg,
      oci_identity_compartment as c 
    where 
      c.id = sg.compartment_id
    group by 
      c.title
    order by 
      c.title
  EOQ
}

query "vcn_security_lists_by_tenancy" {
  sql = <<-EOQ
    select 
      c.title as "Tenancy",
      count(sg.*) as "Security Lists" 
    from 
      oci_core_security_list as sg,
      oci_identity_tenancy as c 
    where 
      c.id = sg.compartment_id
    group by 
      c.title
    order by 
      c.title
  EOQ
}

query "vcn_security_lists_by_region" {
  sql = <<-EOQ
    select
      region as "Region",
      count(*) as "Security Lists" 
    from 
      oci_core_security_list 
    group by 
      region 
    order by 
      region
  EOQ
}

dashboard "vcn_network_security_list_dashboard" {
  title = "OCI VCN Network Security List Dashboard"

  container {

    card {
      width = 2

      sql = <<-EOQ
        select count(*) as "Security Groups" from oci_core_security_list
      EOQ
    }

    card {
      width = 2

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
        )
        select
          count(*) as value,
          'Unrestricted Ingress SSH' as label,
          case count(*) when 0 then 'ok' else 'alert' end as type
        from
          sl_list
        where not restricted
      EOQ
    }

    card {
      width = 2

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
        )
        select
          count(*) as value,
          'Unrestricted Ingress RDP' as label,
          case count(*) when 0 then 'ok' else 'alert' end as type
        from
          sl_list
        where
          not restricted
      EOQ
    }

  }

  container {

    title = "Assessments"

    chart {
      title = "Ingress SSH Status"
      type  = "donut"
      width = 3
      sql   = <<-EOQ
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
        )
        select
          case
            when restricted then 'Restricted'
            else 'Unrestricted'
          end as restrict_ingress_ssh_status,
          count(*)
        from
          sl_list
        group by restricted
      EOQ
    }

    chart {
      title = "Ingress RDP Status"
      type  = "donut"
      width = 3
      sql   = <<-EOQ
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
        )
        select
          case
            when restricted then 'Restricted'
            else 'Unrestricted'
          end as restrict_ingress_rdp_status,
          count(*)
        from
          sl_list
        group by restricted
      EOQ
    }
  }
 
 container {

    title = "Analysis"  

    chart {
      title = "Network Security Lists by Tenancy"
      sql = query.vcn_security_lists_by_tenancy.sql
      type  = "column"
      width = 3
    }    

    chart {
      title = "Network Security Lists by Compartment"
      sql = query.vcn_security_lists_by_compartment.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Network Security Lists by Region"
      sql = query.vcn_security_lists_by_region.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Network Security Lists by VCN"
      sql = <<-EOQ
        select
          v.display_name as "VCN",
          count(*) as "security_lists"
        from
          oci_core_security_list sg
          left join oci_core_vcn v on sg.vcn_id = v.id
        group by v.display_name
        order by v.display_name;
      EOQ
      type  = "column"
      width = 3
    }
  }

}