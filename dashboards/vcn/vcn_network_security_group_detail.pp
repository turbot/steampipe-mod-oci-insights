dashboard "vcn_network_security_group_detail" {

  title         = "OCI VCN Network Security Group Detail"
  documentation = file("./dashboards/vcn/docs/vcn_network_security_group_detail.md")

  tags = merge(local.vcn_common_tags, {
    type = "Detail"
  })

  input "security_group_id" {
    title = "Select a security group:"
    query = query.vcn_network_security_group_input
    width = 4
  }

  container {

    card {
      width = 3
      query = query.vcn_network_security_group_ingress_rules_count
      args  = [self.input.security_group_id.value]
    }

    card {
      width = 3
      query = query.vcn_network_security_group_egress_rules_count
      args  = [self.input.security_group_id.value]
    }

    card {
      width = 3
      query = query.vcn_network_security_group_ingress_ssh
      args  = [self.input.security_group_id.value]
    }

    card {
      width = 3
      query = query.vcn_network_security_group_ingress_rdp
      args  = [self.input.security_group_id.value]
    }

  }

  with "compute_instances_for_vcn_network_security_group" {
    query = query.compute_instances_for_vcn_network_security_group
    args  = [self.input.security_group_id.value]
  }

  with "filestorage_mount_targets_for_vcn_network_security_group" {
    query = query.filestorage_mount_targets_for_vcn_network_security_group
    args  = [self.input.security_group_id.value]
  }

  with "vcn_load_balancers_for_vcn_network_security_group" {
    query = query.vcn_load_balancers_for_vcn_network_security_group
    args  = [self.input.security_group_id.value]
  }

  with "vcn_network_load_balancers_for_vcn_network_security_group" {
    query = query.vcn_network_load_balancers_for_vcn_network_security_group
    args  = [self.input.security_group_id.value]
  }

  with "vcn_vcns_for_vcn_network_security_group" {
    query = query.vcn_vcns_for_vcn_network_security_group
    args  = [self.input.security_group_id.value]
  }

  with "vcn_vnics_for_vcn_network_security_group" {
    query = query.vcn_vnics_for_vcn_network_security_group
    args  = [self.input.security_group_id.value]
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.compute_instance
        args = {
          compute_instance_ids = with.compute_instances_for_vcn_network_security_group.rows[*].compute_instance_id
        }
      }

      node {
        base = node.filestorage_mount_target
        args = {
          filestorage_mount_target_ids = with.filestorage_mount_targets_for_vcn_network_security_group.rows[*].mount_target_id
        }
      }

      node {
        base = node.vcn_load_balancer
        args = {
          vcn_load_balancer_ids = with.vcn_load_balancers_for_vcn_network_security_group.rows[*].load_balancer_id
        }
      }

      node {
        base = node.vcn_network_load_balancer
        args = {
          vcn_network_load_balancer_ids = with.vcn_network_load_balancers_for_vcn_network_security_group.rows[*].network_load_balancer_id
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
          vcn_vcn_ids = with.vcn_vcns_for_vcn_network_security_group.rows[*].vcn_id
        }
      }

      node {
        base = node.vcn_vnic
        args = {
          vcn_vnic_ids = with.vcn_vnics_for_vcn_network_security_group.rows[*].vnic_id
        }
      }

      edge {
        base = edge.vcn_network_security_group_to_compute_instance
        args = {
          vcn_network_security_group_ids = [self.input.security_group_id.value]
        }
      }

      edge {
        base = edge.vcn_network_security_group_to_filestorage_mount_target
        args = {
          vcn_network_security_group_ids = [self.input.security_group_id.value]
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
          vcn_network_security_group_ids = [self.input.security_group_id.value]
        }
      }

      edge {
        base = edge.vcn_vcn_to_vcn_network_security_group
        args = {
          vcn_vcn_ids = with.vcn_vcns_for_vcn_network_security_group.rows[*].vcn_id
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
        title = "Associated to"
        query = query.vcn_network_security_group_assoc
        args  = [self.input.security_group_id.value]

        column "link" {
          display = "none"
        }

        column "Title" {
          href = "{{ .link }}"
        }

      }

    }

    container {
      width = 12

      table {
        title = "Ingress Rules"
        width = 6
        query = query.vcn_network_security_group_ingress_rule
        args  = [self.input.security_group_id.value]
      }

      table {
        title = "Egress Rules"
        width = 6
        query = query.vcn_network_security_group_egress_rule
        args  = [self.input.security_group_id.value]
      }

    }

  }

}

# Input queries

