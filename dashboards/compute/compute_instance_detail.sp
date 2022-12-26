dashboard "compute_instance_detail" {

  title = "OCI Compute Instance Detail"

  tags = merge(local.compute_common_tags, {
    type = "Detail"
  })

  input "instance_id" {
    title = "Select an instance:"
    query = query.compute_instance_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.compute_instance_state
      args = [self.input.instance_id.value]
    }

    card {
      width = 2
      query = query.compute_instance_shape
      args = [self.input.instance_id.value]
    }

    card {
      width = 2
      query = query.compute_instance_core
      args = [self.input.instance_id.value]
    }

    card {
      width = 2
      query = query.compute_instance_public
      args = [self.input.instance_id.value]
    }

    card {
      width = 2
      query = query.compute_instance_monitoring
      args = [self.input.instance_id.value]
    }
  }

  with "autoscaling_auto_scaling_configurations" {
    query = query.compute_instance_autoscaling_auto_scaling_configurations
    args  = [self.input.instance_id.value]
  }

  with "blockstorage_block_volumes" {
    query = query.compute_instance_blockstorage_block_volumes
    args  = [self.input.instance_id.value]
  }

  with "blockstorage_boot_volumes" {
    query = query.compute_instance_blockstorage_boot_volumes
    args  = [self.input.instance_id.value]
  }

  with "compute_images" {
    query = query.compute_instance_compute_images
    args  = [self.input.instance_id.value]
  }

  with "vcn_load_balancers" {
    query = query.compute_instance_vcn_load_balancers
    args  = [self.input.instance_id.value]
  }

  with "vcn_network_load_balancers" {
    query = query.compute_instance_vcn_network_load_balancers
    args  = [self.input.instance_id.value]
  }

  with "vcn_network_security_groups" {
    query = query.compute_instance_vcn_network_security_groups
    args  = [self.input.instance_id.value]
  }

  with "vcn_subnets" {
    query = query.compute_instance_vcn_subnets
    args  = [self.input.instance_id.value]
  }

  with "vcn_vcns" {
    query = query.compute_instance_vcn_vcns
    args  = [self.input.instance_id.value]
  }

  with "vcn_vnics" {
    query = query.compute_instance_vcn_vnics
    args  = [self.input.instance_id.value]
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.autoscaling_auto_scaling_configuration
        args = {
          autoscaling_auto_scaling_configuration_ids = with.autoscaling_auto_scaling_configurations.rows[*].auto_scaling_config_id
        }
      }

      node {
        base = node.blockstorage_block_volume
        args = {
          blockstorage_block_volume_ids = with.blockstorage_block_volumes.rows[*].block_volume_id
        }
      }

      node {
        base = node.blockstorage_boot_volume
        args = {
          blockstorage_boot_volume_ids = with.blockstorage_boot_volumes.rows[*].boot_volume_id
        }
      }

      node {
        base = node.compute_image
        args = {
          compute_image_ids = with.compute_images.rows[*].image_id
        }
      }

      node {
        base = node.compute_instance
        args = {
          compute_instance_ids = [self.input.instance_id.value]
        }
      }

      node {
        base = node.vcn_network_security_group
        args = {
          vcn_network_security_group_ids = with.vcn_network_security_groups.rows[*].nsg_id
        }
      }

      node {
        base = node.vcn_load_balancer
        args = {
          vcn_load_balancer_ids = with.vcn_load_balancers.rows[*].lb_id
        }
      }

      node {
        base = node.vcn_network_load_balancer
        args = {
          vcn_network_load_balancer_ids = with.vcn_network_load_balancers.rows[*].nlb_id
        }
      }

      node {
        base = node.vcn_subnet
        args = {
          vcn_subnet_ids = with.vcn_subnets.rows[*].subnet_id
        }
      }

      node {
        base = node.vcn_vcn
        args = {
          vcn_vcn_ids = with.vcn_vcns.rows[*].vcn_id
        }
      }

      node {
        base = node.vcn_vnic
        args = {
          vcn_vnic_ids = with.vcn_vnics.rows[*].vnic_id
        }
      }

      edge {
        base = edge.autoscaling_auto_scaling_configuration_to_compute_instance
        args = {
          compute_instance_ids = [self.input.instance_id.value]
        }
      }

      edge {
        base = edge.compute_instance_to_blockstorage_block_volume
        args = {
          compute_instance_ids = [self.input.instance_id.value]
        }
      }

      edge {
        base = edge.compute_instance_to_blockstorage_boot_volume
        args = {
          compute_instance_ids = [self.input.instance_id.value]
        }
      }

      edge {
        base = edge.compute_instance_to_compute_image
        args = {
          compute_instance_ids = [self.input.instance_id.value]
        }
      }

      edge {
        base = edge.compute_instance_to_vcn_network_security_group
        args = {
          compute_instance_ids = [self.input.instance_id.value]
        }
      }

      edge {
        base = edge.compute_instance_to_vcn_load_balancer
        args = {
          compute_instance_ids = [self.input.instance_id.value]
        }
      }

      edge {
        base = edge.compute_instance_to_vcn_network_load_balancer
        args = {
          compute_instance_ids = [self.input.instance_id.value]
        }
      }

      edge {
        base = edge.compute_instance_to_vcn_subnet
        args = {
          compute_instance_ids = [self.input.instance_id.value]
        }
      }

      edge {
        base = edge.compute_instance_to_vcn_vnic
        args = {
          compute_instance_ids = [self.input.instance_id.value]
        }
      }

      edge {
        base = edge.vcn_subnet_to_vcn_vcn
        args = {
          vcn_subnet_ids = with.vcn_subnets.rows[*].subnet_id
        }
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
        query = query.compute_instance_overview
        args = [self.input.instance_id.value]
      }

      table {
        title = "Tags"
        width = 6
        query = query.compute_instance_tag
        args = [self.input.instance_id.value]
      }
    }

    container {
      width = 6

      table {
        title = "Launch Options"
        query = query.compute_instance_launch_options
        args = [self.input.instance_id.value]
      }

    }

    container {

      table {
        title = "Virtual Network Interface Card (VNIC) Details"
        query = query.compute_instance_vnic
        args = [self.input.instance_id.value]
      }

    }
  }

}

