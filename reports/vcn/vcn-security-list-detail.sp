dashboard "vcn_security_list_detail" {
  title = "OCI VCN Security List Detail"

  # input {
  #   title = "Security List"
  #   type = "select"
  #   width = 3

  #   sql = <<-EOQ
  #     select
  #       display_name as label,
  #       id as value
  #     from
  #       oci_core_security_list
  #   EOQ
  # }

  container {

    card {
      width = 3
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
        )
        select 
          count(*) as value,
          'Unrestricted SSH ingress access' as label,
          case when count(*) = 0 then 'ok' else 'alert' end as type    
        from 
          non_compliant_rules
      EOQ
    }

    card {
      width = 3
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
        )
        select 
          count(*) as value,
          'Unrestricted RDP ingress access' as label,
          case when count(*) = 0 then 'ok' else 'alert' end as type    
        from 
          non_compliant_rules
      EOQ
    }
  }

  container {

    title  = "Analysis"

    container {

      container {

        table {
          title = "Overview"
          width  = 12
          sql = <<-EOQ
            select
              display_name,
              id,
              vcn_id,
              lifecycle_state,
              title,
              tenant_id
            from
              oci_core_security_list
          EOQ
        }

        table {
          title = "Tags"
          width = 4
          sql = <<-EOQ
            select
              tag.key as "Key",
              tag.value as "Value"
            from
              oci_core_security_list,
              jsonb_each_text(tags) as tag
          EOQ
        }
      }
    }
  }

}