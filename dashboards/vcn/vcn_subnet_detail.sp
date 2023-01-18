dashboard "vcn_subnet_detail" {

  title         = "OCI VCN Subnet Detail"
  documentation = file("./dashboards/vcn/docs/vcn_subnet_detail.md")

  tags = merge(local.vcn_common_tags, {
    type = "Detail"
  })

  input "subnet_id" {
    title = "Select a subnet:"
    sql   = query.vcn_subnet_input.sql
    width = 4
  }

  container {

    card {
      width = 2
      query = query.vcn_subnet_flow_logs
      args  = [self.input.subnet_id.value]
    }

  }

  with "compute_instances" {
    query = query.vcn_subnet_compute_instances
    args  = [self.input.subnet_id.value]
  }

  with "identity_availability_domains" {
    query = query.vcn_subnet_identity_availability_domains
    args  = [self.input.subnet_id.value]
  }

  with "regional_identity_availability_domains" {
    query = query.vcn_subnet_regional_identity_availability_domains
    args  = [self.input.subnet_id.value]
  }

  with "vcn_dhcp_options" {
    query = query.vcn_subnet_vcn_dhcp_options
    args  = [self.input.subnet_id.value]
  }

  with "vcn_flow_logs" {
    query = query.vcn_subnet_vcn_flow_logs
    args  = [self.input.subnet_id.value]
  }

  with "vcn_load_balancers" {
    query = query.vcn_subnet_vcn_load_balancers
    args  = [self.input.subnet_id.value]
  }

  with "vcn_network_load_balancers" {
    query = query.vcn_subnet_vcn_network_load_balancers
    args  = [self.input.subnet_id.value]
  }

  with "vcn_route_tables" {
    query = query.vcn_subnet_vcn_route_tables
    args  = [self.input.subnet_id.value]
  }

  with "vcn_security_lists" {
    query = query.vcn_subnet_vcn_security_lists
    args  = [self.input.subnet_id.value]
  }

  with "vcn_vcns" {
    query = query.vcn_subnet_vcn_vcns
    args  = [self.input.subnet_id.value]
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.compute_instance
        args = {
          compute_instance_ids = with.compute_instances.rows[*].compute_instance_id
        }
      }

      node {
        base = node.identity_availability_domain
        args = {
          availability_domain_ids = with.identity_availability_domains.rows[*].availability_domain_id
        }
      }

      node {
        base = node.regional_identity_availability_domain
        args = {
          availability_domain_ids = with.regional_identity_availability_domains.rows[*].availability_domain_id
        }
      }

      node {
        base = node.vcn_dhcp_option
        args = {
          vcn_dhcp_option_ids = with.vcn_dhcp_options.rows[*].dhcp_options_id
        }
      }

      node {
        base = node.vcn_flow_log
        args = {
          vcn_flow_log_ids = with.vcn_flow_logs.rows[*].flow_log_id
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
        base = node.vcn_route_table
        args = {
          vcn_route_table_ids = with.vcn_route_tables.rows[*].route_table_id
        }
      }

      node {
        base = node.vcn_security_list
        args = {
          vcn_security_list_ids = with.vcn_security_lists.rows[*].security_list_id
        }
      }

      node {
        base = node.vcn_subnet
        args = {
          vcn_subnet_ids = [self.input.subnet_id.value]
        }
      }

      node {
        base = node.vcn_vcn
        args = {
          vcn_vcn_ids = with.vcn_vcns.rows[*].vcn_id
        }
      }

      edge {
        base = edge.vcn_availability_domain_to_vcn_regional_subnet
        args = {
          vcn_subnet_ids = [self.input.subnet_id.value]
        }
      }

      edge {
        base = edge.identity_availability_domain_to_vcn_subnet
        args = {
          vcn_subnet_ids = [self.input.subnet_id.value]
        }
      }

      edge {
        base = edge.vcn_subnet_to_compute_instance
        args = {
          compute_instance_ids = with.compute_instances.rows[*].compute_instance_id
        }
      }

      edge {
        base = edge.vcn_subnet_to_vcn_dhcp_option
        args = {
          vcn_subnet_ids = [self.input.subnet_id.value]
        }
      }

      edge {
        base = edge.vcn_subnet_to_vcn_flow_log
        args = {
          vcn_flow_log_ids = with.vcn_flow_logs.rows[*].flow_log_id
        }
      }

      edge {
        base = edge.vcn_subnet_to_vcn_load_balancer
        args = {
          vcn_subnet_ids = [self.input.subnet_id.value]
        }
      }

      edge {
        base = edge.vcn_subnet_to_vcn_network_load_balancer
        args = {
          vcn_network_load_balancer_ids = with.vcn_network_load_balancers.rows[*].network_load_balancer_id
        }
      }

      edge {
        base = edge.vcn_subnet_to_vcn_route_table
        args = {
          vcn_route_table_ids = with.vcn_route_tables.rows[*].route_table_id
        }
      }

      edge {
        base = edge.vcn_subnet_to_vcn_security_list
        args = {
          vcn_security_list_ids = with.vcn_security_lists.rows[*].security_list_id
        }
      }

      edge {
        base = edge.vcn_vcn_to_identity_availability_domain
        args = {
          vcn_vcn_ids = with.vcn_vcns.rows[*].vcn_id
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
        query = query.vcn_subnet_overview
        args  = [self.input.subnet_id.value]

      }

      table {
        title = "Tags"
        width = 6
        query = query.vcn_subnet_tag
        args  = [self.input.subnet_id.value]

      }
    }

    container {
      width = 6

      table {
        title = "CIDR Block"
        query = query.vcn_subnet_cidr_block
        args  = [self.input.subnet_id.value]
      }

    }

  }
}

