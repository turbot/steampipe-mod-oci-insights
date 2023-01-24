edge "vcn_internet_gateway_to_vcn_vcn" {
  title = "vcn"

  sql = <<-EOQ
    select
      id as from_id,
      vcn_id as to_id
    from
      oci_core_internet_gateway
    where
      id = any($1);
  EOQ

  param "vcn_internet_gateway_ids" {}
}

edge "vcn_load_balancer_to_compute_instance" {
  title = "routes to"

  sql = <<-EOQ
    select
      lb.id as from_id,
      a.instance_id as to_id
    from
      oci_core_vnic_attachment as a,
      oci_core_load_balancer as lb,
      jsonb_array_elements_text(subnet_ids) as sid
    where
      a.subnet_id = sid
      and lb.id = any($1);
  EOQ

  param "vcn_load_balancer_ids" {}
}

edge "vcn_local_peering_gateway_to_vcn_vcn" {
  title = "vcn"

  sql = <<-EOQ
    select
      id as from_id,
      vcn_id as to_id
    from
      oci_core_local_peering_gateway
    where
      id = any($1);
  EOQ

  param "vcn_local_peering_gateway_ids" {}
}

edge "vcn_nat_gateway_to_vcn_public_ip" {
  title = "public ip"

  sql = <<-EOQ
    select
      assigned_entity_id as from_id,
      id as to_id
    from
      oci_core_public_ip
    where
      assigned_entity_type = 'NAT_GATEWAY'
      and assigned_entity_id = any($1);
  EOQ

  param "vcn_nat_gateway_ids" {}
}

edge "vcn_nat_gateway_to_vcn_vcn" {
  title = "vcn"

  sql = <<-EOQ
    select
      id as from_id,
      vcn_id as to_id
    from
      oci_core_nat_gateway
    where
      id = any($1);
  EOQ

  param "vcn_nat_gateway_ids" {}
}

edge "vcn_network_load_balancer_to_compute_instance" {
  title = "routes to"

  sql = <<-EOQ
    select
      n.id as from_id,
      a.instance_id as to_id
    from
      oci_core_vnic_attachment as a,
      oci_core_network_load_balancer as n
    where
      n.subnet_id = a.subnet_id
      and n.id = any($1);
  EOQ

  param "vcn_network_load_balancer_ids" {}
}

edge "vcn_network_security_group_to_compute_instance" {
  title = "instance"

  sql = <<-EOQ
    select
      nid as from_id,
      instance_id as to_id
    from
      oci_core_vnic_attachment,
      jsonb_array_elements_text(nsg_ids) as nid
    where
      nid = any($1);
  EOQ

  param "vcn_network_security_group_ids" {}
}

edge "vcn_network_security_group_to_filestorage_mount_target" {
  title = "mount target"

  sql = <<-EOQ
    select
      nid as from_id,
      id as to_id
    from
      oci_file_storage_mount_target,
      jsonb_array_elements_text(nsg_ids) as nid
    where
      nid = any($1);
  EOQ

  param "vcn_network_security_group_ids" {}
}

edge "vcn_network_security_group_to_vcn_load_balancer" {
  title = "load balancer"

  sql = <<-EOQ
    select
      nid as from_id,
      id as to_id
    from
      oci_core_load_balancer,
      jsonb_array_elements_text(network_security_group_ids) as nid
    where
      nid = any($1);
  EOQ

  param "vcn_network_security_group_ids" {}
}

edge "vcn_network_security_group_to_vcn_network_load_balancer" {
  title = "nlb"

  sql = <<-EOQ
    select
      nid as from_id,
      id as to_id
    from
      oci_core_network_load_balancer,
      jsonb_array_elements_text(network_security_group_ids) as nid
    where
      nid = any($1);
  EOQ

  param "vcn_network_security_group_ids" {}
}

edge "vcn_network_security_group_to_vcn_vnic" {
  title = "vnic"

  sql = <<-EOQ
    select
      nid as from_id,
      vnic_id as to_id
    from
      oci_core_vnic_attachment,
      jsonb_array_elements_text(nsg_ids) as nid
    where
      nid = any($1);
  EOQ

  param "vcn_network_security_group_ids" {}
}

