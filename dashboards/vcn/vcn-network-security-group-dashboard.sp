query "vcn_security_groups_by_compartment" {
  sql = <<-EOQ
    select 
      c.title as "Compartment",
      count(sg.*) as "Security Groups" 
    from 
      oci_core_network_security_group as sg,
      oci_identity_compartment as c 
    where 
      c.id = sg.compartment_id and sg.lifecycle_state <> 'TERMINATED'
    group by 
      c.title
    order by 
      c.title
  EOQ
}

query "vcn_security_groups_by_tenancy" {
  sql = <<-EOQ
    select 
      c.title as "Tenancy",
      count(sg.*) as "Security Groups" 
    from 
      oci_core_network_security_group as sg,
      oci_identity_tenancy as c 
    where 
      c.id = sg.compartment_id and lifecycle_state <> 'TERMINATED'
    group by 
      c.title
    order by 
      c.title
  EOQ
}

query "vcn_security_groups_by_region" {
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
      region
  EOQ
}

dashboard "vcn_network_security_group_dashboard" {
  title = "OCI VCN Network Security Group Dashboard"

  container {

    card {
      width = 2

      sql = <<-EOQ
        select count(*) as "Security Groups" from oci_core_network_security_group where lifecycle_state <> 'TERMINATED'
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
            oci_core_network_security_group,
            jsonb_array_elements(rules) as r
          where
            r ->> 'direction' = 'INGRESS'
            and r ->> 'sourceType' = 'CIDR_BLOCK'
            and r ->> 'source' = '0.0.0.0/0'
            and (
              r ->> 'protocol' = 'all'
              or (
                (r -> 'tcpOptions' -> 'destinationPortRange' ->> 'min')::integer <= 3389
                and (r -> 'tcpOptions' -> 'destinationPortRange' ->> 'max')::integer >= 3389
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
            when restricted then 'Restricted'
            else 'Unrestricted'
          end as restrict_ingress_ssh_status,
          count(*)
        from
          sg_list
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
            oci_core_network_security_group,
            jsonb_array_elements(rules) as r
          where
            r ->> 'direction' = 'INGRESS'
            and r ->> 'sourceType' = 'CIDR_BLOCK'
            and r ->> 'source' = '0.0.0.0/0'
            and (
              r ->> 'protocol' = 'all'
              or (
                (r -> 'tcpOptions' -> 'destinationPortRange' ->> 'min')::integer <= 3389
                and (r -> 'tcpOptions' -> 'destinationPortRange' ->> 'max')::integer >= 3389
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
            when restricted then 'Restricted'
            else 'Unrestricted'
          end as restrict_ingress_rdp_status,
          count(*)
        from
          sg_list
        group by restricted
      EOQ
    }
  }
 
 container {

    title = "Analysis"  

    chart {
      title = "Network Security Groups by Tenancy"
      sql = query.vcn_security_groups_by_tenancy.sql
      type  = "column"
      width = 3
    }    

    chart {
      title = "Network Security Groups by Compartment"
      sql = query.vcn_security_groups_by_compartment.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Network Security Groups by Region"
      sql = query.vcn_security_groups_by_region.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Network Security Groups by VCN"
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
      type  = "column"
      width = 3
    }
  }

}