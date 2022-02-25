query "oci_block_storage_block_volume_input" {
  sql = <<EOQ
    select
      id as label,
      id as value
    from
      oci_core_volume
    where
      lifecycle_state <> 'TERMINATED'
    order by
      id;
EOQ
}

query "oci_block_storage_block_volume_name_for_volume" {
  sql = <<-EOQ
    select
      display_name as "Block Volume"
    from
      oci_core_volume
    where
      id = $1 and lifecycle_state <> 'TERMINATED';
  EOQ

  param "id" {}
}

query "oci_block_storage_block_volume_faulty_for_volume" {
  sql = <<-EOQ
    select
      lifecycle_state as value,
      'Lifecycle State' as label,
      case when lifecycle_state = 'FAULTY' then 'alert' else 'ok' end as type
    from
      oci_core_volume
    where
      id = $1 and lifecycle_state <> 'TERMINATED';
  EOQ

  param "id" {}
}

query "oci_block_storage_block_volume_backup_for_volume" {
  sql = <<-EOQ
    select
      case count(v.*) when 0 then 'Enabled' else 'Disabled' end as value,
      'Backups Status' as label,
      case count(v.*) when 0 then 'ok' else 'alert' end as type
    from
      oci_core_volume as v
    left join oci_core_volume_backup as b on v.id = b.volume_id
    where
      v.id = $1 and v.lifecycle_state <> 'TERMINATED'
    group by
      v.compartment_id,
      v.region,
      v.id
    having
      count(b.id) = 0;
  EOQ

  param "id" {}
}

dashboard "oci_block_storage_block_volume_detail" {
  title = "OCI Block Storage Block Volume Detail"

  input "volume_id" {
    title = "Select a block volume:"
    sql   = query.oci_block_storage_block_volume_input.sql
    width = 4
  }

  container {

    # Assessments
    card {
      width = 2

      query = query.oci_block_storage_block_volume_name_for_volume
      args = {
        id = self.input.volume_id.value
      }
    }

    card {
      width = 2

      query = query.oci_block_storage_block_volume_faulty_for_volume
      args = {
        id = self.input.volume_id.value
      }
    }

    card {
      query = query.oci_block_storage_block_volume_backup_for_volume
      width = 2

      args = {
        id = self.input.volume_id.value
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
            availability_domain as "Availability Domain",
            is_auto_tune_enabled as "Auto Tune Enabled",
            size_in_gbs as "Size In GBs",
            id as "OCID",
            compartment_id as "Compartment ID"
          from
            oci_core_volume
          where
           id = $1 and lifecycle_state <> 'TERMINATED';
        EOQ

        param "id" {}

        args = {
          id = self.input.volume_id.value
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
              oci_core_volume
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
          id = self.input.volume_id.value
        }

      }
    }

    container {
      width = 6

      table {
        title = "Volume Performance Units Per GB"
        sql   = <<-EOQ
          select
            display_name as "Name",
            time_created as "Time Created",
            vpus_per_gb as "VPUS Per GB"
          from
            oci_core_volume
          where
           id  = $1 and lifecycle_state <> 'TERMINATED';
        EOQ

        param "id" {}

        args = {
          id = self.input.volume_id.value
        }
      }

      table {
        title = "Encryption"
        sql   = <<-EOQ
          select
            display_name as "Name",
            time_created as "Time Created",
            case when kms_key_id is not null then 'Customer Managed' else 'Oracle Managed' end as "Encryption Status"
          from
            oci_core_volume
          where
           id  = $1 and lifecycle_state <> 'TERMINATED';
        EOQ

        param "id" {}

        args = {
          id = self.input.volume_id.value
        }
      }
    }

  }
}
