dashboard "vcn_security_list_detail" {
  title = "OCI VCN Security List Detail"

  input {
    title = "Security List"
    type = "select"
    width = 3

    sql = <<-EOQ
      select 
        display_name as label,
        id as value 
      from 
        oci_core_security_list
    EOQ
  }

  container {

    card {
      width = 3

      sql = <<-EOQ
        select 
          'Ingress Security Rules' as label,
          count(*) as value
        from
          oci_core_security_list s
        where
          s.ingress_security_rules is not null and
          jsonb_array_length(s.ingress_security_rules) > 0
      EOQ
    }

    card {
      width = 3

      sql = <<-EOQ
        select
          'Egress Security Rules' as label,
          count(*) as value     
        from
          oci_core_security_list s
        where
          s.egress_security_rules is not null and
          jsonb_array_length(s.egress_security_rules) > 0
      EOQ
    }

    card {
      width = 3

      sql = <<-EOQ
        select 
          'Ingress Security Rules Unspecified' as label,
          count(*) as value
        from
          oci_core_security_list s
        where
          s.ingress_security_rules is not null and
          jsonb_array_length(s.ingress_security_rules) = 0
      EOQ
    }

    card {
      width = 3

      sql = <<-EOQ
        select
          'Egress Security Rules Unspecified' as label,
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