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

edge "vcn_subnet_to_vcn_route_table" {
  title = "route table"

  sql = <<-EOQ
    select
      id as from_id,
      route_table_id as to_id
    from
      oci_core_subnet as s
    where
     id = any($1);
  EOQ

  param "vcn_subnet_ids" {}
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

edge "vcn_vcn_to_vcn_local_peering_gateway" {
  title = "local peering gateway"

  sql = <<-EOQ
    select
      vcn_id as from_id,
      id as to_id
    from
      oci_core_local_peering_gateway
    where
      id = any($1);
  EOQ

  param "vcn_local_peering_gateway_ids" {}
}

edge "vcn_vcn_to_vcn_nat_gateway" {
  title = "nat gateway"

  sql = <<-EOQ
    select
      vcn_id as from_id,
      id as to_id
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

edge "vcn_vcn_to_vcn_route_table" {
  title = "route table"

  sql = <<-EOQ
    select
      vcn_id as from_id,
      id as to_id
    from
      oci_core_route_table
    where
      id = any($1);
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

edge "vcn_vcn_to_vcn_service_gateway" {
  title = "service gateway"

  sql = <<-EOQ
    select
      vcn_id as from_id,
      id as to_id
    from
      oci_core_service_gateway
    where
      id = any($1);
  EOQ

  param "vcn_service_gateway_ids" {}
}

edge "vcn_vcn_to_vcn_subnet" {
  title = "subnet"

  sql = <<-EOQ
    select
      vcn_id as from_id,
      id as to_id
    from
      oci_core_subnet
    where
      id = any($1);
  EOQ

  param "vcn_subnet_ids" {}
}
