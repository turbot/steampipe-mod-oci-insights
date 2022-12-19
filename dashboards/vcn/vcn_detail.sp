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
      args = {
        id = self.input.vcn_id.value
      }
    }

    card {
      width = 2

      query = query.vcn_ipv6_count
      args = {
        id = self.input.vcn_id.value
      }
    }

    card {
      width = 2

      query = query.vcn_attached_subnet_count
      args = {
        id = self.input.vcn_id.value
      }
    }

    card {
      width = 2

      query = query.vcn_attached_nsg_count
      args = {
        id = self.input.vcn_id.value
      }
    }

    card {
      width = 2

      query = query.vcn_attached_sl_count
      args = {
        id = self.input.vcn_id.value
      }
    }

  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.vcn_vcn
        args = {
          vcn_vcn_ids = [self.input.vcn_id.value]
        }
      }

      # edge {
      #   base = edge.s3_bucket_to_sqs_queue
      #   args = {
      #     s3_bucket_arns = [self.input.bucket_arn.value]
      #   }
      # }
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
        args = {
          id = self.input.vcn_id.value
        }

      }

      table {
        title = "Tags"
        width = 6

        query = query.vcn_tag
        args = {
          id = self.input.vcn_id.value
        }
      }

    }

    container {
      width = 6

      table {
        title = "CIDR Blocks"
        query = query.vcn_cidr_blocks
        args = {
          id = self.input.vcn_id.value
        }
      }

      table {
        title = "DHCP Options"
        query = query.vcn_dhcp_options
        args = {
          id = self.input.vcn_id.value
        }
      }

    }

    container {
      title = "Subnets"

      table {
        query = query.vcn_subnet
        args = {
          id = self.input.vcn_id.value
        }
        column "OCID" {
          display = "none"
        }
        column "Name" {
          href = "${dashboard.oci_vcn_subnet_detail.url_path}?input.subnet_id={{.OCID | @uri}}"
        }
      }

    }

    container {
      title = "Routing"

      flow {
        query = query.vcn_gateway_sankey
        args = {
          id = self.input.vcn_id.value
        }
      }

    }

    container {

      table {
        title = "Route Rules"
        query = query.vcn_route_table
        args = {
          id = self.input.vcn_id.value
        }
      }

    }

    container {

      table {
        title = "Security List Details"
        width = 6
        query = query.vcn_security_list
        args = {
          id = self.input.vcn_id.value
        }
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
        args = {
          id = self.input.vcn_id.value
        }
      }

    }

    container {
      title = "Security List Ingress Analysis"

      flow {
        query = query.vcn_nsl_ingress_rule_sankey
        args = {
          id = self.input.vcn_id.value
        }
      }

    }

    container {
      title = "Security List Egress Analysis"

      flow {
        query = query.vcn_nsl_egress_rule_sankey
        args = {
          id = self.input.vcn_id.value
        }
      }

    }

    container {

      table {
        title = "Network Security Group Details"
        width = 6
        query = query.vcn_security_group
        args = {
          id = self.input.vcn_id.value
        }
        column "OCID" {
          display = "none"
        }
        column "Name" {
          href = "${dashboard.oci_vcn_network_security_group_detail.url_path}?input.security_group_id={{.OCID | @uri}}"
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

  param "id" {}
}

query "vcn_ipv6_count" {
  sql = <<-EOQ
      select
        power(2, 128 - masklen(b :: cidr)) as "IPv6 Addresses"
      from
        oci_core_vcn,
        jsonb_array_elements_text(ipv6_cidr_blocks) as b
      where
        id = $1;
  EOQ

  param "id" {}
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

  param "id" {}
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

  param "id" {}
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

  param "id" {}
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

  param "id" {}
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

  param "id" {}
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

  param "id" {}
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

  param "id" {}
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

  param "id" {}
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

  param "id" {}
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

  param "id" {}
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

  param "id" {}
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

  param "id" {}
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

  param "id" {}
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

  param "id" {}
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

  param "id" {}
}