query "vcn_network_security_group_input" {
  sql = <<-EOQ
    select
      g.display_name as label,
      g.id as value,
      json_build_object(
        'b.id', right(reverse(split_part(reverse(g.id), '.', 1)), 8),
        'g.region', region,
        'oci.name', coalesce(oci.title, 'root'),
        't.name', t.name
      ) as tags
    from
      oci_core_network_security_group as g
      left join oci_identity_compartment as oci on g.compartment_id = oci.id
      left join oci_identity_tenancy as t on g.tenant_id = t.id
    where
      g.lifecycle_state <> 'TERMINATED'
    order by
      g.display_name;
  EOQ
}

# With queries

query "compute_instances_for_vcn_network_security_group" {
  sql = <<-EOQ
    select
      instance_id as compute_instance_id
    from
      oci_core_vnic_attachment,
      jsonb_array_elements_text(nsg_ids) as nid
    where
      nid = $1
  EOQ
}

query "filestorage_mount_targets_for_vcn_network_security_group" {
  sql = <<-EOQ
    select
      id as mount_target_id
    from
      oci_file_storage_mount_target,
      jsonb_array_elements_text(nsg_ids) as nid
    where
      nid = $1;
  EOQ
}

query "vcn_load_balancers_for_vcn_network_security_group" {
  sql = <<-EOQ
    select
      id as load_balancer_id
    from
      oci_core_load_balancer,
      jsonb_array_elements_text(network_security_group_ids) as nid
    where
      nid = $1;
  EOQ
}

query "vcn_network_load_balancers_for_vcn_network_security_group" {
  sql = <<-EOQ
    select
      id as network_load_balancer_id
    from
      oci_core_network_load_balancer,
      jsonb_array_elements_text(network_security_group_ids) as nid
    where
      nid = $1;
  EOQ
}

query "vcn_vcns_for_vcn_network_security_group" {
  sql = <<-EOQ
    select
      vcn_id
    from
      oci_core_network_security_group
    where
      id = $1;
  EOQ
}

query "vcn_vnics_for_vcn_network_security_group" {
  sql = <<-EOQ
    select
      vnic_id
    from
      oci_core_vnic_attachment,
      jsonb_array_elements_text(nsg_ids) as nid
    where
      nid = $1;
  EOQ
}

# Card queries

query "vcn_network_security_group_ingress_rules_count" {
  sql = <<-EOQ
    select
      'Ingress Rules' as label,
      count(*) as value
    from
      oci_core_network_security_group,
      jsonb_array_elements(rules) as r
    where
      r ->> 'direction' = 'INGRESS'
      and id = $1;
  EOQ

}

query "vcn_network_security_group_egress_rules_count" {
  sql = <<-EOQ
    select
      'Egress Rules' as label,
      count(*) as value
    from
      oci_core_network_security_group,
      jsonb_array_elements(rules) as r
    where
      r ->> 'direction' = 'EGRESS'
      and id = $1;
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

# Other detail page queries

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

query "vcn_network_security_group_assoc" {
  sql = <<-EOQ

  with nsg_vnic_attachment as (
    select
      jsonb_array_elements_text(nsg_ids) as n_id,
      instance_id as instance_id
    from
      oci_core_vnic_attachment
  )

  -- Compute Instance
  select
    i.title as "Title",
    'oci_core_instance' as "Type",
    i.id as "ID",
    '${dashboard.compute_instance_detail.url_path}?input.instance_id=' || i.id  as link
  from
    nsg_vnic_attachment as g
    left join oci_core_network_security_group as nsg on g.n_id = nsg.id
    left join oci_core_instance as i on i.id = g.instance_id
  where
    nsg.id = $1

    -- File Storage Mount Target
    union all
    select
      title as "Title",
      'oci_file_storage_mount_target' as "Type",
      id as "ID",
      null as link
    from
      oci_file_storage_mount_target,
      jsonb_array_elements_text(nsg_ids) as sg
    where
      sg = $1

    -- Load Balancer
    union all
    select
      title as "Title",
      'oci_core_load_balancer' as "Type",
      id as "ID",
      null as link
    from
      oci_core_load_balancer,
      jsonb_array_elements_text(network_security_group_ids) as sg
    where
      sg = $1

    -- Network Load Balancer
    union all
    select
      title as "Title",
      'oci_core_network_load_balancer' as "Type",
      id as "ID",
      null as link
    from
      oci_core_network_load_balancer,
      jsonb_array_elements_text(network_security_group_ids) as sg
    where
      sg = $1

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
