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
      width = 3

      query = query.filestorage_filesystem_cloned
      args  = [self.input.filesystem_id.value]
    }

    card {
      query = query.filestorage_filesystem_snapshot
      width = 3

      args = [self.input.filesystem_id.value]
    }

  }

  with "filestorage_mount_targets_for_filestorage_file_system" {
    query = query.filestorage_mount_targets_for_filestorage_file_system
    args  = [self.input.filesystem_id.value]
  }

  with "filestorage_snapshots_for_filestorage_file_system" {
    query = query.filestorage_snapshots_for_filestorage_file_system
    args  = [self.input.filesystem_id.value]
  }

  with "kms_keys_for_filestorage_file_system" {
    query = query.kms_keys_for_filestorage_file_system
    args  = [self.input.filesystem_id.value]
  }

  with "kms_vaults_for_filestorage_file_system" {
    query = query.kms_vaults_for_filestorage_file_system
    args  = [self.input.filesystem_id.value]
  }

  with "vcn_network_security_groups_for_filestorage_file_system" {
    query = query.vcn_network_security_groups_for_filestorage_file_system
    args  = [self.input.filesystem_id.value]
  }

  with "vcn_subnets_for_filestorage_file_system" {
    query = query.vcn_subnets_for_filestorage_file_system
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
        base = node.filestorage_mount_target
        args = {
          filestorage_mount_target_ids = with.filestorage_mount_targets_for_filestorage_file_system.rows[*].mount_target_id
        }
      }

      node {
        base = node.filestorage_snapshot
        args = {
          filestorage_snapshot_ids = with.filestorage_snapshots_for_filestorage_file_system.rows[*].snapshot_id
        }
      }

      node {
        base = node.kms_key
        args = {
          kms_key_ids = with.kms_keys_for_filestorage_file_system.rows[*].kms_key_id
        }
      }

      node {
        base = node.kms_vault
        args = {
          kms_vault_ids = with.kms_vaults_for_filestorage_file_system.rows[*].vault_id
        }
      }


      node {
        base = node.vcn_network_security_group
        args = {
          vcn_network_security_group_ids = with.vcn_network_security_groups_for_filestorage_file_system.rows[*].security_group_id
        }
      }

      node {
        base = node.vcn_subnet
        args = {
          vcn_subnet_ids = with.vcn_subnets_for_filestorage_file_system.rows[*].subnet_id
        }
      }

      edge {
        base = edge.filestorage_file_system_to_filestorage_mount_target
        args = {
          filestorage_file_system_ids = [self.input.filesystem_id.value]
        }
      }

      edge {
        base = edge.filestorage_file_system_to_filestorage_snapshot
        args = {
          filestorage_file_system_ids = [self.input.filesystem_id.value]
        }
      }

      edge {
        base = edge.filestorage_file_system_to_kms_key
        args = {
          filestorage_file_system_ids = [self.input.filesystem_id.value]
        }
      }

      edge {
        base = edge.filestorage_mount_target_to_vcn_network_security_group
        args = {
          filestorage_mount_target_ids = with.filestorage_mount_targets_for_filestorage_file_system.rows[*].mount_target_id
        }
      }

      edge {
        base = edge.filestorage_mount_target_to_vcn_subnet
        args = {
          filestorage_mount_target_ids = with.filestorage_mount_targets_for_filestorage_file_system.rows[*].mount_target_id
        }
      }

      edge {
        base = edge.kms_key_to_kms_vault
        args = {
          kms_key_ids = with.kms_keys_for_filestorage_file_system.rows[*].kms_key_id
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

        column "Key Name" {
          href = "${dashboard.kms_key_detail.url_path}?input.key_id={{.'KMS Key ID' | @uri}}"
        }
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
  sql = <<-EOQ
    select
      f.display_name as label,
      f.id as value,
      json_build_object(
        'f.id', right(reverse(split_part(reverse(f.id), '.', 1)), 8),
        'f.region', region,
        'oic.name', coalesce(oic.title, 'root'),
        't.name', t.name
      ) as tags
    from
      oci_file_storage_file_system as f
      left join oci_identity_compartment as oic on f.compartment_id = oic.id
      left join oci_identity_tenancy as t on f.tenant_id = t.id
    where
      f.lifecycle_state <> 'DELETED'
    order by
      f.display_name;
  EOQ
}

# With queries

query "filestorage_mount_targets_for_filestorage_file_system" {
  sql = <<-EOQ
    with export_ids as (
      select
        jsonb_array_elements(exports)->> 'exportSetId' as export_set_id
      from
        oci_file_storage_file_system
      where
        id = $1
    )
    select
      m.id as mount_target_id
    from
      export_ids as e,
      oci_file_storage_mount_target as m
    where
      e.export_set_id = m.export_set_id;
  EOQ
}

query "filestorage_snapshots_for_filestorage_file_system" {
  sql = <<-EOQ
    select
      id as snapshot_id
    from
      oci_file_storage_snapshot
    where
      file_system_id  = $1 ;
  EOQ
}

query "kms_keys_for_filestorage_file_system" {
  sql = <<-EOQ
    select
      kms_key_id as kms_key_id
    from
      oci_file_storage_file_system
    where
      kms_key_id is not null
      and id  = $1;
  EOQ
}

query "kms_vaults_for_filestorage_file_system" {
  sql = <<-EOQ
    select
      vault_id as vault_id
    from
      oci_file_storage_file_system as f
      left join oci_kms_key as k on k.id = f.kms_key_id
    where
      vault_id is not null
      and f.id  = $1;
  EOQ
}

query "vcn_network_security_groups_for_filestorage_file_system" {
  sql = <<-EOQ
    with file_system_export_ids as (
      select
        jsonb_array_elements(exports)->> 'exportSetId' as export_set_id
      from
        oci_file_storage_file_system
      where
        id = $1
    )
    select
      nid as security_group_id
    from
      file_system_export_ids as e,
      oci_file_storage_mount_target as m,
      jsonb_array_elements_text(nsg_ids) as nid
    where
      e.export_set_id = m.export_set_id;
  EOQ
}

query "vcn_subnets_for_filestorage_file_system" {
  sql = <<-EOQ
    with file_system_export_ids as (
      select
        jsonb_array_elements(exports)->> 'exportSetId' as export_set_id
      from
        oci_file_storage_file_system
      where
        id = $1
    )
    select
      subnet_id
    from
      file_system_export_ids as e,
      oci_file_storage_mount_target as m
    where
      e.export_set_id = m.export_set_id;
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
      k.name as "Key Name",
      case when kms_key_id is not null and kms_key_id <> '' then 'Customer Managed' else 'Oracle Managed' end as "Encryption Status",
      kms_key_id as "KMS Key ID"
    from
      oci_file_storage_file_system as s
      left join oci_kms_key as k
      on s.kms_key_id = k.id
    where
      s.id  = $1;
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