edge "vcn_service_gateway_to_vcn_vcn" {
  title = "vcn"

  sql = <<-EOQ
    select
      id as from_id,
      vcn_id as to_id
    from
      oci_core_service_gateway
    where
      id = any($1);
  EOQ

  param "vcn_service_gateway_ids" {}
}

edge "vcn_subnet_to_compute_instance" {
  title = "instance"

  sql = <<-EOQ
    select
      subnet_id as from_id,
      instance_id as to_id
    from
      oci_core_vnic_attachment
    where
      subnet_id = any($1);
  EOQ

  param "vcn_subnet_ids" {}
}

edge "vcn_subnet_to_vcn_dhcp_option" {
  title = "dhcp option"

  sql = <<-EOQ
    select
      id as from_id,
      dhcp_options_id as to_id
    from
      oci_core_subnet
    where
      id = any($1);
  EOQ

  param "vcn_subnet_ids" {}
}

edge "vcn_subnet_to_vcn_flow_log" {
  title = "flow log"

  sql = <<-EOQ
    select
      configuration -> 'source' ->> 'resource' as from_id,
      id as to_id
    from
      oci_logging_log
    where
      configuration -> 'source' ->> 'resource' = any($1);
  EOQ

  param "vcn_subnet_ids" {}
}

edge "vcn_subnet_to_vcn_load_balancer" {
  title = "load balancer"

  sql = <<-EOQ
    select
      sid as from_id,
      id as to_id
    from
      oci_core_load_balancer,
      jsonb_array_elements_text(subnet_ids) as sid
    where
      sid = any($1);
  EOQ

  param "vcn_subnet_ids" {}
}

edge "vcn_subnet_to_vcn_network_load_balancer" {
  title = "nlb"

  sql = <<-EOQ
    select
      subnet_id as from_id,
      id as to_id
    from
      oci_core_network_load_balancer
    where
      subnet_id = any($1);
  EOQ

  param "vcn_subnet_ids" {}
}

edge "vcn_subnet_to_vcn_route_table" {
  title = "route table"

  sql = <<-EOQ
    select
      coalesce(s.id, r.vcn_id ) as from_id,
      r.id as to_id
    from
      oci_core_route_table as r
      left join oci_core_subnet as s on r.id = s.route_table_id
    where
      r.id = any($1);
  EOQ

  param "vcn_route_table_ids" {}
}

edge "vcn_subnet_to_vcn_security_list" {
  title = "security list"

  sql = <<-EOQ
    select
      id as from_id,
      sid as to_id
    from
      oci_core_subnet,
      jsonb_array_elements_text(security_list_ids) as sid
    where
      id = any($1)
  EOQ

  param "vcn_subnet_ids" {}
}

edge "vcn_vcn_to_identity_availability_domain" {
  title = "availability domain"

  sql = <<-EOQ
    select
      v.id as from_id,
      a.id as to_id
    from
      oci_identity_availability_domain as a,
      oci_core_vcn as v
    where
      a.region = v.region
      and v.id = any($1);
  EOQ

  param "vcn_vcn_ids" {}
}

edge "vcn_vcn_to_vcn_dhcp_option" {
  title = "dhcp option"

  sql = <<-EOQ
    select
      vcn_id as from_id,
      id as to_id
    from
      oci_core_dhcp_options
    where
      vcn_id = any($1);
  EOQ

  param "vcn_vcn_ids" {}
}

edge "vcn_vcn_to_vcn_network_security_group" {
  title = "nsg"

  sql = <<-EOQ
    select
      vcn_id as from_id,
      id as to_id
    from
      oci_core_network_security_group
    where
      vcn_id = any($1);
  EOQ

  param "vcn_vcn_ids" {}
}

edge "vcn_vcn_to_vcn_security_list" {
  title = "security list"

  sql = <<-EOQ
    select
      vcn_id as from_id,
      id as to_id
    from
      oci_core_security_list
    where
      vcn_id = any($1);
  EOQ

  param "vcn_vcn_ids" {}
}

edge "vcn_subnet_to_vcn_vcn" {
  title = "vcn"

  sql = <<-EOQ
    select
      id as from_id,
      vcn_id as to_id
    from
      oci_core_subnet
    where
      id = any($1);
  EOQ

  param "vcn_subnet_ids" {}
}