query "compute_instance_input" {
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

query "compute_instance_state" {
  sql = <<-EOQ
    select
      'State' as label,
      initcap(lifecycle_state) as value
    from
      oci_core_instance
    where
      id = $1;
  EOQ
}

query "compute_instance_shape" {
  sql = <<-EOQ
    select
      'Shape' as label,
      shape as value
    from
      oci_core_instance
    where
      id = $1;
  EOQ
}

query "compute_instance_core" {
  sql = <<-EOQ
    select
      shape_config_ocpus as "OCPUs"
    from
      oci_core_instance
    where
      id = $1;
  EOQ
}

query "compute_instance_public" {
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
}

query "compute_instance_monitoring" {
  sql = <<-EOQ
    with instance_monitoring as (
      select
        distinct display_name
      from
        oci_core_instance,
        jsonb_array_elements(agent_config -> 'pluginsConfig') as config
      where
        config ->> 'name' = 'Compute Instance Monitoring'
        and config ->> 'desiredState' = 'ENABLED'
    )
    select
      'Monitoring' as label,
      case when m.display_name is null then 'Disabled' else 'Enabled' end as value,
      case when m.display_name is null then 'alert' else 'ok' end as type
    from
      oci_core_instance as i
      left join instance_monitoring as m on i.display_name = m.display_name
    where
      i.id = $1;
  EOQ
}

query "compute_instance_overview" {
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
}

query "compute_instance_tag" {
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
}

query "compute_instance_launch_options" {
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
}

query "compute_instance_vnic" {
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
}

query "compute_instance_vcn_subnets" {
  sql = <<-EOQ
    select
      s.id as subnet_id
    from
      oci_core_instance as i,
      oci_core_subnet as s,
      oci_core_vnic_attachment as v
    where
      v.instance_id = i.id
      and v.subnet_id = s.id
      and i.id = $1;
  EOQ
}

query "compute_instance_vcn_vcns" {
  sql = <<-EOQ
    select
      s.vcn_id as vcn_id
    from
      oci_core_instance as i,
      oci_core_subnet as s,
      oci_core_vnic_attachment as v
    where
      v.instance_id = i.id
      and v.subnet_id = s.id
      and i.id = $1;
  EOQ
}

query "compute_instance_blockstorage_boot_volumes" {
  sql = <<-EOQ
    select
      boot_volume_id
    from
      oci_core_boot_volume_attachment
    where
      instance_id = $1;
  EOQ
}

query "compute_instance_blockstorage_block_volumes" {
  sql = <<-EOQ
    select
      volume_id as block_volume_id
    from
      oci_core_volume_attachment
    where
      instance_id = $1;
  EOQ
}

query "compute_instance_vcn_network_security_groups" {
  sql = <<-EOQ
    with network_security_groups as (
      select
        jsonb_array_elements_text(nsg_ids) as n_id,
        instance_id
      from
        oci_core_vnic_attachment
    )
    select
      n_id as nsg_id
    from
      oci_core_network_security_group,
      network_security_groups
    where
      id = n_id
      and instance_id = $1
  EOQ
}

query "compute_instance_vcn_vnics" {
  sql = <<-EOQ
    select
      vnic_id
    from
      oci_core_vnic_attachment
    where
      lifecycle_state = 'ATTACHED'
      and instance_id = $1
  EOQ
}

query "compute_instance_vcn_load_balancers" {
  sql = <<-EOQ
    with subnet_list as (
      select
        jsonb_array_elements_text(subnet_ids) as subnet_id,
        id
      from
        oci_core_load_balancer
    )
    select
      s.id as lb_id
    from
      oci_core_vnic_attachment as a,
      subnet_list as s
    where
      s.subnet_id = a.subnet_id
      and a.instance_id = $1;
  EOQ
}

query "compute_instance_vcn_network_load_balancers" {
  sql = <<-EOQ
    select
      n.id as nlb_id
    from
      oci_core_vnic_attachment as a,
      oci_core_network_load_balancer as n
    where
      n.subnet_id = a.subnet_id
      and a.instance_id = $1;
  EOQ
}

query "compute_instance_autoscaling_auto_scaling_configurations" {
  sql = <<-EOQ
    with intance_pool_id as (
      select
        tags ->> 'oci:compute:instancepool' as instance_pool_id,
        id
      from
        oci_core_instance
    )
    select
      a.id as auto_scaling_config_id
    from
      oci_autoscaling_auto_scaling_configuration as a,
      intance_pool_id as i
    where
      instance_pool_id = resource ->> 'id'
      and i.id = $1
  EOQ
}

query "compute_instance_compute_images" {
  sql = <<-EOQ
    select
      source_details ->> 'imageId' as image_id
    from
      oci_core_instance
    where
      id = $1
  EOQ
}