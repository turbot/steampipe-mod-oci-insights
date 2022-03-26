dashboard "oci_vcn_detail" {

  title         = "OCI VCN Detail"
  documentation = file("./dashboards/vcn/docs/vcn_detail.md")

  tags = merge(local.vcn_common_tags, {
    type = "Detail"
  })

  input "vcn_id" {
    title = "Select a VCN:"
    sql   = query.oci_vcn_input.sql
    width = 4
  }

  container {

    card {
      width = 2

      query = query.oci_vcn_attached_subnet_count
      args = {
        id = self.input.vcn_id.value
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
        query = query.oci_vcn_overview
        args = {
          id = self.input.vcn_id.value
        }

      }

      table {
        title = "Tags"
        width = 6

        query = query.oci_vcn_tag
        args = {
          id = self.input.vcn_id.value
        }
      }

    }

    container {
      width = 6

      table {
        title = "DHCP Options"
        query = query.oci_vcn_dhcp_options
        args = {
          id = self.input.vcn_id.value
        }
      }

    }

    container {
      title = "Subnets"

      flow {
        query = query.oci_vcn_subnet_sankey
        args = {
          id = self.input.vcn_id.value
        }
      }

    }

    container {
      table {
        title = "Subnet Details"
        query = query.oci_vcn_subnet
        args = {
          id = self.input.vcn_id.value
        }
      }

    }

    container {

      table {
        title = "Route Rules"
        query = query.oci_vcn_route_table
        args = {
          id = self.input.vcn_id.value
        }
      }

    }

    container {

      title = "Network Security List Egress Rules"

      flow {
        query = query.oci_vcn_nsl_egress_rule_sankey
        args = {
          id = self.input.vcn_id.value
        }
      }

    }

    container {

      title = "Network Security List Ingress Rules"

      flow {
        query = query.oci_vcn_nsl_ingress_rule_sankey
        args = {
          id = self.input.vcn_id.value
        }
      }

    }

    container {

      title = "Network Security Group Egress Rules"

      flow {
        query = query.oci_vcn_nsg_egress_rule_sankey
        args = {
          id = self.input.vcn_id.value
        }
      }

    }

    container {

      title = "Network Security Group Ingress Rules"
      flow {
        query = query.oci_vcn_nsg_ingress_rule_sankey
        args = {
          id = self.input.vcn_id.value
        }
      }

    }

  }

}

