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

    card {
      width = 2

      query = query.oci_filestorage_filesystem_cloned
      args = {
        id = self.input.filesystem_id.value
      }
    }

    card {
      query = query.oci_filestorage_filesystem_snapshot
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
        query = query.oci_filestorage_filesystem_overview
        args = {
          id = self.input.filesystem_id.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.oci_filestorage_filesystem_tag
        args = {
          id = self.input.filesystem_id.value
        }

      }
    }

    container {
      width = 6

      table {
        title = "Snapshots Details"
        query = query.oci_filestorage_filesystem_snapshot_detail
        args = {
          id = self.input.filesystem_id.value
        }
      }

      table {
        title = "Encryption"
        query = query.oci_filestorage_filesystem_encryption
        args = {
          id = self.input.filesystem_id.value
        }
      }
    }

  }
}

query "oci_filestorage_filesystem_input" {
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
      oci_file_storage_file_system as s
      left join oci_identity_compartment as c on s.compartment_id = c.id
      left join oci_identity_tenancy as t on s.tenant_id = t.id
    where
      s.lifecycle_state <> 'TERMINATED'
    order by
      s.display_name;
EOQ
}

query "oci_filestorage_filesystem_cloned" {
  sql = <<-EOQ
    select
      case when is_clone_parent then 'Cloned' else 'Not Cloned' end as "File System Type"
    from
      oci_file_storage_file_system
    where
      id = $1 and lifecycle_state <> 'DELETED';
  EOQ

  param "id" {}
}

query "oci_filestorage_filesystem_snapshot" {
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

query "oci_filestorage_filesystem_overview" {
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
}

query "oci_filestorage_filesystem_tag" {
  sql = <<-EOQ
    with jsondata as (
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
}

query "oci_filestorage_filesystem_snapshot_detail" {
  sql = <<-EOQ
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
}


query "oci_filestorage_filesystem_encryption" {
  sql = <<-EOQ
    select
      case when kms_key_id is not null then 'Customer Managed' else 'Oracle Managed' end as "Encryption Status",
      kms_key_id as "KMS Key ID"
    from
      oci_file_storage_file_system
    where
      id  = $1 and lifecycle_state <> 'DELETED';
  EOQ

  param "id" {}
}
