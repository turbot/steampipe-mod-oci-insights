dashboard "vcn_subnet_detail" {
  title = "OCI VCN Subnet Detail"

  # input {
  #   title = "Subnet List"
  #   type = "select"
  #   sql = <<-EOQ
  #     select
  #       display_name as label,
  #       id as value
  #     from
  #       oci_core_subnet
  #   EOQ
  #   width = 3
  # }

  container {

    card {
      width = 2
      sql = <<-EOQ
        select
          count(*) as value,
          'Public IP not prohibited on VNIC' as label,
          case when count(*) = 0 then 'ok' else 'alert' end as type
        from
          oci_core_subnet
        where
          not prohibit_public_ip_on_vnic
      EOQ
    }

    card {
      width = 2
      sql = <<-EOQ
        select
          count(*) as value,
          'Flow Logs not Configured' as label,
          case when count(*) = 0 then 'ok' else 'alert' end as type
        from
          oci_logging_log
        where
          (configuration -> 'source' ->> 'resource') not like 'ocid1.subnet.oc1%'
      EOQ
    }
  }

  container {

    title  = "Analysis"

    container {

      container {

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
              oci_core_subnet
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
              oci_core_subnet,
              jsonb_each_text(tags) as tag
          EOQ
        }
      }
    }
  }

}