query "oci_vcn_input" {
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

query "oci_vcn_attached_subnet_count" {
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

query "oci_vcn_overview" {
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

query "oci_vcn_tag" {
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

query "oci_vcn_dhcp_options" {
  sql = <<-EOQ
    select
      display_name as "Name",
      lifecycle_state as "State",
      op ->> 'type' as "Option Type",
      op -> 'searchDomainNames' as "Search Domain Names",
      op -> 'customDnsServers' as "Custom DNS Servers",
      op ->> 'serverType' as "Server Type"
    from
      oci_core_dhcp_options,
      jsonb_array_elements(options) as op
    where
      vcn_id = $1;
  EOQ

  param "id" {}
}

query "oci_vcn_subnet" {
  sql = <<-EOQ
    select
      display_name as "Name",
      lifecycle_state as "State",
      time_created as "Time Created",
      availability_domain as "Availability Domain",
      cidr_block as "IPv4 CIDR Block",
      dns_label as "DNS Label",
      ipv6_cidr_block as "IPv6 CIDR Block",
      subnet_domain_name as "Subnet Domain Name",
      virtual_router_ip as "Virtual Router IP",
      prohibit_public_ip_on_vnic as "Prohibit Public IP on Vnic",
      virtual_router_mac as "Virtual Router MAC"
    from
      oci_core_subnet
    where
      vcn_id = $1;
  EOQ

  param "id" {}
}

query "oci_vcn_subnet_sankey" {
  sql = <<-EOQ
    with subnets as (
      select
        s.display_name as subnet_name,
        s.id as subnet_id,
        s.cidr_block::text as "cidr",
        g.display_name as gateway_name,
        g.id as gateway_id
      from
        oci_core_subnet as s
        left join oci_core_vcn as v on s.vcn_id = v.id
        left join oci_core_nat_gateway as g on g.vcn_id = v.id
      where
        s.vcn_id = $1
    )
      select
        null as from_id,
        subnet_name as id,
        subnet_name as title,
        'subnet' as category,
        0 as depth
      from
        subnets
      union
        select
          subnet_name as from_id,
          cidr as id,
          cidr as title,
          'cidr' as category,
          1 as depth
        from
          subnets
      union
        select
          cidr as from_id,
          gateway_name as id,
          gateway_name as title,
          'natGateway' as category,
          2 as depth
        from
          subnets
  EOQ

  param "id" {}
}

query "oci_vcn_route_table" {
  sql = <<-EOQ
    select
      display_name as "Route Table Name",
      lifecycle_state as "Route Table State",
      r ->> 'cidrBlock' as "CIDR Block",
      r ->> 'destination' as "Destination",
      r ->> 'destinationType' as "Destination Type",
      r ->> 'networkEntityId' as "Network Entity ID"
    from
      oci_core_route_table,
      jsonb_array_elements(route_rules) as r
    where
      vcn_id = $1;
  EOQ

  param "id" {}
}

query "oci_vcn_nsl_egress_rule_sankey" {

  sql = <<-EOQ
    with subnets_nsl as (
      select
        s.display_name as subnet_name,
        s.id as subnet_id,
        s.cidr_block::text as "cidr",
        l.display_name as list_name,
        l.id as list_id,
        l.egress_security_rules as rules
      from
        oci_core_subnet as s
        left join oci_core_vcn as v on s.vcn_id = v.id
        left join oci_core_security_list as l on l.vcn_id = v.id
      where
        s.vcn_id = $1
    ),
    rule as (
      select
        subnet_name,
        subnet_id,
        list_id,
        list_name,
        cidr,
        case
          when r ->> 'protocol' = 'all' then 'Allow All Traffic'
          when r ->> 'protocol' = '6' then 'Allow TCP'
          when r ->> 'protocol' = '17' then 'Allow UDP'
          when r ->> 'protocol' = '1' then 'Allow ICMP'
          when r is null then 'Deny All'
        end as rule_description
      from
        subnets_nsl,
        jsonb_array_elements(rules) as r
    )

      -- Subnet Nodes
      select
        distinct subnet_id as id,
        subnet_name title,
        'subnet' as category,
        null as from_id,
        null as to_id,
        0 as depth
      from rule

      -- CIDR Nodes
      union select
        distinct cidr as id,
        cidr as title,
        'cidr_block' as category,
        subnet_id as from_id,
        null as to_id,
        1 as depth
      from rule

        -- NSL Nodes
      union select
        list_id as id,
        list_name as title,
        'nslid' as category,
        cidr as from_id,
        null as to_id,
        2 as depth
      from rule

        -- Rule Nodes
      union select
        rule_description as id,
        rule_description as title,
        'rule' as category,
        list_id as from_id,
        null as to_id,
        3 as depth
      from rule
  EOQ

  param "id" {}
}

query "oci_vcn_nsl_ingress_rule_sankey" {

  sql = <<-EOQ
    with subnets_nsl as (
      select
        s.display_name as subnet_name,
        s.id as subnet_id,
        s.cidr_block::text as "cidr",
        l.display_name as list_name,
        l.id as list_id,
        l.ingress_security_rules as rules
      from
        oci_core_subnet as s
        left join oci_core_vcn as v on s.vcn_id = v.id
        left join oci_core_security_list as l on l.vcn_id = v.id
      where
        s.vcn_id = $1
    ),
    rule as (
      select
        subnet_name,
        subnet_id,
        list_id,
        list_name,
        cidr,
        case
          when r ->> 'protocol' = 'all' then 'Allow All Traffic'
          when r ->> 'protocol' = '6' then 'Allow TCP'
          when r ->> 'protocol' = '17' then 'Allow UDP'
          when r ->> 'protocol' = '1' then 'Allow ICMP'
        end as rule_description
      from
        subnets_nsl,
        jsonb_array_elements(rules) as r
    )

      -- Subnet Nodes
      select
        distinct subnet_id as id,
        subnet_name title,
        'subnet' as category,
        null as from_id,
        null as to_id,
        0 as depth
      from rule

      -- CIDR Nodes
      union select
        distinct cidr as id,
        cidr as title,
        'cidr_block' as category,
        subnet_id as from_id,
        null as to_id,
        1 as depth
      from rule

        -- NSL Nodes
      union select
        list_id as id,
        list_name as title,
        'nslid' as category,
        cidr as from_id,
        null as to_id,
        2 as depth
      from rule

        -- Rule Nodes
      union select
        rule_description as id,
        rule_description as title,
        'rule' as category,
        list_id as from_id,
        null as to_id,
        3 as depth
      from rule
  EOQ

  param "id" {}
}

query "oci_vcn_nsg_egress_rule_sankey" {

  sql = <<-EOQ
    with subnets_nsg as (
      select
        s.display_name as subnet_name,
        s.id as subnet_id,
        s.cidr_block::text as "cidr",
        g.display_name as group_name,
        g.id as group_id,
        g.rules as rules
      from
        oci_core_subnet as s
        left join oci_core_vcn as v on s.vcn_id = v.id
        left join oci_core_network_security_group as g on g.vcn_id = v.id
      where
        s.vcn_id = $1
    ),
    rule as (
      select
        subnet_name,
        subnet_id,
        group_id,
        group_name,
        cidr,
        case
          when r ->> 'protocol' = 'all' then 'Allow All Traffic'
          when r ->> 'protocol' = '6' then 'Allow TCP'
          when r ->> 'protocol' = '17' then 'Allow UDP'
          when r ->> 'protocol' = '1' then 'Allow ICMP'
        end as rule_description
        from
          subnets_nsg,
          jsonb_array_elements(rules) as r
        where
          r ->> 'direction' = 'EGRESS'
    )

      -- Subnet Nodes
      select
        distinct subnet_id as id,
        subnet_name title,
        'subnet' as category,
        null as from_id,
        null as to_id,
        0 as depth
      from rule

      -- CIDR Nodes
      union select
        distinct cidr as id,
        cidr as title,
        'cidr_block' as category,
        subnet_id as from_id,
        null as to_id,
        1 as depth
      from rule

        -- NSG Nodes
      union select
        group_id as id,
        group_name as title,
        'nsgid' as category,
        cidr as from_id,
        null as to_id,
        2 as depth
      from rule

        -- Rule Nodes
      union select
        rule_description as id,
        rule_description as title,
        'rule' as category,
        group_id as from_id,
        null as to_id,
        3 as depth
      from rule
  EOQ

  param "id" {}
}

query "oci_vcn_nsg_ingress_rule_sankey" {

  sql = <<-EOQ
    with subnets_nsg as (
      select
        s.display_name as subnet_name,
        s.id as subnet_id,
        s.cidr_block::text as "cidr",
        g.display_name as group_name,
        g.id as group_id,
        g.rules as rules
      from
        oci_core_subnet as s
        left join oci_core_vcn as v on s.vcn_id = v.id
        left join oci_core_network_security_group as g on g.vcn_id = v.id
      where
        s.vcn_id = $1
    ),
    rule as (
      select
        subnet_name,
        subnet_id,
        group_id,
        group_name,
        cidr,
        case
          when r ->> 'protocol' = 'all' then 'Allow All Traffic'
          when r ->> 'protocol' = '6' then 'Allow TCP'
          when r ->> 'protocol' = '17' then 'Allow UDP'
          when r ->> 'protocol' = '1' then 'Allow ICMP'
        end as rule_description
      from
        subnets_nsg,
        jsonb_array_elements(rules) as r
       where
          r ->> 'direction' = 'INGRESS'
    )

      -- Subnet Nodes
      select
        distinct subnet_id as id,
        subnet_name title,
        'subnet' as category,
        null as from_id,
        null as to_id,
        0 as depth
      from rule

      -- CIDR Nodes
      union select
        distinct cidr as id,
        cidr as title,
        'cidr_block' as category,
        subnet_id as from_id,
        null as to_id,
        1 as depth
      from rule

        -- NSG Nodes
      union select
        group_id as id,
        group_name as title,
        'nsgid' as category,
        cidr as from_id,
        null as to_id,
        2 as depth
      from rule

        -- Rule Nodes
      union select
        rule_description as id,
        rule_description as title,
        'rule' as category,
        group_id as from_id,
        null as to_id,
        3 as depth
      from rule
  EOQ

  param "id" {}
}
