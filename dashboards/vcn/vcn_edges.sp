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

edge "vcn_network_security_group_to_compute_instance" {
  title = "instance"

  sql = <<-EOQ
    with network_security_groups as (
      select
        jsonb_array_elements_text(nsg_ids) as n_id,
        instance_id
      from
        oci_core_vnic_attachment
    )
    select
      id as from_id,
      instance_id as to_id
    from
      oci_core_network_security_group,
      network_security_groups
    where
      id = n_id
      and instance_id = any($1)
  EOQ

  param "compute_instance_ids" {}
}

edge "vcn_network_security_group_to_file_storage_mount_target" {
  title = "mount target"

  sql = <<-EOQ
    with network_security_groups as (
      select
        jsonb_array_elements_text(nsg_ids) as n_id,
        id
      from
        oci_file_storage_mount_target
    )
    select
      n.id as from_id,
      s.id as to_id
    from
      oci_core_network_security_group as n,
      network_security_groups as s
    where
      n.id = n_id
      and s.id = any($1)
  EOQ

  param "file_storage_mount_target_ids" {}
}

edge "vcn_network_security_group_to_vcn_load_balancer" {
  title = "load balancer"

  sql = <<-EOQ
    with nsg_list as (
      select
        id as nsg_id
      from
        oci_core_network_security_group
      where
        id = any($1)
      )
      select
        s as from_id,
        id as to_id
      from
        oci_core_load_balancer,
        jsonb_array_elements_text(network_security_group_ids) as s
      where
        s in (select nsg_id from nsg_list);
  EOQ

  param "vcn_network_security_group_ids" {}
}

edge "vcn_network_security_group_to_vcn_network_load_balancer" {
  title = "network load balancer"

  sql = <<-EOQ
    with nsg_list as (
      select
        id as nsg_id
      from
        oci_core_network_security_group
      where
        id = any($1)
      )
      select
        s as from_id,
        id as to_id
      from
        oci_core_network_load_balancer,
        jsonb_array_elements_text(network_security_group_ids) as s
      where
        s in (select nsg_id from nsg_list);
  EOQ

  param "vcn_network_security_group_ids" {}
}

edge "vcn_network_security_group_to_vcn_vnic" {
  title = "vnic"

  sql = <<-EOQ
    with network_security_groups as (
      select
        jsonb_array_elements_text(nsg_ids) as n_id,
        vnic_id
      from
        oci_core_vnic_attachment
    )
    select
      n_id as from_id,
      vnic_id as to_id
    from
      oci_core_network_security_group,
      network_security_groups
    where
      id = n_id
      and vnic_id = any($1)
  EOQ

  param "vcn_vnic_ids" {}
}

edge "vcn_subnet_to_compute_instance" {
  title = "instance"

  sql = <<-EOQ
    select
      s.id as from_id,
      i.id as to_id
    from
      oci_core_instance as i,
      oci_core_subnet as s,
      oci_core_vnic_attachment as v
    where
      v.instance_id = i.id
      and v.subnet_id = s.id
      and i.id = any($1);
  EOQ

  param "compute_instance_ids" {}
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
      id = any($1);
  EOQ

  param "vcn_flow_log_ids" {}
}

edge "vcn_subnet_to_vcn_security_list" {
  title = "security list"

  sql = <<-EOQ
    with subnet_security_lists as (
      select
        jsonb_array_elements_text(security_list_ids) as s_id,
        id as subnet_id
      from
        oci_core_subnet
      )
      select
        ssl.subnet_id as from_id,
        sl.id as to_id
      from
        oci_core_security_list as sl,
        subnet_security_lists as ssl
      where
        sl.id = ssl.s_id
        and sl.id = any($1);
  EOQ

  param "vcn_security_list_ids" {}
}

edge "vcn_subnet_to_vcn_load_balancer" {
  title = "load balancer"

  sql = <<-EOQ
    with subnet_list as (
      select
        id as subnet_id
      from
        oci_core_subnet
      where
        id = any($1)
      )
      select
        subnet_ids as from_id,
        id as to_id
      from
        oci_core_load_balancer,
        jsonb_array_elements_text(subnet_ids) as s
      where
        s in (select subnet_id from subnet_list);
  EOQ

  param "vcn_subnet_ids" {}
}

edge "vcn_subnet_to_vcn_network_load_balancer" {
  title = "network load balancer"

  sql = <<-EOQ
    select
      subnet_id as from_id,
      id as to_id
    from
      oci_core_network_load_balancer
    where
      id = any($1);
  EOQ

  param "vcn_network_load_balancer_ids" {}
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
      id = any($1);
  EOQ

  param "vcn_dhcp_option_ids" {}
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

edge "vcn_nat_gateway_vcn_vcn" {
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

edge "vcn_vcn_to_vcn_network_security_group" {
  title = "nsg"

  sql = <<-EOQ
    select
      vcn_id as from_id,
      id as to_id
    from
      oci_core_network_security_group
    where
      id = any($1);
  EOQ

  param "vcn_network_security_group_ids" {}
}

edge "vcn_subnet_to_vcn_route_table" {
  title = "route table"

  sql = <<-EOQ
    select
      id as from_id,
      route_table_id as to_id
    from
      oci_core_subnet
    where
      route_table_id = any($1);
  EOQ

  param "vcn_route_table_ids" {}
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
      id = any($1);
  EOQ

  param "vcn_security_list_ids" {}
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

edge "vcn_availability_domain_to_vcn_regional_subnet" {
  title = "subnet"

  sql = <<-EOQ
    with ad as (
      select
        a.id as ad_id,
        a.region as ad_region
      from
        oci_identity_availability_domain as a,
        oci_region as r
      where
        a.region = r.name
    )
    select
      ad_id as from_id,
      id as to_id
    from
      oci_core_subnet,
      ad
    where
      availability_domain is null
      and ad_region = region
      and id = any($1);
  EOQ

  param "vcn_subnet_ids" {}
}
