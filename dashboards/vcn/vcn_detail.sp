dashboard "vcn_detail" {

  title         = "OCI VCN Detail"
  documentation = file("./dashboards/vcn/docs/vcn_detail.md")

  tags = merge(local.vcn_common_tags, {
    type = "Detail"
  })

  input "vcn_id" {
    title = "Select a VCN:"
    sql   = query.vcn_input.sql
    width = 4
  }

  container {

    card {
      width = 2

      query = query.vcn_ipv4_count
      args = [self.input.vcn_id.value]
    }

    card {
      width = 2

      query = query.vcn_ipv6_count
      args = [self.input.vcn_id.value]
    }

    card {
      width = 2

      query = query.vcn_attached_subnet_count
      args = [self.input.vcn_id.value]
    }

    card {
      width = 2

      query = query.vcn_attached_nsg_count
      args = [self.input.vcn_id.value]
    }

    card {
      width = 2

      query = query.vcn_attached_sl_count
      args = [self.input.vcn_id.value]
    }

  }

  with "identity_availability_domains" {
    query = query.vcn_identity_availability_domains
    args  = [self.input.vcn_id.value]
  }

  with "compute_instances" {
    query = query.vcn_compute_instances
    args  = [self.input.vcn_id.value]
  }

  with "vcn_dhcp_options" {
    query = query.vcn_vcn_dhcp_options
    args  = [self.input.vcn_id.value]
  }

  with "vcn_flow_logs" {
    query = query.vcn_vcn_flow_logs
    args  = [self.input.vcn_id.value]
  }

  with "vcn_internet_gateways" {
    query = query.vcn_vcn_internet_gateways
    args  = [self.input.vcn_id.value]
  }

  with "vcn_load_balancers" {
    query = query.vcn_vcn_load_balancers
    args  = [self.input.vcn_id.value]
  }

  with "vcn_local_peering_gateways" {
    query = query.vcn_vcn_local_peering_gateways
    args  = [self.input.vcn_id.value]
  }

  with "vcn_nat_gateways" {
    query = query.vcn_nat_gateways
    args  = [self.input.vcn_id.value]
  }

  with "vcn_network_load_balancers" {
    query = query.vcn_network_load_balancers
    args  = [self.input.vcn_id.value]
  }

  with "vcn_network_security_groups" {
    query = query.vcn_network_security_groups
    args  = [self.input.vcn_id.value]
  }

  with "vcn_route_tables" {
    query = query.vcn_vcn_route_tables
    args  = [self.input.vcn_id.value]
  }

  with "vcn_security_lists" {
    query = query.vcn_vcn_security_lists
    args  = [self.input.vcn_id.value]
  }

  with "vcn_service_gateways" {
    query = query.vcn_vcn_service_gateways
    args  = [self.input.vcn_id.value]
  }

  with "vcn_subnets" {
    query = query.vcn_vcn_subnets
    args  = [self.input.vcn_id.value]
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.identity_availability_domain
        args = {
          availability_domain_ids = with.identity_availability_domains.rows[*].availability_domain_id
        }
      }

      node {
        base = node.compute_instance
        args = {
          compute_instance_ids = with.compute_instances.rows[*].compute_instance_id
        }
      }

      node {
        base = node.vcn_dhcp_option
        args = {
          vcn_dhcp_option_ids = with.vcn_dhcp_options.rows[*].dhcp_option_id
        }
      }

      node {
        base = node.vcn_flow_log
        args = {
          vcn_flow_log_ids = with.vcn_flow_logs.rows[*].flow_log_id
        }
      }

      node {
        base = node.vcn_internet_gateway
        args = {
          vcn_internet_gateway_ids = with.vcn_internet_gateways.rows[*].internet_gateway_id
        }
      }

      node {
        base = node.vcn_load_balancer
        args = {
          vcn_load_balancer_ids = with.vcn_load_balancers.rows[*].load_balancer_id
        }
      }

      node {
        base = node.vcn_local_peering_gateway
        args = {
          vcn_local_peering_gateway_ids = with.vcn_local_peering_gateways.rows[*].local_peering_gateway_id
        }
      }

      node {
        base = node.vcn_nat_gateway
        args = {
          vcn_nat_gateway_ids = with.vcn_nat_gateways.rows[*].nat_gateway_id
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
          vcn_network_security_group_ids = with.vcn_network_security_groups.rows[*].network_security_group_id
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
        base = node.vcn_service_gateway
        args = {
          vcn_service_gateway_ids = with.vcn_service_gateways.rows[*].service_gateway_id
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
          vcn_vcn_ids = [self.input.vcn_id.value]
        }
      }

      edge {
        base = edge.identity_availability_domain_to_vcn_subnet
        args = {
          vcn_subnet_ids = with.vcn_subnets.rows[*].subnet_id
        }
      }

      edge {
        base = edge.vcn_internet_gateway_to_vcn_vcn
        args = {
          vcn_internet_gateway_ids = with.vcn_internet_gateways.rows[*].internet_gateway_id
        }
      }

      edge {
        base = edge.vcn_subnet_to_compute_instance
        args = {
          compute_instance_ids = with.compute_instances.rows[*].compute_instance_id
        }
      }

      edge {
        base = edge.vcn_subnet_to_vcn_load_balancer
        args = {
          vcn_subnet_ids = with.vcn_subnets.rows[*].subnet_id
        }
      }

      edge {
        base = edge.vcn_subnet_to_vcn_network_load_balancer
        args = {
          vcn_network_load_balancer_ids = with.vcn_network_load_balancers.rows[*].network_load_balancer_id
        }
      }

      edge {
        base = edge.vcn_vcn_to_vcn_dhcp_option
        args = {
          vcn_dhcp_option_ids = with.vcn_dhcp_options.rows[*].dhcp_option_id
        }
      }

      edge {
        base = edge.vcn_subnet_to_vcn_flow_log
        args = {
          vcn_flow_log_ids = with.vcn_flow_logs.rows[*].flow_log_id
        }
      }

      edge {
        base = edge.vcn_vcn_to_identity_availability_domain
        args = {
          availability_domain_ids = with.identity_availability_domains.rows[*].availability_domain_id
        }
      }

      edge {
        base = edge.vcn_vcn_to_vcn_nat_gateway
        args = {
          vcn_nat_gateway_ids = with.vcn_nat_gateways.rows[*].nat_gateway_id
        }
      }

      edge {
        base = edge.vcn_vcn_to_vcn_network_security_group
        args = {
          vcn_network_security_group_ids = with.vcn_network_security_groups.rows[*].network_security_group_id
        }
      }

      edge {
        base = edge.vcn_subnet_to_vcn_route_table
        args = {
          vcn_route_table_ids = with.vcn_route_tables.rows[*].route_table_id
        }
      }

      edge {
        base = edge.vcn_vcn_to_vcn_local_peering_gateway
        args = {
          vcn_local_peering_gateway_ids = with.vcn_local_peering_gateways.rows[*].local_peering_gateway_id
        }
      }

      edge {
        base = edge.vcn_vcn_to_vcn_security_list
        args = {
          vcn_security_list_ids = with.vcn_security_lists.rows[*].security_list_id
        }
      }

      edge {
        base = edge.vcn_vcn_to_vcn_service_gateway
        args = {
          vcn_service_gateway_ids = with.vcn_service_gateways.rows[*].service_gateway_id
        }
      }

      edge {
        base = edge.vcn_vcn_to_vcn_subnet
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
        query = query.vcn_overview
        args = [self.input.vcn_id.value]

      }

      table {
        title = "Tags"
        width = 6

        query = query.vcn_tag
        args = [self.input.vcn_id.value]
      }

    }

    container {
      width = 6

      table {
        title = "CIDR Blocks"
        query = query.vcn_cidr_blocks
        args = [self.input.vcn_id.value]
      }

      table {
        title = "DHCP Options"
        query = query.vcn_dhcp_options
        args = [self.input.vcn_id.value]
      }

    }

    container {
      title = "Subnets"

      table {
        query = query.vcn_subnet
        args = [self.input.vcn_id.value]
        column "OCID" {
          display = "none"
        }
        column "Name" {
          href = "${dashboard.vcn_subnet_detail.url_path}?input.subnet_id={{.OCID | @uri}}"
        }
      }

    }

    container {
      title = "Routing"

      flow {
        query = query.vcn_gateway_sankey
        args = [self.input.vcn_id.value]
      }

    }

    container {

      table {
        title = "Route Rules"
        query = query.vcn_route_table
        args = [self.input.vcn_id.value]
      }

    }

    container {

      table {
        title = "Security List Details"
        width = 6
        query = query.vcn_security_list
        args = [self.input.vcn_id.value]
        column "OCID" {
          display = "none"
        }
        column "Name" {
          href = "${dashboard.oci_vcn_security_list_detail.url_path}?input.security_list_id={{.OCID | @uri}}"
        }
      }

      table {
        title = "Gateways"
        width = 6
        query = query.vcn_gateways_table
        args = [self.input.vcn_id.value]
      }

    }

    container {
      title = "Security List Ingress Analysis"

      flow {
        query = query.vcn_nsl_ingress_rule_sankey
        args = [self.input.vcn_id.value]
      }

    }

    container {
      title = "Security List Egress Analysis"

      flow {
        query = query.vcn_nsl_egress_rule_sankey
        args = [self.input.vcn_id.value]
      }

    }

    container {

      table {
        title = "Network Security Group Details"
        width = 6
        query = query.vcn_security_group
        args = [self.input.vcn_id.value]
        column "OCID" {
          display = "none"
        }
        column "Name" {
          href = "${dashboard.vcn_network_security_group_detail.url_path}?input.security_group_id={{.OCID | @uri}}"
        }
      }
    }

  }

}

