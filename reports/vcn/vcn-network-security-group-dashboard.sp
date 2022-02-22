query "vcn_security_groups_by_compartment" {
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
      count(sg.*) as "Security Lists" 
    from 
      oci_core_network_security_group as sg,
      compartments as c 
    where 
      c.id = sg.compartment_id
    group by 
      compartment
    order by 
      compartment
  EOQ
}

query "vcn_security_groups_by_region" {
  sql = <<-EOQ
    select
      region as "Region",
      count(*) as "Security Lists" 
    from 
      oci_core_network_security_group 
    group by 
      region 
    order by 
      region
  EOQ
}

query "oci_security_groups_by_creation_month" {
  sql = <<-EOQ
    with databases as (
      select
        title,
        time_created,
        to_char(time_created,
          'YYYY-MM') as creation_month
      from
        oci_core_network_security_group
    ),
    months as (
      select
        to_char(d,
          'YYYY-MM') as month
      from
        generate_series(date_trunc('month',
            (
              select
                min(time_created)
                from databases)),
            date_trunc('month',
              current_date),
            interval '1 month') as d
    ),
    databases_by_month as (
      select
        creation_month,
        count(*)
      from
        databases
      group by
        creation_month
    )
    select
      months.month,
      databases_by_month.count
    from
      months
      left join databases_by_month on months.month = databases_by_month.creation_month
    order by
      months.month desc;
  EOQ
}

dashboard "vcn_network_security_group_dashboard" {
  title = "OCI VCN Network Security Group Dashboard"

  # input {
  #   title = "Network Security Group"
  #   type = "select"
  #   width = 3

  #   sql = <<-EOQ
  #     select
  #       display_name as label,
  #       id as value 
  #     from
  #       oci_core_network_security_group
  #   EOQ
  # }

  container {

    card {
      width = 2

      sql = <<-EOQ
        select count(*) as "Security Groups" from oci_core_network_security_group
      EOQ
    }

    card {
      width = 2

      sql = <<-EOQ
        select
          'Ingress Rules' as label,
          count(*) as value
        from
          oci_core_network_security_group g,
          jsonb_array_elements(g.rules) as r
        where
          r is not null and (r ->> 'direction') = 'INGRESS'
      EOQ
    }

    card {
      width = 2

      sql = <<-EOQ
        select
          'Egress Rules' as label,
          count(*) as value
        from
          oci_core_network_security_group g,
          jsonb_array_elements(g.rules) as r
        where
          r is not null and (r ->> 'direction') = 'EGRESS'
      EOQ
    }

  }

  container {

    title = "Analysis"      

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
      title = "Security Groups by VCN"
      sql = <<-EOQ
        select
          v.display_name as "VCN",
          count(*) as "security_groups"
        from
          oci_core_network_security_group sg
          left join oci_core_vcn v on sg.vcn_id = v.id
        group by v.display_name
        order by v.display_name;
      EOQ
      type  = "column"
      width = 3
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
    
    title = "Resources by Age"

    chart {
      title = "Security Groups by Creation Month"
      sql   = query.oci_security_groups_by_creation_month.sql
      type  = "column"
      width = 3

      series "month" {
        color = "green"
      }
    }
  }

}