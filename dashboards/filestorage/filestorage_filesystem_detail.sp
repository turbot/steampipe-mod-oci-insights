query "oci_filestorage_filesystem_input" {
  sql = <<EOQ
    select
      id as label,
      id as value
    from
      oci_file_storage_file_system
    where
      lifecycle_state <> 'DELETED'
    order by
      id;
EOQ
}

query "oci_filestorage_filesystem_name_for_filesystem" {
  sql = <<-EOQ
    select
      display_name as "File System"
    from
      oci_file_storage_file_system
    where
      id = $1 and lifecycle_state <> 'DELETED';
  EOQ

  param "id" {}
}

query "oci_filestorage_filesystem_cloned_for_filesystem" {
  sql = <<-EOQ
    select
      case when is_clone_parent then 'true' else 'false' end as "Cloned File System"
    from
      oci_file_storage_file_system
    where
      id = $1 and lifecycle_state <> 'DELETED';
  EOQ

  param "id" {}
}

query "oci_filestorage_filesystem_snapshot_for_filesystem" {
  sql = <<-EOQ
    select
      count(*) as "Snapshot"
    from
      oci_file_storage_snapshot
    where
      file_system_id = $1 and lifecycle_state <> 'DELETED';
  EOQ

  param "id" {}
}

dashboard "oci_filestorage_filesystem_detail" {
  title = "OCI File Storage File System Detail"

  input "filesystem_id" {
    title = "Select a file system:"
    sql   = query.oci_filestorage_filesystem_input.sql
    width = 4
  }

  tags = merge(local.filestorage_common_tags, {
    type     = "Report"
    category = "Detail"
  })

  container {

    # Assessments
    card {
      width = 2

      query = query.oci_filestorage_filesystem_name_for_filesystem
      args = {
        id = self.input.filesystem_id.value
      }
    }

    card {
      width = 2

      query = query.oci_filestorage_filesystem_cloned_for_filesystem
      args = {
        id = self.input.filesystem_id.value
      }
    }

    card {
      query = query.oci_filestorage_filesystem_snapshot_for_filesystem
      width = 2

      args = {
        id = self.input.filesystem_id.value
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
            id as "OCID",
            compartment_id as "Compartment ID"
          from
            oci_file_storage_file_system
          where
           id = $1 and lifecycle_state <> 'DELETED';
        EOQ

        param "id" {}

        args = {
          id = self.input.filesystem_id.value
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
              oci_file_storage_file_system
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
          id = self.input.filesystem_id.value
        }

      }
    }

    container {
      width = 6

      table {
        title = "Snapshots"
        sql   = <<-EOQ
          select
            name as "Snapshot Name",
            time_created as "Time Created",
            is_clone_source as "Clone Source"
          from
            oci_file_storage_snapshot
          where
           file_system_id  = $1 and lifecycle_state <> 'DELETED';
        EOQ

        param "id" {}

        args = {
          id = self.input.filesystem_id.value
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
            oci_file_storage_file_system
          where
           id  = $1 and lifecycle_state <> 'DELETED';
        EOQ

        param "id" {}

        args = {
          id = self.input.filesystem_id.value
        }
      }
    }

  }
}
