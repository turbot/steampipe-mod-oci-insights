dashboard "filestorage_filesystem_detail" {

  title = "OCI File Storage File System Detail"

  input "filesystem_id" {
    title = "Select a file system:"
    query = query.filestorage_filesystem_input
    width = 4
  }

  tags = merge(local.filestorage_common_tags, {
    type = "Detail"
  })

  container {

    card {
      width = 2

      query = query.filestorage_filesystem_cloned
      args  = [self.input.filesystem_id.value]
    }

    card {
      query = query.filestorage_filesystem_snapshot
      width = 2

      args = [self.input.filesystem_id.value]
    }

  }

  with "filestorage_snapshots" {
    query = query.filestorage_file_system_filestorage_snapshots
    args  = [self.input.filesystem_id.value]
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.filestorage_file_system
        args = {
          filestorage_file_system_ids = [self.input.filesystem_id.value]
        }
      }

      node {
        base = node.filestorage_snapshot
        args = {
          filestorage_snapshot_ids = with.filestorage_snapshots.rows[*].snapshot_id
        }
      }

      edge {
        base = edge.filestorage_file_system_to_filestorage_snapshot
        args = {
          filestorage_file_system_ids = [self.input.filesystem_id.value]
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
        query = query.filestorage_filesystem_overview
        args  = [self.input.filesystem_id.value]

      }

      table {
        title = "Tags"
        width = 6
        query = query.filestorage_filesystem_tag
        args  = [self.input.filesystem_id.value]

      }
    }

    container {
      width = 6

      table {
        title = "Snapshots Details"
        query = query.filestorage_filesystem_snapshot_detail
        args  = [self.input.filesystem_id.value]
      }

      table {
        title = "Encryption Details"
        query = query.filestorage_filesystem_encryption
        args  = [self.input.filesystem_id.value]
      }

      table {
        title = "Source Details"
        query = query.filestorage_filesystem_source
        args  = [self.input.filesystem_id.value]
      }
    }

  }
}

# Input queries

query "filestorage_filesystem_input" {
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
      s.lifecycle_state <> 'DELETED'
    order by
      s.display_name;
  EOQ
}

# With queries

query "filestorage_file_system_filestorage_snapshots" {
  sql = <<-EOQ
    select
      id as snapshot_id
    from
      oci_file_storage_snapshot
    where
      file_system_id  = $1 ;
  EOQ
}

# Card queries

query "filestorage_filesystem_cloned" {
  sql = <<-EOQ
    select
      case when is_clone_parent then 'Cloned' else 'Not cloned' end as "File System Type"
    from
      oci_file_storage_file_system
    where
      id = $1;
  EOQ
}

query "filestorage_filesystem_snapshot" {
  sql = <<-EOQ
    select
      count(*) as "Snapshots"
    from
      oci_file_storage_snapshot
    where
      file_system_id = $1;
  EOQ
}

# Other detail page queries

query "filestorage_filesystem_overview" {
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
      id = $1;
  EOQ
}

query "filestorage_filesystem_tag" {
  sql = <<-EOQ
    with jsondata as (
    select
      tags::json as tags
    from
      oci_file_storage_file_system
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

query "filestorage_filesystem_snapshot_detail" {
  sql = <<-EOQ
    select
      name as "Snapshot Name",
      time_created as "Time Created",
      is_clone_source as "Clone Source"
    from
      oci_file_storage_snapshot
    where
      file_system_id  = $1;
  EOQ
}

query "filestorage_filesystem_encryption" {
  sql = <<-EOQ
    select
      case when kms_key_id is not null and kms_key_id <> '' then 'Customer Managed' else 'Oracle Managed' end as "Encryption Status",
      kms_key_id as "KMS Key ID"
    from
      oci_file_storage_file_system
    where
      id  = $1;
  EOQ
}

query "filestorage_filesystem_source" {
  sql = <<-EOQ
    select
      source_details ->> 'parentFileSystemId' as "Parent File System ID",
      source_details ->> 'sourceSnapshotId' as "Source Snapshot ID"
    from
      oci_file_storage_file_system
    where
      id  = $1 ;
  EOQ
}
