dashboard "mysql_db_system_detail" {

  title = "OCI MySQL DB System Detail"

  tags = merge(local.mysql_common_tags, {
    type = "Detail"
  })

  input "db_system_id" {
    title = "Select a DB system:"
    query = query.mysql_db_system_input
    width = 4
  }

  container {

    card {
      width = 3

      query = query.mysql_db_system_mysql_version
      args = [self.input.db_system_id.value]
    }

    card {
      width = 3

      query = query.mysql_db_system_backup
      args = [self.input.db_system_id.value]
    }

  }

  with "mysql_backups_for_mysql_db_system" {
    query = query.mysql_backups_for_mysql_db_system
    args  = [self.input.db_system_id.value]
  }

  with "mysql_channels_for_mysql_db_system" {
    query = query.mysql_channels_for_mysql_db_system
    args  = [self.input.db_system_id.value]
  }

  with "mysql_configurations_for_mysql_db_system" {
    query = query.mysql_configurations_for_mysql_db_system
    args  = [self.input.db_system_id.value]
  }

  with "vcn_subnets_for_mysql_db_system" {
    query = query.vcn_subnets_for_mysql_db_system
    args  = [self.input.db_system_id.value]
  }

  with "vcn_vcns_for_mysql_db_system" {
    query = query.vcn_vcns_for_mysql_db_system
    args  = [self.input.db_system_id.value]
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.mysql_backup
        args = {
          mysql_backup_ids = with.mysql_backups_for_mysql_db_system.rows[*].backup_id
        }
      }

      node {
        base = node.mysql_channel
        args = {
          mysql_channel_ids = with.mysql_channels_for_mysql_db_system.rows[*].channel_id
        }
      }

      node {
        base = node.mysql_configuration
        args = {
          mysql_configuration_ids = with.mysql_configurations_for_mysql_db_system.rows[*].configuration_id
        }
      }

      node {
        base = node.mysql_db_system
        args = {
          mysql_db_system_ids = [self.input.db_system_id.value]
        }
      }

      node {
        base = node.vcn_subnet
        args = {
          vcn_subnet_ids = with.vcn_subnets_for_mysql_db_system.rows[*].subnet_id
        }
      }

      node {
        base = node.vcn_vcn
        args = {
          vcn_vcn_ids = with.vcn_vcns_for_mysql_db_system.rows[*].vcn_id
        }
      }

      edge {
        base = edge.mysql_db_system_to_mysql_backup
        args = {
          mysql_db_system_ids = [self.input.db_system_id.value]
        }
      }

      edge {
        base = edge.mysql_db_system_to_mysql_channel
        args = {
          mysql_db_system_ids = [self.input.db_system_id.value]
        }
      }

      edge {
        base = edge.mysql_db_system_to_mysql_configuration
        args = {
          mysql_db_system_ids = [self.input.db_system_id.value]
        }
      }

      edge {
        base = edge.vcn_subnet_to_vcn_vcn
        args = {
          vcn_subnet_ids = with.vcn_subnets_for_mysql_db_system.rows[*].subnet_id
        }
      }

      edge {
        base = edge.mysql_db_system_to_vcn_subnet
        args = {
          mysql_db_system_ids = [self.input.db_system_id.value]
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
        query = query.mysql_db_system_overview
        args = [self.input.db_system_id.value]

      }

      table {
        title = "Tags"
        width = 6
        query = query.mysql_db_system_tag
        args = [self.input.db_system_id.value]

      }
    }

    container {
      width = 6

      table {
        title = "Backup Policy"
        query = query.mysql_db_system_backup_policy
        args = [self.input.db_system_id.value]
      }
    }

    container {

      table {
        title = "Endpoint Details"
        query = query.mysql_db_system_endpoint
        args = [self.input.db_system_id.value]
      }
    }

    container {

      chart {
        title = "Metric Connections - Last 7 Days"
        type  = "line"
        width = 6
        query = query.mysql_db_system_connection
        args = [self.input.db_system_id.value]
      }
    }

  }
}

# Input queries

