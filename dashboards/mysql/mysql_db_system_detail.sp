dashboard "oci_mysql_db_system_detail" {

  title = "OCI MySQL DB System Detail"

  tags = merge(local.mysql_common_tags, {
    type = "Detail"
  })

  input "db_system_id" {
    title = "Select a DB system:"
    query = query.oci_mysql_db_system_input
    width = 4
  }

  container {

    card {
      width = 2

      query = query.oci_mysql_db_system_mysql_version
      args = {
        id = self.input.db_system_id.value
      }
    }

    card {
      width = 2

      query = query.oci_mysql_db_system_backup
      args = {
        id = self.input.db_system_id.value
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
        query = query.oci_mysql_db_system_overview
        args = {
          id = self.input.db_system_id.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.oci_mysql_db_system_tag
        args = {
          id = self.input.db_system_id.value
        }

      }
    }

    container {
      width = 6

      table {
        title = "Backup Policy"
        query = query.oci_mysql_db_system_backup_policy
        args = {
          id = self.input.db_system_id.value
        }
      }
    }

    container {

      table {
        title = "Endpoint Details"
        query = query.oci_mysql_db_system_endpoint
        args = {
          id = self.input.db_system_id.value
        }
      }
    }

    container {

      chart {
        title = "Metric Connections - Last 7 Days"
        type  = "line"
        width = 6
        query = query.oci_mysql_db_system_connection
        args = {
          id = self.input.db_system_id.value
        }
      }
    }

  }
}

query "oci_mysql_db_system_input" {
  sql = <<EOQ
    select
      s.display_name as label,
      s.id as value,
      json_build_object(
        'c.name', coalesce(c.title, 'root'),
        's.region', region,
        't.name', t.name
      ) as tags
    from
      oci_mysql_db_system as s
      left join oci_identity_compartment as c on s.compartment_id = c.id
      left join oci_identity_tenancy as t on s.tenant_id = t.id
    where
      s.lifecycle_state <> 'DELETED'
    order by
      s.display_name;
EOQ
}

query "oci_mysql_db_system_mysql_version" {
  sql = <<-EOQ
    select
      mysql_version as "MySQL Version"
    from
      oci_mysql_db_system
    where
      id = $1;
  EOQ

  param "id" {}
}

query "oci_mysql_db_system_backup" {
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

  param "id" {}
}

query "oci_mysql_db_system_overview" {
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

  param "id" {}
}

query "oci_mysql_db_system_tag" {
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

  param "id" {}
}

query "oci_mysql_db_system_backup_policy" {
  sql = <<-EOQ
    select
      backup_policy ->> 'isEnabled' as "Automatic Backup Enabled",
      backup_policy ->> 'retentionInDays' as "Backup Retention Days"
    from
      oci_mysql_db_system
    where
      id  = $1;
  EOQ

  param "id" {}
}

query "oci_mysql_db_system_endpoint" {
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

  param "id" {}
}

query "oci_mysql_db_system_connection" {
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

  param "id" {}
}