# Input queries

query "vcn_subnet_input" {
  sql = <<-EOQ
    select
      s.display_name as label,
      s.id as value,
      json_build_object(
        'c.name', coalesce(c.title, 'root'),
        's.region', region,
        't.name', t.name
      ) as tags
    from
      oci_core_subnet as s
      left join oci_identity_compartment as c on s.compartment_id = c.id
      left join oci_identity_tenancy as t on s.tenant_id = t.id
    where
      s.lifecycle_state <> 'TERMINATED'
    order by
      s.display_name;
  EOQ
}

# With queries

query "vcn_subnet_vcn_dhcp_options" {
  sql = <<-EOQ
    select
      dhcp_options_id
    from
      oci_core_subnet
    where
      id  = $1;
  EOQ
}

query "vcn_subnet_vcn_route_tables" {
  sql = <<-EOQ
    select
      route_table_id
    from
      oci_core_subnet
    where
      id  = $1;
  EOQ
}

query "vcn_subnet_vcn_vcns" {
  sql = <<-EOQ
    select
      vcn_id
    from
      oci_core_subnet
    where
      id  = $1;
  EOQ
}

query "vcn_subnet_vcn_load_balancers" {
  sql = <<-EOQ
    select
      id as load_balancer_id
    from
      oci_core_load_balancer,
      jsonb_array_elements_text(subnet_ids) as sid
    where
      sid = $1;
  EOQ
}

query "vcn_subnet_vcn_network_load_balancers" {
  sql = <<-EOQ
    select
      id as network_load_balancer_id
    from
      oci_core_network_load_balancer
    where
      subnet_id = $1;
  EOQ
}

query "vcn_subnet_vcn_flow_logs" {
  sql = <<-EOQ
    select
      id as flow_log_id
    from
      oci_logging_log
    where
      configuration -> 'source' ->> 'service' = 'flowlogs'
      and configuration -> 'source' ->> 'resource' = $1;
  EOQ
}

query "vcn_subnet_vcn_security_lists" {
  sql = <<-EOQ
    select
      sid as security_list_id
    from
      oci_core_subnet,
      jsonb_array_elements_text(security_list_ids) as sid
    where
      id = $1
  EOQ
}

query "vcn_subnet_compute_instances" {
  sql = <<-EOQ
    select
      instance_id as compute_instance_id
    from
      oci_core_vnic_attachment
    where
      subnet_id = $1;
  EOQ
}

query "vcn_subnet_identity_availability_domains" {
  sql = <<-EOQ
    select
      a.id as availability_domain_id
    from
      oci_identity_availability_domain as a,
      oci_core_subnet as s
    where
      s.availability_domain = a.name
      and s.id = $1;
  EOQ
}

query "vcn_subnet_regional_identity_availability_domains" {
  sql = <<-EOQ
    select
      a.id as availability_domain_id
    from
      oci_identity_availability_domain as a,
      oci_core_subnet as s
    where
      s.region = a.region
      and s.availability_domain is null
      and s.id = $1;
  EOQ
}

# Card queries

query "vcn_subnet_flow_logs" {
  sql = <<-EOQ
    select
      case when is_enabled then 'Enabled' else 'Disabled' end as value,
      'Flow Logs' as label,
      case when is_enabled then 'ok' else 'alert' end as type
    from
      oci_core_subnet as s
      left join oci_logging_log as l
      on s.id = l.configuration -> 'source' ->> 'resource'
    where
      s.id = $1 and s.lifecycle_state <> 'TERMINATED';
  EOQ
}

# Other detail page queries

query "vcn_subnet_overview" {
  sql = <<-EOQ
    select
      display_name as "Name",
      time_created as "Time Created",
      subnet_domain_name as "Subnet Domain Name",
      region as "Region",
      id as "OCID",
      compartment_id as "Compartment ID"
    from
      oci_core_subnet
    where
      id = $1 and lifecycle_state <> 'TERMINATED';
  EOQ
}

query "vcn_subnet_tag" {
  sql = <<-EOQ
    with jsondata as (
      select
        tags::json as tags
      from
        oci_core_subnet
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

query "vcn_subnet_cidr_block" {
  sql = <<-EOQ
    select
      cidr_block as "IPv4 CIDR Block",
      ipv6_cidr_block as "IPv6 CIDR Block"
    from
      oci_core_subnet
    where
      id  = $1 and lifecycle_state <> 'TERMINATED';
  EOQ
}