query "mysql_db_system_input" {
  sql = <<-EOQ
    select
      b.display_name as label,
      b.id as value,
      json_build_object(
        'b.id', concat('id: ', right(reverse(split_part(reverse(b.id), '.', 1)), 8)),
        'b.region', concat('region: ', region),
        'c.name', concat('compartment: ', coalesce(c.title, 'root')),
        't.name', concat('tenant: ', t.name)
      ) as tags
    from
      oci_mysql_db_system as b
      left join oci_identity_compartment as c on b.compartment_id = c.id
      left join oci_identity_tenancy as t on b.tenant_id = t.id
    where
      b.lifecycle_state <> 'DELETED'
    order by
      b.display_name;
  EOQ
}

# With queries

query "mysql_backups_for_mysql_db_system" {
  sql = <<-EOQ
    select
      id as backup_id
    from
      oci_mysql_backup
    where
      db_system_id = $1
  EOQ
}

query "mysql_configurations_for_mysql_db_system" {
  sql = <<-EOQ
    select
      configuration_id
    from
      oci_mysql_db_system
    where
      id = $1
  EOQ
}

query "mysql_channels_for_mysql_db_system" {
  sql = <<-EOQ
    select
      id as channel_id
    from
      oci_mysql_channel
    where
      target ->> 'dbSystemId' = $1
  EOQ
}

query "vcn_vcns_for_mysql_db_system" {
  sql = <<-EOQ
    select
      s.vcn_id as vcn_id
    from
      oci_mysql_db_system as m,
      oci_core_subnet as s
    where
      m.subnet_id = s.id
      and m.id = $1
  EOQ
}

query "vcn_subnets_for_mysql_db_system" {
  sql = <<-EOQ
    select
      subnet_id
    from
      oci_mysql_db_system as m
    where
      m.id = $1
  EOQ
}

# Card queries

query "mysql_db_system_mysql_version" {
  sql = <<-EOQ
    select
      mysql_version as "MySQL Version"
    from
      oci_mysql_db_system
    where
      id = $1;
  EOQ
}

query "mysql_db_system_backup" {
  sql = <<-EOQ
    select
      'Backup Status' as label,
      case when b.id is null then 'Disabled' else 'Enabled' end as value,
      case when b.id is null then 'alert' else 'ok' end as type
    from
      oci_mysql_db_system as s
      left join oci_mysql_backup as b on s.id = b.db_system_id
    where
      s.id = $1;
  EOQ
}

# Other detail page queries

query "mysql_db_system_overview" {
  sql = <<-EOQ
    select
      display_name as "Name",
      time_created as "Time Created",
      id as "OCID",
      compartment_id as "Compartment ID"
    from
      oci_mysql_db_system
    where
      id = $1;
  EOQ
}

query "mysql_db_system_tag" {
  sql = <<-EOQ
    with jsondata as (
      select
      tags::json as tags
    from
      oci_mysql_db_system
    where
      id = $1
    )
    select
      key as "Key",
      value as "Value"
    from
      jsondata,
      json_each_text(tags);
  EOQ
}

query "mysql_db_system_backup_policy" {
  sql = <<-EOQ
    select
      backup_policy ->> 'isEnabled' as "Automatic Backup Enabled",
      backup_policy ->> 'retentionInDays' as "Backup Retention Days"
    from
      oci_mysql_db_system
    where
      id  = $1;
  EOQ
}

query "mysql_db_system_endpoint" {
  sql = <<-EOQ
    select
      e ->> 'hostname' as "Hostname",
      e ->> 'ipAddress' as "IP Address",
      e ->> 'modes' as "Modes",
      e ->> 'port' as "Port",
      e ->> 'portX' as "PortX",
      e ->> 'status' as "Status"
    from
      oci_mysql_db_system,
      jsonb_array_elements(endpoints) as e
    where
      id = $1;
  EOQ
}

query "mysql_db_system_connection" {
  sql = <<-EOQ
    select
      timestamp,
      (sum / 300) as metric_connection
    from
      oci_mysql_db_system_metric_connections
    where
      timestamp >= current_date - interval '7 day' and id = $1
    order by timestamp;
  EOQ
}
