dashboard "kms_key_detail" {

  title = "OCI KMS Key Detail"

  tags = merge(local.kms_common_tags, {
    type = "Detail"
  })

  input "key_id" {
    title = "Select a key:"
    query = query.kms_key_input
    width = 4
  }

  container {

    card {
      width = 3

      query = query.kms_key_disabled
      args = {
        id = self.input.key_id.value
      }
    }

    card {
      query = query.kms_key_protection_mode
      width = 3

      args = {
        id = self.input.key_id.value
      }
    }

  }

  with "blockstorage_block_volumes_for_kms_key" {
    query = query.blockstorage_block_volumes_for_kms_key
    args  = [self.input.key_id.value]
  }

  with "blockstorage_boot_volumes_for_kms_key" {
    query = query.blockstorage_boot_volumes_for_kms_key
    args  = [self.input.key_id.value]
  }

  with "file_storage_file_systems_for_kms_key" {
    query = query.file_storage_file_systems_for_kms_key
    args  = [self.input.key_id.value]
  }

  with "kms_key_versions_for_kms_key" {
    query = query.kms_key_versions_for_kms_key
    args  = [self.input.key_id.value]
  }

  with "kms_vaults_for_kms_key" {
    query = query.kms_vaults_for_kms_key
    args  = [self.input.key_id.value]
  }

  with "objectstorage_buckets_for_kms_key" {
    query = query.objectstorage_buckets_for_kms_key
    args  = [self.input.key_id.value]
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.blockstorage_block_volume
        args = {
          blockstorage_block_volume_ids = with.blockstorage_block_volumes_for_kms_key.rows[*].block_volume_id
        }
      }

      node {
        base = node.blockstorage_boot_volume
        args = {
          blockstorage_boot_volume_ids = with.blockstorage_boot_volumes_for_kms_key.rows[*].boot_volume_id
        }
      }

      node {
        base = node.filestorage_file_system
        args = {
          filestorage_file_system_ids = with.file_storage_file_systems_for_kms_key.rows[*].file_system_id
        }
      }

      node {
        base = node.kms_key
        args = {
          kms_key_ids = [self.input.key_id.value]
        }
      }

      node {
        base = node.kms_key_version
        args = {
          kms_key_version_ids =  with.kms_key_versions_for_kms_key.rows[*].kms_key_version_id
        }
      }

      node {
        base = node.kms_vault
        args = {
          kms_vault_ids = with.kms_vaults_for_kms_key.rows[*].vault_id
        }
      }

      node {
        base = node.objectstorage_bucket
        args = {
          objectstorage_bucket_ids = with.objectstorage_buckets_for_kms_key.rows[*].bucket_id
        }
      }

      edge {
        base = edge.blockstorage_block_volume_to_kms_key_version
        args = {
          blockstorage_block_volume_ids = with.blockstorage_block_volumes_for_kms_key.rows[*].block_volume_id
        }
      }

      edge {
        base = edge.blockstorage_boot_volume_to_kms_key_version
        args = {
          blockstorage_boot_volume_ids = with.blockstorage_boot_volumes_for_kms_key.rows[*].boot_volume_id
        }
      }

      edge {
        base = edge.filestorage_file_system_to_kms_key
        args = {
          filestorage_file_system_ids = with.file_storage_file_systems_for_kms_key.rows[*].file_system_id
        }
      }


      edge {
        base = edge.kms_key_version_to_kms_key
        args = {
          kms_key_version_ids =  with.kms_key_versions_for_kms_key.rows[*].kms_key_version_id
        }
      }

      edge {
        base = edge.kms_key_to_kms_vault
        args = {
          kms_key_ids = [self.input.key_id.value]
        }
      }

      edge {
        base = edge.objectstorage_bucket_to_kms_key
        args = {
          objectstorage_bucket_ids = with.objectstorage_buckets_for_kms_key.rows[*].bucket_id
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
        query = query.kms_key_overview
        args = {
          id = self.input.key_id.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.kms_key_tag
        args = {
          id = self.input.key_id.value
        }

      }
    }

    container {
      width = 6

      table {
        title = "Key Details"
        query = query.kms_key_detail
        args = {
          id = self.input.key_id.value
        }
      }
    }

  }
}

