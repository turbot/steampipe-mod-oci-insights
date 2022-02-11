report vcn_network_security_group_detail {
  title = "OCI VCN Network Security Group Detail"

  input {
    title = "Network Security Group"
    type = "select"
    sql = <<-EOQ
      select 
        display_name as label,
        id as value 
      from 
        oci_core_network_security_group
    EOQ
    width = 3
  }

  container {

    card {
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
      width = 2
    }

    card {
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
      width = 2
    }

  }

  container {
    title  = "Analysis"

    container {

      container {
        width = 6 

        table {
          title = "Overview"

          sql   = <<-EOQ
            select
              display_name,
              id,
              vcn_id,
              title,
              tenant_id
            from
              oci_core_network_security_group
          EOQ
        }

        table {
          title = "Tags"

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