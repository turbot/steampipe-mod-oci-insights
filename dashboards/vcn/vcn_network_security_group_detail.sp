dashboard "vcn_network_security_group_detail" {
  title = "OCI VCN Network Security Group Detail"

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

    title = "Analysis"

    container {

      container {
        width = 12
        table {
          title = "Overview"
          width = 12
          sql   = <<-EOQ
            select
              display_name,
              id,
              vcn_id,
              lifecycle_state,
              title,
              tenant_id
            from
              oci_core_network_security_group
          EOQ
        }

        table {
          title = "Tags"
          width = 4
          sql   = <<-EOQ
            select
              tag.key as "Key",
              tag.value as "Value"
            from
              oci_core_network_security_group,
              jsonb_each_text(tags) as tag
          EOQ
        }
      }
    }
  }

}