query "vcn_input" {
  sql = <<-EOQ
    select
      v.display_name as label,
      v.id as value,
      json_build_object(
        'c.name', coalesce(c.title, 'root'),
        'v.region', region,
        't.name', t.name
      ) as tags
    from
      oci_core_vcn as v
      left join oci_identity_compartment as c on v.compartment_id = c.id
      left join oci_identity_tenancy as t on v.tenant_id = t.id
    where
      v.lifecycle_state <> 'TERMINATED'
    order by
      v.display_name;
  EOQ
}

query "vcn_ipv4_count" {
  sql = <<-EOQ
    with cidrs as (
      select
        power(2, 32 - masklen(b :: cidr)) as num_ips
      from
        oci_core_vcn,
        jsonb_array_elements_text(cidr_blocks) as b
      where
        id = $1
    )
    select
      sum(num_ips) as "IPv4 Addresses"
    from
      cidrs
  EOQ
}

query "vcn_ipv6_count" {
  sql = <<-EOQ
      select
        power(2, 128 - masklen(b :: cidr)) as "IPv6 Addresses"
      from
        oci_core_vcn
        left join jsonb_array_elements_text(ipv6_cidr_blocks) as b on ipv6_cidr_blocks is not null
      where
        id = $1;
  EOQ
}

