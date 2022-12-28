dashboard "vcn_network_security_group_detail" {

  title         = "OCI VCN Network Security Group Detail"
  documentation = file("./dashboards/vcn/docs/vcn_network_security_group_detail.md")

  tags = merge(local.vcn_common_tags, {
    type = "Detail"
  })

  input "security_group_id" {
    title = "Select a security group:"
    sql   = query.vcn_network_security_group_input.sql
    width = 4
  }

  container {

    card {
      width = 2

      query = query.vcn_network_security_group_ingress_ssh
      args  = [self.input.security_group_id.value]
    }

    card {
      width = 2

      query = query.vcn_network_security_group_ingress_rdp
      args  = [self.input.security_group_id.value]
    }

  }

  with "filestorage_mount_targets" {
    query = query.vcn_network_security_group_filestorage_mount_targets
    args  = [self.input.security_group_id.value]
  }

  with "compute_instances" {
    query = query.vcn_network_security_group_compute_instances
    args  = [self.input.security_group_id.value]
  }

  with "vcn_load_balancers" {
    query = query.vcn_network_security_group_vcn_load_balancers
    args  = [self.input.security_group_id.value]
  }

  with "vcn_network_load_balancers" {
    query = query.vcn_network_security_group_vcn_network_load_balancers
    args  = [self.input.security_group_id.value]
  }

  with "vcn_vcns" {
    query = query.vcn_network_security_group_vcn_vcns
    args  = [self.input.security_group_id.value]
  }

  with "vcn_vnics" {
    query = query.vcn_network_security_group_vcn_vnics
    args  = [self.input.security_group_id.value]
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.filestorage_mount_target
        args = {
          filestorage_mount_target_ids = with.filestorage_mount_targets.rows[*].mount_target_id
        }
      }

      node {
        base = node.compute_instance
        args = {
          compute_instance_ids = with.compute_instances.rows[*].compute_instance_id
        }
      }

      node {
        base = node.vcn_load_balancer
        args = {
          vcn_load_balancer_ids = with.vcn_load_balancers.rows[*].load_balancer_id
        }
      }

      node {
        base = node.vcn_network_load_balancer
        args = {
          vcn_network_load_balancer_ids = with.vcn_network_load_balancers.rows[*].network_load_balancer_id
        }
      }

      node {
        base = node.vcn_network_security_group
        args = {
          vcn_network_security_group_ids = [self.input.security_group_id.value]
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
        base = edge.vcn_network_security_group_to_compute_instance
        args = {
          compute_instance_ids = with.compute_instances.rows[*].compute_instance_id
        }
      }

      edge {
        base = edge.vcn_network_security_group_to_filestorage_mount_target
        args = {
          filestorage_mount_target_ids = with.filestorage_mount_targets.rows[*].mount_target_id
        }
      }

      edge {
        base = edge.vcn_network_security_group_to_vcn_load_balancer
        args = {
          vcn_network_security_group_ids = [self.input.security_group_id.value]
        }
      }

      edge {
        base = edge.vcn_network_security_group_to_vcn_network_load_balancer
        args = {
          vcn_network_security_group_ids = [self.input.security_group_id.value]
        }
      }

      edge {
        base = edge.vcn_network_security_group_to_vcn_vnic
        args = {
          vcn_vnic_ids = with.vcn_vnics.rows[*].vnic_id
        }
      }

      edge {
        base = edge.vcn_vcn_to_vcn_network_security_group
        args = {
          vcn_network_security_group_ids = [self.input.security_group_id.value]
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
        query = query.vcn_network_security_group_overview
        args  = [self.input.security_group_id.value]

      }

      table {
        title = "Tags"
        width = 6

        query = query.vcn_network_security_group_tag
        args  = [self.input.security_group_id.value]

      }

    }

    container {
      width = 6

      table {
        title = "Ingress Rules"
        query = query.vcn_network_security_group_ingress_rule
        args  = [self.input.security_group_id.value]
      }

      table {
        title = "Egress Rules"
        query = query.vcn_network_security_group_egress_rule
        args  = [self.input.security_group_id.value]
      }

    }

  }

}

query "vcn_network_security_group_input" {
  sql = <<-EOQ
    select
      g.display_name as label,
      g.id as value,
      json_build_object(
        'c.name', coalesce(c.title, 'root'),
        'g.region', region,
        't.name', t.name
      ) as tags
    from
      oci_core_network_security_group as g
      left join oci_identity_compartment as c on g.compartment_id = c.id
      left join oci_identity_tenancy as t on g.tenant_id = t.id
    where
      g.lifecycle_state <> 'TERMINATED'
    order by
      g.display_name;
  EOQ
}

query "vcn_network_security_group_ingress_ssh" {
  sql = <<-EOQ
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
      and lifecycle_state <> 'TERMINATED'
      group by id
      )
      select
        case when non_compliant_rules.id is null then 'Restricted' else 'Unrestricted' end as value,
        'Ingress SSH' as label,
        case when non_compliant_rules.id is null then 'ok' else 'alert' end as type
      from
        oci_core_network_security_group as nsg
        left join non_compliant_rules on non_compliant_rules.id = nsg.id
      where
        nsg.id = $1 and nsg.lifecycle_state <> 'TERMINATED';
  EOQ
}

