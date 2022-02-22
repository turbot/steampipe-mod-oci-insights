query "vcn_security_list_by_compartment" {
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
      count(s.*) as "Security Lists" 
    from 
      oci_core_security_list as s,
      compartments as c 
    where 
      c.id = s.compartment_id
    group by 
      compartment
    order by 
      compartment
  EOQ
}

query "vcn_security_list_by_region" {
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

query "oci_security_list_by_creation_month" {
  sql = <<-EOQ
    with databases as (
      select
        title,
        time_created,
        to_char(time_created,
          'YYYY-MM') as creation_month
      from
        oci_core_security_list
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

dashboard "vcn_security_list_dashboard" {

  title = "OCI VCN Security List Dashboard"

  container {

    card {
      width = 2
      sql = <<-EOQ
        select count(*) as "Security Lists" from oci_core_security_list
      EOQ
    }

    card {
      width = 2
      sql = <<-EOQ
        select
          'Ingress Rules' as label,
          count(*) as value
        from
          oci_core_security_list s
        where
          s.ingress_security_rules is not null and
          jsonb_array_length(s.ingress_security_rules) > 0
      EOQ
    }

    card {
      width = 2
      sql = <<-EOQ
        select
          'Egress Rules' as label,
          count(*) as value
        from
          oci_core_security_list s
        where
          s.egress_security_rules is not null and
          jsonb_array_length(s.egress_security_rules) > 0
      EOQ
    }

    card {
      width = 2
      sql = <<-EOQ
        select
          'Ingress Rules Unspecified' as label,
          count(*) as value
        from
          oci_core_security_list s
        where
          s.ingress_security_rules is not null and
          jsonb_array_length(s.ingress_security_rules) = 0
      EOQ
    }

    card {
      width = 2
      sql = <<-EOQ
        select
          'Egress Rules Unspecified' as label,
          count(*) as value
        from
          oci_core_security_list s
        where
          s.egress_security_rules is not null and
          jsonb_array_length(s.egress_security_rules) = 0
      EOQ
    }

  }

  container {

    title = "Analysis"      

    chart {
      title = "Security Lists by Compartment"
      sql = query.vcn_security_list_by_compartment.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Security Lists by Region"
      sql = query.vcn_security_list_by_region.sql
      type  = "column"
      width = 3
    }

    chart {
      title = "Security Lists by VCN"
      sql = <<-EOQ
        select
          v.display_name as "VCN",
          count(*) as "security_lists"
        from
          oci_core_security_list sl
          left join oci_core_vcn v on sl.vcn_id = v.id
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
    
    title = "Resources by Age"

    chart {
      title = "Security List by Creation Month"
      sql   = query.oci_security_list_by_creation_month.sql
      type  = "column"
      width = 3

      series "month" {
        color = "green"
      }
    }
  }

}