query "vcn_attached_subnet_count" {
  sql = <<-EOQ
    select
      'Subnets' as label,
      count(*) as value
    from
      oci_core_subnet
    where
      vcn_id = $1;
  EOQ
}

query "vcn_attached_nsg_count" {
  sql = <<-EOQ
    select
      'Network Security Groups' as label,
      count(*) as value
    from
      oci_core_network_security_group
    where
      vcn_id = $1;
  EOQ
}

query "vcn_attached_sl_count" {
  sql = <<-EOQ
    select
      'Security Lists' as label,
      count(*) as value
    from
      oci_core_security_list
    where
      vcn_id = $1;
  EOQ
}

query "vcn_overview" {
  sql = <<-EOQ
    select
      display_name as "Name",
      time_created as "Time Created",
      region as "Region",
      id as "OCID",
      compartment_id as "Compartment ID"
    from
      oci_core_vcn
    where
      id = $1;
  EOQ
}

query "vcn_tag" {
  sql = <<-EOQ
    with jsondata as (
      select
        tags::json as tags
      from
        oci_core_vcn
      where
        id = $1
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

query "vcn_cidr_blocks" {
  sql = <<-EOQ
    select
      b as "CIDR Block",
      power(2, 32 - masklen(b :: cidr)) as "Total IPs"
    from
      oci_core_vcn,
      jsonb_array_elements_text(cidr_blocks) as b
    where
      id = $1
    union all
    select
      b as cidr_block,
      power(2, 128 - masklen(b :: cidr)) as num_ips
    from
      oci_core_vcn,
      jsonb_array_elements_text(ipv6_cidr_blocks) as b
    where
      id = $1;
  EOQ
}

query "vcn_dhcp_options" {
  sql = <<-EOQ
    select
      display_name as "Name",
      lifecycle_state as "Lifecycle State",
      op ->> 'type' as "Option Type",
      op -> 'searchDomainNames' as "Search Domain Names",
      op -> 'customDnsServers' as "Custom DNS Servers",
      op ->> 'serverType' as "Server Type"
    from
      oci_core_dhcp_options,
      jsonb_array_elements(options) as op
    where
      vcn_id = $1
    order by
      display_name;
  EOQ
}

query "vcn_subnet" {
  sql = <<-EOQ
    select
      display_name as "Name",
      cidr_block as "IPv4 CIDR Block",
      ipv6_cidr_block as "IPv6 CIDR Block",
      id as "OCID",
      availability_domain as "Availability Domain",
      subnet_domain_name as "Subnet Domain Name",
      prohibit_public_ip_on_vnic as "Prohibit Public IP on VNIC"
    from
      oci_core_subnet
    where
      vcn_id = $1
    order by
      display_name;
  EOQ
}

query "vcn_gateway_sankey" {
  sql = <<-EOQ
    with routes as (
    select
        r.id as route_table_id,
        r.vcn_id,
        rule ->> 'networkEntityId' as gateway,
        rule ->> 'destination' as destination_cidr,
        s.display_name as associated_to
      from
        oci_core_subnet as s
        left join oci_core_route_table as r on s.route_table_id = r.id,
        jsonb_array_elements(route_rules) as rule
      where
        s.vcn_id = $1
    ),
    gateway as (
      select
        associated_to,
        gateway,
        destination_cidr,
        case
          when i.id is not null then i.display_name
          when l.id is not null then l.name
          when n.id is not null then n.display_name
          when s.id is not null then s.display_name
        end as gateway_name
      from
        routes as r
        left join oci_core_internet_gateway as i on i.id = gateway
        left join oci_core_local_peering_gateway as l on l.id = gateway
        left join oci_core_nat_gateway as n on n.id = gateway
        left join oci_core_service_gateway as s on s.id = gateway
    )
    select
        null as from_id,
        associated_to as id,
        associated_to as title,
        'route_table' as category,
        0 as depth
      from
        gateway
      union
        select
          associated_to as from_id,
          destination_cidr as id,
          destination_cidr as title,
          'subnet' as category,
          1 as depth
        from
          gateway
      union
        select
          destination_cidr as from_id,
          gateway_name as id,
          gateway_name as title,
          'gateway' as category,
          2 as depth
        from
          gateway
  EOQ
}

query "vcn_route_table" {
  sql = <<-EOQ
    select
      display_name as "Route Table Name",
      lifecycle_state as "Lifecycle State",
      r ->> 'cidrBlock' as "CIDR Block",
      r ->> 'destination' as "Destination",
      r ->> 'destinationType' as "Destination Type",
      r ->> 'networkEntityId' as "Network Entity ID"
    from
      oci_core_route_table,
      jsonb_array_elements(route_rules) as r
    where
      vcn_id = $1
    order by
      display_name;
  EOQ
}

query "vcn_gateways_table" {
  sql = <<-EOQ
    select
      display_name as "Name",
      'oci_core_internet_gateway' as "Type",
      lifecycle_state as "Lifecycle State"
    from
      oci_core_internet_gateway
    where
      vcn_id = $1
    union all
    select
      name as "Name",
      'oci_core_local_peering_gateway' as "Type",
      lifecycle_state as "State"
    from
      oci_core_local_peering_gateway
    where
      vcn_id = $1
    union all
    select
      display_name as "Name",
      'oci_core_nat_gateway' as "Type",
      lifecycle_state as "State"
    from
      oci_core_nat_gateway
    where
      vcn_id = $1
    union all
    select
      display_name as "Name",
      'oci_core_service_gateway' as "Type",
      lifecycle_state as "State"
    from
      oci_core_service_gateway
    where
      vcn_id = $1;
  EOQ
}

query "vcn_security_list" {
  sql = <<-EOQ
    select
      display_name as "Name",
      id as "OCID",
      lifecycle_state as "Lifecycle State",
      time_created as "Time Created"
    from
      oci_core_security_list
    where
      vcn_id = $1
    order by
      display_name;
  EOQ
}

query "vcn_security_group" {
  sql = <<-EOQ
    select
      display_name as "Name",
      id as "OCID",
      lifecycle_state as "Lifecycle State",
      time_created as "Time Created"
    from
      oci_core_network_security_group
    where
      vcn_id = $1
    order by
      display_name;
  EOQ
}

query "vcn_nsl_ingress_rule_sankey" {

  sql = <<-EOQ
   with subnets as (
      select
        display_name as subnet_name,
        id as subnet_id,
        sl as sl_id
      from
        oci_core_subnet as s,
        jsonb_array_elements_text(security_list_ids) as sl
      where
        vcn_id = $1
    ),
    securityList as (
      select
        subnet_name,
        subnet_id,
        display_name as sl_name,
        l.id as sl_id,
        ingress_security_rules as rules
      from
        oci_core_security_list as l
        left join subnets as s on s.sl_id = l.id
      where
        vcn_id = $1
    ),
    rule as (
      select
        subnet_name,
        subnet_id,
        sl_id,
        sl_name,
        r ->> 'source' as source,
        case
          when r ->> 'protocol' = 'all' then 'Allow All Traffic'
          when r ->> 'protocol' = '6' and r ->> 'tcpOptions' is null then 'Allow All TCP'
          when r ->> 'protocol' = '17' and r ->> 'udpOptions' is null then 'Allow All UDP'
          when r ->> 'protocol' = '1' and r ->> 'icmpOptions' is null then 'Allow All ICMP'

          when r->>'protocol' = '6' and (r->'tcpOptions' -> 'sourcePortRange' ->>'min' = '1' or r->'tcpOptions' -> 'sourcePortRange' ->>'min' is null)
              and (r->'tcpOptions' -> 'destinationPortRange' ->>'max' = '65535' or r->'tcpOptions' -> 'destinationPortRange' ->>'max' is null)
              then 'Allow All TCP'

          when r->>'protocol' = '17' and (r->'udpOptions' -> 'sourcePortRange' ->>'min' = '1' or r->'udpOptions' -> 'sourcePortRange' ->>'min' is null)
              and (r->'udpOptions' -> 'destinationPortRange' ->>'max' = '65535' or r->'udpOptions' -> 'destinationPortRange' ->>'max' is null)
              then 'Allow All UDP'

          when r ->> 'protocol' = '1' and r -> 'icmpOptions' ->> 'code' is not null and r -> 'icmpOptions' ->> 'type' is not null
            then concat('ICMP Type ', r -> 'icmpOptions' ->> 'type', ', Code ',  r -> 'icmpOptions' ->> 'code')
          when r ->> 'protocol' = '1' and r -> 'icmpOptions' ->> 'code' is not null
            then concat('ICMP Code ',  r -> 'icmpOptions' ->> 'code')
          when r ->> 'protocol' = '1' and r -> 'icmpOptions' ->> 'type' is not null
            then concat('ICMP Type ',  r -> 'icmpOptions' ->> 'type')

          when r->>'protocol' = '6' and r->'tcpOptions' -> 'sourcePortRange' ->>'min' = r->'tcpOptions' -> 'destinationPortRange' ->>'max'
              then concat(r -> 'tcpOptions' -> 'sourcePortRange' ->> 'min','/TCP')

          when r->>'protocol' = '17' and r->'udpOptions' -> 'sourcePortRange' ->>'min' = r->'udpOptions' -> 'destinationPortRange' ->>'max'
              then concat(r -> 'udpOptions' -> 'sourcePortRange' ->> 'min','/UDP')

          when r->>'protocol' = '6' and COALESCE(r->'tcpOptions' -> 'sourcePortRange' ->>'min','1') <> COALESCE(r->'tcpOptions' -> 'destinationPortRange' ->>'max','65535')
              then concat(COALESCE(r -> 'tcpOptions' -> 'sourcePortRange' ->> 'min','1'), '-',COALESCE(r->'tcpOptions' -> 'destinationPortRange' ->>'max','65535'),'/TCP')

          when r->>'protocol' = '17' and COALESCE(r->'udpOptions' -> 'sourcePortRange' ->>'min','1') <> COALESCE(r->'udpOptions' -> 'destinationPortRange' ->>'max','65535')
              then concat(COALESCE(r -> 'udpOptions' -> 'sourcePortRange' ->> 'min','1'), '-',COALESCE(r->'udpOptions' -> 'destinationPortRange' ->>'max','65535'),'/UDP')


          else concat('Protocol: ', r ->> 'protocol')
        end as rule_description
      from
        securityList,
        jsonb_array_elements(rules) as r
    )

      -- CIDR Nodes
    select
      distinct source as id,
      source as title,
      'source' as category,
      null as from_id,
      null as to_id
    from rule

      -- Rule Nodes
    union select
      distinct rule_description as id,
      rule_description as title,
      'rule' as category,
      null as from_id,
      null as to_id
    from rule

      -- SL Nodes
    union select
      distinct sl_name as id,
      sl_name as title,
      'sl' as category,
      null as from_id,
      null as to_id
    from rule

      -- Subnet node
    union select
      distinct subnet_name as id,
      subnet_name as title,
      'subnet' as category,
      null as from_id,
      null as to_id
    from rule

      -- ip -> rule edge
    union select
      null as id,
      null as title,
      sl_name as category,
      source as from_id,
      rule_description as to_id
    from rule

      -- rule -> SL edge
    union select
      null as id,
      null as title,
      sl_name as category,
      rule_description as from_id,
      sl_name as to_id
    from rule

      -- sl -> subnet edge
    union select
      null as id,
      null as title,
      'attached' as category,
      sl_name as from_id,
      subnet_name as to_id
    from rule
  EOQ
}

query "vcn_nsl_egress_rule_sankey" {

  sql = <<-EOQ
    with subnets as (
      select
        display_name as subnet_name,
        id as subnet_id,
        sl as sl_id
      from
        oci_core_subnet as s,
        jsonb_array_elements_text(security_list_ids) as sl
      where
        vcn_id = $1
    ),
    securityList as (
      select
        subnet_name,
        subnet_id,
        display_name as sl_name,
        l.id as sl_id,
        egress_security_rules as rules
      from
        oci_core_security_list as l
        left join subnets as s on s.sl_id = l.id
      where
        vcn_id = $1
    ),
    rule as (
      select
        subnet_name,
        subnet_id,
        sl_id,
        sl_name,
        r ->> 'source' as source,
        case
          when r ->> 'protocol' = 'all' then 'Allow All Traffic'
          when r ->> 'protocol' = '6' and r ->> 'tcpOptions' is null then 'Allow All TCP'
          when r ->> 'protocol' = '17' and r ->> 'udpOptions' is null then 'Allow All UDP'
          when r ->> 'protocol' = '1' and r ->> 'icmpOptions' is null then 'Allow All ICMP'

          when r->>'protocol' = '6' and (r->'tcpOptions' -> 'sourcePortRange' ->>'min' = '1' or r->'tcpOptions' -> 'sourcePortRange' ->>'min' is null)
              and (r->'tcpOptions' -> 'destinationPortRange' ->>'max' = '65535' or r->'tcpOptions' -> 'destinationPortRange' ->>'max' is null)
              then 'Allow All TCP'

          when r->>'protocol' = '17' and (r->'udpOptions' -> 'sourcePortRange' ->>'min' = '1' or r->'udpOptions' -> 'sourcePortRange' ->>'min' is null)
              and (r->'udpOptions' -> 'destinationPortRange' ->>'max' = '65535' or r->'udpOptions' -> 'destinationPortRange' ->>'max' is null)
              then 'Allow All UDP'

          when r ->> 'protocol' = '1' and r -> 'icmpOptions' ->> 'code' is not null and r -> 'icmpOptions' ->> 'type' is not null
            then concat('ICMP Type ', r -> 'icmpOptions' ->> 'type', ', Code ',  r -> 'icmpOptions' ->> 'code')
          when r ->> 'protocol' = '1' and r -> 'icmpOptions' ->> 'code' is not null
            then concat('ICMP Code ',  r -> 'icmpOptions' ->> 'code')
          when r ->> 'protocol' = '1' and r -> 'icmpOptions' ->> 'type' is not null
            then concat('ICMP Type ',  r -> 'icmpOptions' ->> 'type')

          when r->>'protocol' = '6' and r->'tcpOptions' -> 'sourcePortRange' ->>'min' = r->'tcpOptions' -> 'destinationPortRange' ->>'max'
              then concat(r -> 'tcpOptions' -> 'sourcePortRange' ->> 'min','/TCP')

          when r->>'protocol' = '17' and r->'udpOptions' -> 'sourcePortRange' ->>'min' = r->'udpOptions' -> 'destinationPortRange' ->>'max'
              then concat(r -> 'udpOptions' -> 'sourcePortRange' ->> 'min','/UDP')

          when r->>'protocol' = '6' and COALESCE(r->'tcpOptions' -> 'sourcePortRange' ->>'min','1') <> COALESCE(r->'tcpOptions' -> 'destinationPortRange' ->>'max','65535')
              then concat(COALESCE(r -> 'tcpOptions' -> 'sourcePortRange' ->> 'min','1'), '-',COALESCE(r->'tcpOptions' -> 'destinationPortRange' ->>'max','65535'),'/TCP')

          when r->>'protocol' = '17' and COALESCE(r->'udpOptions' -> 'sourcePortRange' ->>'min','1') <> COALESCE(r->'udpOptions' -> 'destinationPortRange' ->>'max','65535')
              then concat(COALESCE(r -> 'udpOptions' -> 'sourcePortRange' ->> 'min','1'), '-',COALESCE(r->'udpOptions' -> 'destinationPortRange' ->>'max','65535'),'/UDP')


          else concat('Protocol: ', r ->> 'protocol')
        end as rule_description
      from
        securityList,
        jsonb_array_elements(rules) as r
    )

      -- Subnet node
    select
      distinct subnet_name as id,
      subnet_name as title,
      'subnet' as category,
      null as from_id,
      null as to_id,
      0 as depth
    from rule

      -- SL Nodes
    union select
      distinct sl_name as id,
      sl_name as title,
      'sl' as category,
      null as from_id,
      null as to_id,
      1 as depth
    from rule

      -- Rule Nodes
    union select
      distinct rule_description as id,
      rule_description as title,
      'rule' as category,
      null as from_id,
      null as to_id,
      2 as depth
    from rule

      -- CIDR Nodes
    union select
      distinct source as id,
      source as title,
      'source' as category,
      null as from_id,
      null as to_id,
      3 as depth
    from rule

    -- sl -> subnet edge
    union select
      null as id,
      null as title,
      'attached' as category,
      sl_name as from_id,
      subnet_name as to_id,
      null as depth
    from rule

    -- rule -> SL edge
    union select
      null as id,
      null as title,
      'rule' as category,
      rule_description as from_id,
      sl_name as to_id,
      null as depth
    from rule

      -- ip -> rule edge
    union select
      null as id,
      null as title,
      'rule' as category,
      source as from_id,
      rule_description as to_id,
      null as depth
    from rule
  EOQ
}

query "vcn_compute_instances" {
  sql = <<-EOQ
    select
      i.id as compute_instance_id
    from
      oci_core_instance as i,
      oci_core_subnet as s,
      oci_core_vnic_attachment as v
    where
      v.instance_id = i.id
      and v.subnet_id = s.id
      and i.lifecycle_state = 'RUNNING'
      and s.vcn_id = $1;
  EOQ
}

query "vcn_vcn_subnets" {
  sql = <<-EOQ
    select
      id as subnet_id
    from
      oci_core_subnet
    where
      vcn_id = $1;
  EOQ
}

query "vcn_vcn_internet_gateways" {
  sql = <<-EOQ
    select
      id as internet_gateway_id
    from
      oci_core_internet_gateway
    where
      vcn_id = $1;
  EOQ
}

query "vcn_nat_gateways" {
  sql = <<-EOQ
    select
      id as nat_gateway_id
    from
      oci_core_nat_gateway
    where
      vcn_id = $1;
  EOQ
}

query "vcn_network_security_groups" {
  sql = <<-EOQ
    select
      id as network_security_group_id
    from
      oci_core_network_security_group
    where
      vcn_id = $1;
  EOQ
}

query "vcn_vcn_load_balancers" {
  sql = <<-EOQ
    with subnet_list as (
      select
        id as subnet_id
      from
        oci_core_subnet
      where
        vcn_id = $1
      )
      select
        id as load_balancer_id
      from
        oci_core_load_balancer,
        jsonb_array_elements_text(subnet_ids) as s
      where
        s in (select subnet_id from subnet_list);
  EOQ
}

query "vcn_vcn_route_tables" {
  sql = <<-EOQ
    select
      id as route_table_id
    from
      oci_core_route_table
    where
      vcn_id = $1;
  EOQ
}

query "vcn_vcn_dhcp_options" {
  sql = <<-EOQ
    select
      id as dhcp_option_id
    from
      oci_core_dhcp_options
    where
      vcn_id = $1;
  EOQ
}

query "vcn_vcn_security_lists" {
  sql = <<-EOQ
    select
      id as security_list_id
    from
      oci_core_security_list
    where
      vcn_id = $1;
  EOQ
}

query "vcn_vcn_local_peering_gateways" {
  sql = <<-EOQ
    select
      id as local_peering_gateway_id
    from
      oci_core_local_peering_gateway
    where
      vcn_id = $1;
  EOQ
}

query "vcn_vcn_service_gateways" {
  sql = <<-EOQ
    select
      id as service_gateway_id
    from
      oci_core_service_gateway
    where
      vcn_id = $1;
  EOQ
}

query "vcn_network_load_balancers" {
  sql = <<-EOQ
    select
      n.id as network_load_balancer_id
    from
      oci_core_network_load_balancer as n,
      oci_core_subnet as s
    where
      s.id = n.subnet_id
      and s.vcn_id = $1;
  EOQ
}

query "vcn_vcn_flow_logs" {
  sql = <<-EOQ
    select
      l.id as flow_log_id
    from
      oci_logging_log as l,
      oci_core_subnet as s
    where
      configuration -> 'source' ->> 'service' = 'flowlogs'
      and configuration -> 'source' ->> 'resource' = s.id
      and s.vcn_id = $1;
  EOQ
}

query "vcn_identity_availability_domains" {
  sql = <<-EOQ
    select
      a.id as availability_domain_id
    from
      oci_identity_availability_domain as a,
      oci_core_subnet as s
    where
      s.availability_domain = a.name
      and s.vcn_id = $1;
  EOQ
}