query "vcn_network_security_group_ingress_rdp" {
  sql = <<-EOQ
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
      and lifecycle_state <> 'TERMINATED'
      group by id
      )
      select
        case when non_compliant_rules.id is null then 'Restricted' else 'Unrestricted' end as value,
        'Ingress RDP' as label,
        case when non_compliant_rules.id is null then 'ok' else 'alert' end as type
      from
        oci_core_network_security_group as nsg
        left join non_compliant_rules on non_compliant_rules.id = nsg.id
      where
        nsg.id = $1 and nsg.lifecycle_state <> 'TERMINATED';
  EOQ
}

query "vcn_network_security_group_overview" {
  sql = <<-EOQ
    select
      display_name as "Name",
      time_created as "Time Created",
      region as "Region",
      id as "OCID",
      compartment_id as "Compartment ID"
    from
      oci_core_network_security_group
    where
      id = $1 and lifecycle_state <> 'TERMINATED';
  EOQ
}

query "vcn_network_security_group_tag" {
  sql = <<-EOQ
    with jsondata as (
      select
        tags::json as tags
      from
        oci_core_network_security_group
      where
        id = $1 and lifecycle_state <> 'TERMINATED'
    )
    select
      key as "Key",
      value as "Value"
    from
      jsondata,
      json_each_text(tags)
    order by
      key;
  EOQ
}

query "vcn_network_security_group_ingress_rule" {
  sql = <<-EOQ
    select
      r ->> 'protocol' as "Protocol",
      r ->> 'source' as "Source",
      r ->> 'isStateless' as "Stateless",
      r ->> 'isValid' as "Valid"
    from
      oci_core_network_security_group,
      jsonb_array_elements(rules) as r
    where
    r ->> 'direction' = 'INGRESS' and
      id  = $1 and lifecycle_state <> 'TERMINATED';
  EOQ
}

query "vcn_network_security_group_egress_rule" {
  sql = <<-EOQ
    select
      r ->> 'protocol' as "Protocol",
      r ->> 'destination' as "Destination",
      r ->> 'isStateless' as "Stateless",
      r ->> 'isValid' as "Valid"
    from
      oci_core_network_security_group,
      jsonb_array_elements(rules) as r
    where
      r ->> 'direction' = 'EGRESS' and
      id  = $1 and lifecycle_state <> 'TERMINATED';
  EOQ
}

query "vcn_network_security_group_vcn_vcns" {
  sql = <<-EOQ
    select
      vcn_id
    from
      oci_core_network_security_group
    where
      id = $1;
  EOQ
}

query "vcn_network_security_group_vcn_vnics" {
  sql = <<-EOQ
    with network_security_groups as (
      select
        jsonb_array_elements_text(nsg_ids) as n_id,
        vnic_id
      from
        oci_core_vnic_attachment
    )
    select
      vnic_id
    from
      oci_core_network_security_group,
      network_security_groups
    where
      id = n_id
      and id = $1
  EOQ
}

query "vcn_network_security_group_vcn_load_balancers" {
  sql = <<-EOQ
    with nsg_list as (
      select
        id as nsg_id
      from
        oci_core_network_security_group
      where
        id = $1
      )
      select
        id as load_balancer_id
      from
        oci_core_load_balancer,
        jsonb_array_elements_text(network_security_group_ids) as s
      where
        s in (select nsg_id from nsg_list);
  EOQ
}

query "vcn_network_security_group_vcn_network_load_balancers" {
  sql = <<-EOQ
    with nsg_list as (
      select
        id as nsg_id
      from
        oci_core_network_security_group
      where
        id = $1
      )
      select
        id as network_load_balancer_id
      from
        oci_core_network_load_balancer,
        jsonb_array_elements_text(network_security_group_ids) as s
      where
        s in (select nsg_id from nsg_list);
  EOQ
}

query "vcn_network_security_group_filestorage_mount_targets" {
  sql = <<-EOQ
    with network_security_groups as (
      select
        jsonb_array_elements_text(nsg_ids) as n_id,
        id
      from
        oci_filestorage_mount_target
    )
    select
      s.id as mount_target_id
    from
      oci_core_network_security_group as n,
      network_security_groups as s
    where
      n.id = n_id
      and n.id = $1
  EOQ
}

query "vcn_network_security_group_compute_instances" {
  sql = <<-EOQ
    with network_security_groups as (
      select
        jsonb_array_elements_text(nsg_ids) as n_id,
        instance_id
      from
        oci_core_vnic_attachment
    )
    select
      instance_id as compute_instance_id
    from
      oci_core_network_security_group,
      network_security_groups
    where
      id = n_id
      and id = $1
  EOQ
}
