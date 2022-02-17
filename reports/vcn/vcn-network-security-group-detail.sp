dashboard "vcn_network_security_group_detail" {
  title = "OCI VCN Network Security Group Detail"

  input {
    title = "Network Security Group"
    type = "select"
    width = 3

    sql = <<-EOQ
      select 
        display_name as label,
        id as value 
      from 
        oci_core_network_security_group
    EOQ
  }

  container {

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
    title  = "Analysis"

    container {

      container {
        width = 12

        table {
          title = "Overview"
          width = 12

          sql = <<-EOQ
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

          sql = <<-EOQ
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