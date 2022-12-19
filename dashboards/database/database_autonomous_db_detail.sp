dashboard "database_autonomous_database_detail" {

  title = "OCI Autonomous Database Detail"

  tags = merge(local.database_common_tags, {
    type = "Detail"
  })

  input "db_id" {
    title = "Select an autonomous DB:"
    query = query.database_autonomous_database_input
    width = 4
  }

  container {

    card {
      width = 2

      query = query.database_autonomous_database_core
      args = {
        id = self.input.db_id.value
      }
    }

    card {
      width = 2

      query = query.database_autonomous_database_data_guard
      args = {
        id = self.input.db_id.value
      }
    }

    card {
      width = 2

      query = query.database_autonomous_db_operations_insights
      args = {
        id = self.input.db_id.value
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
        query = query.database_autonomous_database_overview
        args = {
          id = self.input.db_id.value
        }
      }

      table {
        title = "Tags"
        width = 6
        query = query.database_autonomous_database_tag
        args = {
          id = self.input.db_id.value
        }
      }
    }

    container {
      width = 6

      table {
        title = "DB Details"
        query = query.database_autonomous_database_db
        args = {
          id = self.input.db_id.value
        }
      }

      table {
        title = "Backup Config"
        query = query.database_autonomous_database_backup
        args = {
          id = self.input.db_id.value
        }
      }
    }

    container {
      width = 6

      table {
        title = "Private Endpoint Details"
        query = query.database_autonomous_database_private_endpoint
        args = {
          id = self.input.db_id.value
        }
      }
    }
    container {
      width = 6

      table {
        title = "Access Details"
        query = query.database_autonomous_database_access_detail
        args = {
          id = self.input.db_id.value
        }
      }
    }
  }
}

query "database_autonomous_database_input" {
  sql = <<EOQ
    select
      d.display_name as label,
      d.id as value,
      json_build_object(
        'c.name', coalesce(c.title, 'root'),
        'd.region', region,
        't.name', t.name
      ) as tags
    from
      oci_database_autonomous_database as d
      left join oci_identity_compartment as c on d.compartment_id = c.id
      left join oci_identity_tenancy as t on d.tenant_id = t.id
    where
      d.lifecycle_state <> 'TERMINATED'
    order by
      d.display_name;
EOQ
}

query "database_autonomous_database_core" {
  sql = <<-EOQ
    select
      cpu_core_count as "OCPUs"
    from
      oci_database_autonomous_database
    where
      id = $1;
  EOQ

  param "id" {}
}

query "database_autonomous_database_data_guard" {
  sql = <<-EOQ
    select
      case when is_data_guard_enabled then 'Enabled' else 'Disabled' end as value,
      'Data Guard' as label,
      case when is_data_guard_enabled then 'ok' else 'alert' end as type
    from
      oci_database_autonomous_database
    where
      id = $1;
  EOQ

  param "id" {}
}

query "database_autonomous_db_operations_insights" {
  sql = <<-EOQ
    select
      case when operations_insights_status = 'NOT_ENABLED' then 'Enabled' else 'Disabled' end as value,
      'Operations Insights' as label,
      case when operations_insights_status = 'NOT_ENABLED' then 'ok' else 'alert' end as type
    from
      oci_database_autonomous_database
    where
      id = $1;
  EOQ

  param "id" {}
}

query "database_autonomous_database_overview" {
  sql = <<-EOQ
    select
      display_name as "Name",
      time_created as "Time Created",
      is_dedicated as "Dedicated",
      is_free_tier as "Free Tier",
      data_storage_size_in_gbs as "Total Size (GB)",
      license_model as "License Model",
      id as "OCID",
      compartment_id as "Compartment ID"
    from
      oci_database_autonomous_database
    where
      id = $1;
  EOQ

  param "id" {}
}

query "database_autonomous_database_tag" {
  sql = <<-EOQ
    with jsondata as (
    select
      tags::json as tags
    from
      oci_database_autonomous_database
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

  param "id" {}
}

query "database_autonomous_database_db" {
  sql = <<-EOQ
    select
      db_name as "DB Name",
      db_version as "DB Version",
      db_workload as "DB Workload"
    from
      oci_database_autonomous_database
    where
      id  = $1;
  EOQ

  param "id" {}
}

query "database_autonomous_database_backup" {
  sql = <<-EOQ
    select
      backup_config ->> 'manualBackupBucketName' as "Manual Backup Bucket Name",
      backup_config ->> 'manualBackupType' as "Manual Backup Type"
    from
      oci_database_autonomous_database
    where
      id  = $1;
  EOQ

  param "id" {}
}

query "database_autonomous_database_private_endpoint" {
  sql = <<-EOQ
    select
      private_endpoint as "Private Endpoint",
      private_endpoint_ip as "Private Endpoint IP",
      private_endpoint_label as "Private Endpoint Label"
    from
      oci_database_autonomous_database
    where
      id = $1;
  EOQ

  param "id" {}
}

query "database_autonomous_database_access_detail" {
  sql = <<-EOQ
    select
      is_access_control_enabled as "Access Control Enabled",
      open_mode as "Open Mode",
      permission_level as "Permission Level"
    from
      oci_database_autonomous_database
    where
      id = $1;
  EOQ

  param "id" {}
}
