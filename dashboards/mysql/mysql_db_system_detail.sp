query "oci_mysql_db_system_input" {
  sql = <<EOQ
    select
      id as label,
      id as value
    from
      oci_mysql_db_system
    where
      lifecycle_state <> 'DELETED'
    order by
      id;
EOQ
}

query "oci_mysql_db_system_name_for_db_system" {
  sql = <<-EOQ
    select
      display_name as "DB System"
    from
      oci_mysql_db_system
    where
      id = $1 and lifecycle_state <> 'DELETED';
  EOQ

  param "id" {}
}

query "oci_mysql_db_system_analytics_cluster_attached_for_db_system" {
  sql = <<-EOQ
    select
      case when is_analytics_cluster_attached then 'true' else 'false' end as "Analytics Cluster Attached"
    from
      oci_mysql_db_system
    where
      id = $1 and lifecycle_state <> 'DELETED';
  EOQ

  param "id" {}
}

query "oci_mysql_db_system_heat_wave_cluster_attached_for_db_system" {
  sql = <<-EOQ
    select
      case when is_heat_wave_cluster_attached then 'true' else 'false' end as "Heat Wave Cluster Attached"
    from
      oci_mysql_db_system
    where
      id = $1 and lifecycle_state <> 'DELETED';
  EOQ

  param "id" {}
}

query "oci_mysql_db_system_failed_for_db_system" {
  sql = <<-EOQ
    select
      lifecycle_state as value,
      'Lifecycle State' as label,
      case when lifecycle_state = 'FAILED' then 'alert' else 'ok' end as type
    from
      oci_mysql_db_system
    where
      id = $1 and lifecycle_state <> 'DELETED';
  EOQ

  param "id" {}
}

query "oci_mysql_db_system_backup_for_db_system" {
  sql = <<-EOQ
    select
      case count(s.*) when 0 then 'Enabled' else 'Disabled' end as value,
      'Backups Status' as label,
      case count(s.*) when 0 then 'ok' else 'alert' end as type
    from
      oci_mysql_db_system as s
    left join oci_mysql_backup as b on s.id = b.db_system_id
    where
      s.id = $1 and s.lifecycle_state <> 'DELETED'
    group by
      s.compartment_id,
      s.region,
      s.id
    having
      count(b.id) = 0;
  EOQ

  param "id" {}
}

dashboard "oci_mysql_db_system_detail" {
  title = "OCI MySQL DB System Detail"

  tags = merge(local.mysql_common_tags, {
    type     = "Report"
    category = "Detail"
  })

  input "db_system_id" {
    title = "Select a DB system:"
    sql   = query.oci_mysql_db_system_input.sql
    width = 4
  }

  container {

    # Assessments
    card {
      width = 2

      query = query.oci_mysql_db_system_name_for_db_system
      args = {
        id = self.input.db_system_id.value
      }
    }

    card {
      width = 2

      query = query.oci_mysql_db_system_analytics_cluster_attached_for_db_system
      args = {
        id = self.input.db_system_id.value
      }
    }

    card {
      width = 2

      query = query.oci_mysql_db_system_heat_wave_cluster_attached_for_db_system
      args = {
        id = self.input.db_system_id.value
      }
    }

    card {
      width = 2

      query = query.oci_mysql_db_system_failed_for_db_system
      args = {
        id = self.input.db_system_id.value
      }
    }

    card {
      query = query.oci_mysql_db_system_backup_for_db_system
      width = 2

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

        args = {
          id = self.input.db_system_id.value
        }

      }

      table {
        title = "Tags"
        width = 6

        sql = <<-EOQ
          WITH jsondata AS (
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

        args = {
          id = self.input.db_system_id.value
        }

      }
    }

    container {
      width = 6

      table {
        title = "Shape"
        sql   = <<-EOQ
          select
            display_name as "Name",
            time_created as "Time Created",
            shape_name as "Shape Name"
          from
            oci_mysql_db_system
          where
           id  = $1 and lifecycle_state <> 'DELETED';
        EOQ

        param "id" {}

        args = {
          id = self.input.db_system_id.value
        }
      }

      table {
        title = "Backup Policy"
        sql   = <<-EOQ
          select
            display_name as "Name",
            backup_policy ->> 'isEnabled' as "Status",
            backup_policy ->> 'retentionInDays' as "Retention In Days"
          from
            oci_mysql_db_system
          where
           id  = $1 and lifecycle_state <> 'DELETED';
        EOQ

        param "id" {}

        args = {
          id = self.input.db_system_id.value
        }
      }
    }

  }
}
