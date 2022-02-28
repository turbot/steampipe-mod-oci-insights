query "oci_compute_instance_input" {
  sql = <<EOQ
    select
      id as label,
      id as value
    from
      oci_core_instance
    where
      lifecycle_state <> 'TERMINATED'
    order by
      id;
EOQ
}

query "oci_compute_instance_name_for_instance" {
  sql = <<-EOQ
    select
      display_name as "Instance"
    from
      oci_core_instance
    where
      id = $1 and lifecycle_state <> 'TERMINATED';
  EOQ

  param "id" {}
}

query "oci_compute_instance_core_for_instance" {
  sql = <<-EOQ
    select
      shape_config_ocpus as "OCPUs"
    from
      oci_core_instance
    where
      id = $1 and lifecycle_state <> 'TERMINATED';
  EOQ

  param "id" {}
}

query "oci_compute_instance_public_for_instance" {
  sql = <<-EOQ
    select
      case when title = '' then 'false' else 'true' end as value,
      'Public Instance' as label,
      case when title = '' then 'ok' else 'alert' end as type
    from
      oci_core_vnic_attachment
    where
      instance_id = $1 and public_ip is not null;
  EOQ

  param "id" {}
}

dashboard "oci_compute_instance_detail" {
  title = "OCI Compute Instance Detail"

  tags = merge(local.compute_common_tags, {
    type     = "Report"
    category = "Detail"
  })

  input "instance_id" {
    title = "Select a instance:"
    sql   = query.oci_compute_instance_input.sql
    width = 4
  }

  container {

    # Assessments
    card {
      width = 2

      query = query.oci_compute_instance_name_for_instance
      args = {
        id = self.input.instance_id.value
      }
    }

    card {
      width = 2

      query = query.oci_compute_instance_core_for_instance
      args = {
        id = self.input.instance_id.value
      }
    }

    card {
      width = 2

      query = query.oci_compute_instance_public_for_instance
      args = {
        id = self.input.instance_id.value
      }
    }

  }

  container {

    container {
      width = 6

      table {
        title = "Overview"
        type  = "line"
        width = 6

        sql = <<-EOQ
          select
            display_name as "Name",
            time_created as "Time Created",
            availability_domain as "Availability Domain",
            launch_mode as "Launch mode",
            shape_config_memory_in_gbs as "Shape Config Memory In GBs",
            id as "OCID",
            compartment_id as "Compartment ID"
          from
            oci_core_instance
          where
           id = $1 and lifecycle_state <> 'TERMINATED';
        EOQ

        param "id" {}

        args = {
          id = self.input.instance_id.value
        }

      }

      table {
        title = "Tags"
        width = 6

        sql = <<-EOQ
          WITH jsondata AS (
            select
              tags::json as tags
            from
              oci_core_instance
            where
              id = $1 and lifecycle_state <> 'TERMINATED'
          )
          select
            key as "Key",
            value as "Value"
          from
            jsondata,
            json_each_text(tags);
        EOQ

        param "id" {}

        args = {
          id = self.input.instance_id.value
        }

      }
    }

    container {
      width = 6

      table {
        title = "Shape"
        sql   = <<-EOQ
          select
            display_name as "Name",
            shape as "Shape",
            shape_config_max_vnic_attachments as "Shape Config Max Vnic Attachments"
          from
            oci_core_instance
          where
           id  = $1 and lifecycle_state <> 'TERMINATED';
        EOQ

        param "id" {}

        args = {
          id = self.input.instance_id.value
        }
      }

      table {
        title = "Launch Options"
        sql   = <<-EOQ
          select
            launch_options ->> 'bootVolumeType' as "Boot Volume Type",
            launch_options ->> 'firmware' as "Firmware",
            launch_options ->> 'isPvEncryptionInTransitEnabled' as "Pv Encryption In Transit Enabled"
          from
            oci_core_instance
          where
           id  = $1 and lifecycle_state <> 'TERMINATED';
        EOQ

        param "id" {}

        args = {
          id = self.input.instance_id.value
        }
      }
    }

  }
}
