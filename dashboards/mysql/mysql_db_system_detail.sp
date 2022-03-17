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

      query = query.oci_mysql_db_system_analytics_cluster_attached
      args = {
        id = self.input.db_system_id.value
      }
    }

    card {
      width = 2

      query = query.oci_mysql_db_system_heat_wave_cluster_attached
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

query "oci_mysql_db_system_analytics_cluster_attached" {
  sql = <<-EOQ
    select
      case when is_analytics_cluster_attached then 'Attached' else 'Unattached' end as "Analytics Cluster"
    from
      oci_mysql_db_system
    where
      id = $1 and lifecycle_state <> 'DELETED';
  EOQ

  param "id" {}
}

query "oci_mysql_db_system_heat_wave_cluster_attached" {
  sql = <<-EOQ
    select
      case when is_heat_wave_cluster_attached then 'Attached' else 'Unattached' end as "Heat Wave Cluster"
    from
      oci_mysql_db_system
    where
      id = $1 and lifecycle_state <> 'DELETED';
  EOQ

  param "id" {}
}

query "oci_mysql_db_system_overview" {
  sql = <<-EOQ
    select
      display_name as "Name",
      time_created as "Time Created",
      mysql_version as "MySQL Version",
      port as "Port",
      id as "OCID",
      compartment_id as "Compartment ID"
    from
      oci_mysql_db_system
    where
      id = $1 and lifecycle_state <> 'DELETED';
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
      id = $1 and lifecycle_state <> 'DELETED'
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
      id  = $1 and lifecycle_state <> 'DELETED';
  EOQ

  param "id" {}
}

