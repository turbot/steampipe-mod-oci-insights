dashboard "vcn_public_ip_detail" {

  title         = "OCI VCN Public IP Detail"
  documentation = file("./dashboards/vcn/docs/vcn_public_ip_detail.md")

  tags = merge(local.vcn_common_tags, {
    type = "Detail"
  })

  input "public_ip_id" {
    title = "Select a public ip:"
    query = query.vcn_public_ip_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.vcn_public_ip_association
      args  = [self.input.public_ip_id.value]
    }

    card {
      width = 2
      query = query.vcn_public_ip_lifetime
      args  = [self.input.public_ip_id.value]
    }

    card {
      width = 2
      query = query.vcn_public_ip_public_ip_address
      args  = [self.input.public_ip_id.value]
    }
  }

  with "vcn_nat_gateways" {
    query = query.vcn_public_ip_vcn_nat_gateways
    args  = [self.input.public_ip_id.value]
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.vcn_public_ip
        args = {
          vcn_public_ip_ids = [self.input.public_ip_id.value]
        }
      }

      node {
        base = node.vcn_nat_gateway
        args = {
          vcn_nat_gateway_ids = with.vcn_nat_gateways.rows[*].nat_gateway_id
        }
      }

      edge {
        base = edge.vcn_nat_gateway_to_vcn_public_ip
        args = {
          vcn_nat_gateway_ids = with.vcn_nat_gateways.rows[*].nat_gateway_id
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
        query = query.vcn_public_ip_overview
        args  = [self.input.public_ip_id.value]
      }

      table {
        title = "Tags"
        width = 6
        query = query.vcn_public_ip_tags
        args  = [self.input.public_ip_id.value]
      }

    }

    container {

      width = 6

      table {
        title = "Association"
        query = query.vcn_public_ip_association_details
        args  = [self.input.public_ip_id.value]

      }
    }

  }
}

# Input queries

query "vcn_public_ip_input" {
  sql = <<-EOQ
    select
      p.display_name as label,
      p.id as value,
      json_build_object(
        'c.name', coalesce(c.title, 'root'),
        't.name', t.name
      ) as tags
    from
      oci_core_public_ip as p
      left join oci_identity_compartment as c on p.compartment_id = c.id
      left join oci_identity_tenancy as t on p.tenant_id = t.id
    where
      p.lifecycle_state <> 'TERMINATED'
    order by
      p.display_name;
  EOQ
}

# Card queries

query "vcn_public_ip_association" {
  sql = <<-EOQ
    select
      'Association' as label,
      case when assigned_entity_id is not null then 'Associated' else 'Not Associated' end as value,
      case when assigned_entity_id is not null then 'ok' else 'alert' end as type
    from
      oci_core_public_ip
    where
      id = $1;
  EOQ

}

query "vcn_public_ip_lifetime" {
  sql = <<-EOQ
    select
      'Lifetime' as label,
      lifetime as value
    from
      oci_core_public_ip
    where
      id = $1;
  EOQ

}

query "vcn_public_ip_public_ip_address" {
  sql = <<-EOQ
    select
      'Public IP Address' as label,
      ip_address as value
    from
      oci_core_public_ip
    where
      id = $1;
  EOQ

}

# With Queries

query "vcn_public_ip_vcn_nat_gateways" {
  sql   = <<-EOQ
    select
      assigned_entity_id as nat_gateway_id
    from
      oci_core_public_ip
    where
      assigned_entity_type = 'NAT_GATEWAY'
      and id = $1;
  EOQ
}

# Other detail page queries

query "vcn_public_ip_overview" {
  sql = <<-EOQ
    select
      display_name as "Name",
      time_created as "Time Created",
      scope as "Scope",
      id as "OCID",
      compartment_id as "Compartment ID"
    from
      oci_core_public_ip
    where
      id = $1
  EOQ

}

query "vcn_public_ip_tags" {
  sql = <<-EOQ
    select
      tags ->> 'Key' as "Key",
      tags ->> 'Value' as "Value"
    from
      oci_core_public_ip
    where
      id = $1
    order by
      tags ->> 'Key';
  EOQ

}

query "vcn_public_ip_association_details" {
  sql = <<-EOQ
    select
      assigned_entity_type as "Assigned Entity Type",
      n.display_name as "Assigned Entity Name",
      assigned_entity_id  as "Assigned Entity ID"
    from
      oci_core_public_ip as p,
      oci_core_nat_gateway as n
    where
      n.id = p.assigned_entity_id
      and p.id = $1;
  EOQ

}