# Input queries

query "kms_key_input" {
  sql = <<EOQ
    select
     right(reverse(split_part(reverse(v.title), '.', 1)), 8) as label,
      k.id as value,
      json_build_object(
        'Key Name', k.name,
        'c.name', coalesce(c.title, 'root'),
        'k.region', v.region,
        't.name', t.name
      ) as tags
      from
        oci_kms_key as k
        left join oci_identity_compartment as c on k.compartment_id = c.id
        left join oci_kms_key_version as v on v.key_id = k.id
        left join oci_identity_tenancy as t on k.tenant_id = t.id
      where
        k.lifecycle_state <> 'DELETED'
        and v.management_endpoint = k.management_endpoint
        and v.region = k.region
      order by
        v.title ;
  EOQ
}

# With queries

query "blockstorage_block_volumes_for_kms_key" {
  sql = <<-EOQ
    select
      id as block_volume_id
    from
      oci_core_volume
    where
      kms_key_id = $1;
  EOQ
}

query "file_storage_file_systems_for_kms_key" {
  sql = <<-EOQ
    select
      id as file_system_id
    from
      oci_file_storage_file_system
    where
      kms_key_id = $1;
  EOQ
}

query "blockstorage_boot_volumes_for_kms_key" {
  sql = <<-EOQ
    select
      id as boot_volume_id
    from
      oci_core_boot_volume
    where
      kms_key_id = $1;
  EOQ
}

query "kms_key_versions_for_kms_key" {
  sql = <<-EOQ
    select
      v.id as kms_key_version_id
    from
      oci_kms_key_version as v
      left join oci_kms_key as k on k.id = v.key_id
    where
      v.management_endpoint = k.management_endpoint
      and v.region = k.region
      and k.id = $1;
  EOQ
}

query "kms_vaults_for_kms_key" {
  sql = <<-EOQ
    select
      vault_id
    from
      oci_kms_key
    where
      id = $1;
  EOQ
}

query "objectstorage_buckets_for_kms_key" {
  sql = <<-EOQ
    select
      id as bucket_id
    from
      oci_objectstorage_bucket
    where
      kms_key_id = $1;
  EOQ
}

# Card queries

query "kms_key_disabled" {
  sql = <<-EOQ
    select
      initcap(lifecycle_state) as value,
      'Lifecycle State' as label,
      case when lifecycle_state = 'DISABLED' then 'alert' else 'ok' end as type
    from
      oci_kms_key
    where
      id = $1;
  EOQ

  param "id" {}
}

query "kms_key_protection_mode" {
  sql = <<-EOQ
    select
      case when protection_mode = 'HSM' then 'HSM' else initcap(protection_mode) end as "Protection Mode"
    from
      oci_kms_key
    where
      id = $1;
  EOQ

  param "id" {}
}

# Other detail page queries

query "kms_key_overview" {
  sql = <<-EOQ
    select
      name as "Name",
      time_created as "Time Created",
      time_of_deletion as "Time Of Deletion",
      vault_name as "Vault Name",
      id as "OCID",
      compartment_id as "Compartment ID"
    from
      oci_kms_key
    where
      id = $1;
  EOQ

  param "id" {}
}

query "kms_key_tag" {
  sql = <<-EOQ
    with jsondata as (
    select
      tags::json as tags
    from
      oci_kms_key
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

query "kms_key_detail" {
  sql = <<-EOQ
    select
      algorithm as "Algorithm",
      curve_id as "Curve ID",
      length as "Length"
    from
      oci_kms_key
    where
      id  = $1;
  EOQ

  param "id" {}
}