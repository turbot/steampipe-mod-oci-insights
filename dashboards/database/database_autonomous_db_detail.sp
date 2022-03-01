query "oci_database_autonomous_database_input" {
  sql = <<EOQ
    select
      id as label,
      id as value
    from
      oci_database_autonomous_database
    where
      lifecycle_state <> 'TERMINATED'
    order by
      id;
EOQ
}

query "oci_database_autonomous_database_name_for_db" {
  sql = <<-EOQ
    select
      display_name as "Autonomous Database"
    from
      oci_database_autonomous_database
    where
      id = $1 and lifecycle_state <> 'TERMINATED';
  EOQ

  param "id" {}
}

query "oci_database_autonomous_database_core_for_db" {
  sql = <<-EOQ
    select
      cpu_core_count as "OCPUs"
    from
      oci_database_autonomous_database
    where
      id = $1 and lifecycle_state <> 'TERMINATED';
  EOQ

  param "id" {}
}

query "oci_database_autonomous_database_need_attention_for_db" {
  sql = <<-EOQ
    select
      lifecycle_state as value,
      'Lifecycle State' as label,
      case when lifecycle_state = 'AVAILABLE_NEEDS_ATTENTION' then 'alert' else 'ok' end as type
    from
      oci_database_autonomous_database
    where
      id = $1 and lifecycle_state <> 'TERMINATED';
  EOQ

  param "id" {}
}

query "oci_database_autonomous_database_autoscaling_for_db" {
  sql = <<-EOQ
    select
      case when is_auto_scaling_enabled then 'ENABLED' else 'DISABLED' end as "Auto Scaling"
    from
      oci_database_autonomous_database
    where
      id = $1 and lifecycle_state <> 'TERMINATED';
  EOQ

  param "id" {}
}

query "oci_database_autonomous_database_data_guard_for_db" {
  sql = <<-EOQ
    select
      case when is_data_guard_enabled then 'ENABLED' else 'DISABLED' end as "Data Guard"
    from
      oci_database_autonomous_database
    where
      id = $1 and lifecycle_state <> 'TERMINATED';
  EOQ

  param "id" {}
}

dashboard "oci_database_autonomous_database_detail" {
  title = "OCI Autonomous Database Detail"

  tags = merge(local.database_common_tags, {
    type     = "Report"
    category = "Detail"
  })

  input "db_id" {
    title = "Select a autonomous DB:"
    sql   = query.oci_database_autonomous_database_input.sql
    width = 4
  }

  container {

    # Assessments
    card {
      width = 2

      query = query.oci_database_autonomous_database_name_for_db
      args = {
        id = self.input.db_id.value
      }
    }

    card {
      width = 2

      query = query.oci_database_autonomous_database_core_for_db
      args = {
        id = self.input.db_id.value
      }
    }

    card {
      width = 2

      query = query.oci_database_autonomous_database_need_attention_for_db
      args = {
        id = self.input.db_id.value
      }
    }

    card {
      width = 2

      query = query.oci_database_autonomous_database_autoscaling_for_db
      args = {
        id = self.input.db_id.value
      }
    }

    card {
      query = query.oci_database_autonomous_database_data_guard_for_db
      width = 2

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

        sql = <<-EOQ
          select
            display_name as "Name",
            time_created as "Time Created",
            db_name as "DB Name",
            cpu_core_count as "Cpu Core Count",
            license_model as "License Model",
            id as "OCID",
            compartment_id as "Compartment ID"
          from
            oci_database_autonomous_database
          where
           id = $1 and lifecycle_state <> 'TERMINATED';
        EOQ

        param "id" {}

        args = {
          id = self.input.db_id.value
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
              oci_database_autonomous_database
            where
              id = $1 and lifecycle_state <> 'TERMINATED'
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
          id = self.input.db_id.value
        }

      }
    }

    container {
      width = 6

      table {
        title = "Data Safe registration"
        sql   = <<-EOQ
          select
            display_name as "Name",
            db_name as "DB Name",
            data_safe_status as "Data Safe Status"
          from
            oci_database_autonomous_database
          where
           id  = $1 and lifecycle_state <> 'TERMINATED';
        EOQ

        param "id" {}

        args = {
          id = self.input.db_id.value
        }
      }

      table {
        title = "Backup Config"
        sql   = <<-EOQ
          select
            display_name as "Name",
            backup_config ->> 'manualBackupBucketName' as "Manual Backup Bucket Name",
            backup_config ->> 'manualBackupType' as "Manual Backup Type"
          from
            oci_database_autonomous_database
          where
           id  = $1 and lifecycle_state <> 'TERMINATED';
        EOQ

        param "id" {}

        args = {
          id = self.input.db_id.value
        }
      }
    }

  }
}
