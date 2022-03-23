dashboard "oci_compute_instance_detail" {

  title = "OCI Compute Instance Detail"

  tags = merge(local.compute_common_tags, {
    type = "Detail"
  })

  input "instance_id" {
    title = "Select a instance:"
    query = query.oci_compute_instance_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.oci_compute_instance_state
      args = {
        id = self.input.instance_id.value
      }
    }

    card {
      width = 2
      query = query.oci_compute_instance_shape
      args = {
        id = self.input.instance_id.value
      }
    }

    card {
      width = 2
      query = query.oci_compute_instance_core
      args = {
        id = self.input.instance_id.value
      }
    }

    card {
      width = 2
      query = query.oci_compute_instance_public
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
        query = query.oci_compute_instance_overview
        args = {
          id = self.input.instance_id.value
        }
      }

      table {
        title = "Tags"
        width = 6
        query = query.oci_compute_instance_tag
        args = {
          id = self.input.instance_id.value
        }
      }
    }

    container {
      width = 6

      table {
        title = "Launch Options"
        query = query.oci_compute_instance_launch_options
        args = {
          id = self.input.instance_id.value
        }
      }

    }

    container {

      table {
        title = "Virtual Network Interface Card (VNIC) Details"
        query = query.oci_compute_instance_vnic
        args = {
          id = self.input.instance_id.value
        }
      }

    }
  }

}

query "oci_compute_instance_input" {
  sql = <<EOQ
    select
      i.display_name as label,
      i.id as value,
      json_build_object(
        'c.name', coalesce(c.title, 'root'),
        'i.region', region,
        't.name', t.name
      ) as tags
    from
      oci_core_instance as i
      left join oci_identity_compartment as c on i.compartment_id = c.id
      left join oci_identity_tenancy as t on i.tenant_id = t.id
    where
      i.lifecycle_state <> 'TERMINATED'
    order by
      i.display_name;
EOQ
}

query "oci_compute_instance_state" {
  sql = <<-EOQ
    select
      'State' as label,
      initcap(lifecycle_state) as value
    from
      oci_core_instance
    where
      id = $1;
  EOQ

  param "id" {}

}

query "oci_compute_instance_shape" {
  sql = <<-EOQ
    select
      'Shape' as label,
      shape as value
    from
      oci_core_instance
    where
      id = $1;
  EOQ

  param "id" {}

}

query "oci_compute_instance_core" {
  sql = <<-EOQ
    select
      shape_config_ocpus as "OCPUs"
    from
      oci_core_instance
    where
      id = $1;
  EOQ

  param "id" {}
}

query "oci_compute_instance_public" {
  sql = <<-EOQ
    select
      case when title = '' then 'Disabled' else 'Enabled' end as value,
      'Public Access' as label,
      case when title = '' then 'ok' else 'alert' end as type
    from
      oci_core_vnic_attachment
    where
      instance_id = $1 and public_ip is not null;
  EOQ

  param "id" {}
}

query "oci_compute_instance_overview" {
  sql = <<-EOQ
    select
      display_name as "Name",
      time_created as "Time Created",
      availability_domain as "Availability Domain",
      fault_domain as "Fault Domain",
      id as "OCID",
      compartment_id as "Compartment ID"
    from
      oci_core_instance
    where
      id = $1;
  EOQ

  param "id" {}
}

query "oci_compute_instance_tag" {
  sql = <<-EOQ
    with jsondata as (
    select
      tags::json as tags
    from
      oci_core_instance
    where
      id = $1
    )
    select
      key as "Key",
      value as "Value"
    from
      jsondata,
      json_each_text(tags);
  EOQ

  param "id" {}
}

query "oci_compute_instance_launch_options" {
  sql = <<-EOQ
    select
      launch_options ->> 'bootVolumeType' as "Boot Volume Type",
      launch_options ->> 'firmware' as "Firmware",
      launch_options ->> 'isPvEncryptionInTransitEnabled' as "Pv Encryption In Transit Enabled"
    from
      oci_core_instance
    where
      id  = $1;
  EOQ

  param "id" {}
}

query "oci_compute_instance_vnic" {
  sql = <<-EOQ
    select
      vnic_name as "VNIC Name",
      private_ip as "Private IP",
      public_ip as "Public IP",
      time_created as "Time Created",
      hostname_label as "Hostname Label",
      is_primary as "Primary",
      mac_address as "MAC Address"
    from
      oci_core_vnic_attachment
    where
      instance_id = $1 and public_ip is not null;
  EOQ

  param "id" {}
}
