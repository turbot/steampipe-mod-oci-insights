node "vcn_dhcp_option" {
  category = category.vcn_dhcp_option

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'ID', id,
        'Display Name', display_name,
        'Time Created', time_created,
        'Lifecycle State', lifecycle_state,
        'Region', region,
        'compartment ID', compartment_id
      ) as properties
    from
      oci_core_dhcp_options
    where
      id = any($1);
  EOQ

  param "vcn_dhcp_option_ids" {}
}

node "vcn_flow_log" {
  category = category.vcn_flow_log

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'ID', id,
        'Display Name', name,
        'Retention Duration', retention_duration,
        'Time Created', time_created,
        'Lifecycle State', lifecycle_state,
        'Region', region,
        'compartment ID', compartment_id
      ) as properties
    from
      oci_logging_log
    where
      configuration -> 'source' ->> 'service' = 'flowlogs'
      and id = any($1);
  EOQ

  param "vcn_flow_log_ids" {}
}

node "vcn_internet_gateway" {
  category = category.vcn_internet_gateway

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'ID', id,
        'VCN ID', vcn_id,
        'Is Enabled', is_enabled,
        'Time Created', time_created,
        'Display_Name', display_name,
        'Lifecycle State', lifecycle_state,
        'Compartment ID', compartment_id,
        'Region', region
      ) as properties
    from
      oci_core_internet_gateway
    where
      id = any($1 ::text[]);
  EOQ

  param "vcn_internet_gateway_ids" {}
}

node "vcn_load_balancer" {
  category = category.vcn_load_balancer

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'ID', id,
        'Display Name', display_name,
        'Is Private', is_private,
        'Time Created', time_created,
        'Lifecycle State', lifecycle_state,
        'Region', region,
        'compartment ID', compartment_id
      ) as properties
    from
      oci_core_load_balancer
    where
      id = any($1);
  EOQ

  param "vcn_load_balancer_ids" {}
}

node "vcn_local_peering_gateway" {
  category = category.vcn_local_peering_gateway

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'ID', id,
        'Display Name', name,
        'Time Created', time_created,
        'Lifecycle State', lifecycle_state,
        'Region', region,
        'compartment ID', compartment_id
      ) as properties
    from
      oci_core_local_peering_gateway
    where
      id = any($1);
  EOQ

  param "vcn_local_peering_gateway_ids" {}
}

node "vcn_nat_gateway" {
  category = category.vcn_nat_gateway

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'ID', id,
        'Display Name', display_name,
        'Lifecycle State', lifecycle_state,
        'Time Created', time_created,
        'Compartment ID', compartment_id,
        'Region', region
      ) as properties
    from
      oci_core_nat_gateway
    where
      id = any($1);
  EOQ

  param "vcn_nat_gateway_ids" {}
}

node "vcn_network_load_balancer" {
  category = category.vcn_network_load_balancer

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'ID', id,
        'Display Name', display_name,
        'Lifecycle State', lifecycle_state,
        'Time Created', time_created,
        'Compartment ID', compartment_id,
        'Region', region
      ) as properties
    from
      oci_core_network_load_balancer
    where
      id = any($1);
  EOQ

  param "vcn_network_load_balancer_ids" {}
}

node "vcn_network_security_group" {
  category = category.vcn_network_security_group

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'ID', id,
        'Display Name', display_name,
        'Lifecycle State', lifecycle_state,
        'Time Created', time_created,
        'Compartment ID', compartment_id,
        'Region', region
      ) as properties
    from
      oci_core_network_security_group
    where
      id = any($1);
  EOQ

  param "vcn_network_security_group_ids" {}
}

node "vcn_route_table" {
  category = category.vcn_route_table

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'ID', id,
        'Display Name', display_name,
        'Time Created', time_created,
        'Lifecycle State', lifecycle_state,
        'Region', region,
        'compartment ID', compartment_id
      ) as properties
    from
      oci_core_route_table
    where
      id = any($1);
  EOQ

  param "vcn_route_table_ids" {}
}

node "vcn_security_list" {
  category = category.vcn_security_list

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'ID', id,
        'Display Name', display_name,
        'Time Created', time_created,
        'Lifecycle State', lifecycle_state,
        'Region', region,
        'compartment ID', compartment_id
      ) as properties
    from
      oci_core_security_list
    where
      id = any($1);
  EOQ

  param "vcn_security_list_ids" {}
}

node "vcn_service_gateway" {
  category = category.vcn_service_gateway

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'ID', id,
        'Display Name', display_name,
        'Time Created', time_created,
        'Lifecycle State', lifecycle_state,
        'Region', region,
        'compartment ID', compartment_id
      ) as properties
    from
      oci_core_service_gateway
    where
      id = any($1);
  EOQ

  param "vcn_service_gateway_ids" {}
}

node "vcn_subnet" {
  category = category.vcn_subnet

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'Subnet ID', id,
        'Subnet Domain Name', subnet_domain_name,
        'CIDR Block', cidr_block,
        'Time Created', time_created,
        'Display_Name', display_name,
        'Lifecycle State', lifecycle_state,
        'Compartment ID', compartment_id,
        'Region', region
      ) as properties
    from
      oci_core_subnet
    where
      id = any($1 ::text[]);
  EOQ

  param "vcn_subnet_ids" {}
}

node "vcn_vcn" {
  category = category.vcn_vcn

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'VCN ID', id,
        'Display Name', display_name,
        'Lifecycle State', lifecycle_state,
        'CIDR Block', cidr_block,
        'DNS Label', dns_label,
        'Compartment ID', compartment_id,
        'Region', region
      ) as properties
    from
      oci_core_vcn
    where
      id = any($1);
  EOQ

  param "vcn_vcn_ids" {}
}
