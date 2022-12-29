dashboard "blockstorage_boot_volume_detail" {

  title = "OCI Block Storage Boot Volume Detail"

  tags = merge(local.blockstorage_common_tags, {
    type = "Detail"
  })

  input "boot_volume_id" {
    title = "Select a boot volume:"
    query = query.blockstorage_boot_volume_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.blockstorage_boot_volume_storage
      args = [self.input.boot_volume_id.value]
    }

    card {
      width = 2
      query = query.blockstorage_boot_volume_vpu
      args = [self.input.boot_volume_id.value]
    }

  }

  with "blockstorage_boot_volume_backups" {
    query = query.blockstorage_boot_volume_blockstorage_boot_volume_backups
    args  = [self.input.boot_volume_id.value]
  }

  with "blockstorage_boot_volume_replicas" {
    query = query.blockstorage_boot_volume_blockstorage_boot_volume_replicas
    args  = [self.input.boot_volume_id.value]
  }

  with "compute_images" {
    query = query.blockstorage_boot_volume_compute_images
    args  = [self.input.boot_volume_id.value]
  }

  with "compute_instances" {
    query = query.blockstorage_boot_volume_compute_instances
    args  = [self.input.boot_volume_id.value]
  }

  with "kms_keys" {
    query = query.blockstorage_boot_volume_kms_keys
    args  = [self.input.boot_volume_id.value]
  }

  with "kms_vaults" {
    query = query.blockstorage_boot_volume_kms_vaults
    args  = [self.input.boot_volume_id.value]
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.blockstorage_boot_volume
        args = {
          blockstorage_boot_volume_ids = [self.input.boot_volume_id.value]
        }
      }

      node {
        base = node.blockstorage_boot_volume_backup
        args = {
          blockstorage_boot_volume_backup_ids = with.blockstorage_boot_volume_backups.rows[*].backup_id
        }
      }

      node {
        base = node.blockstorage_boot_volume_replica
        args = {
          blockstorage_boot_volume_replica_ids = with.blockstorage_boot_volume_replicas.rows[*].replica_id
        }
      }

      node {
        base = node.compute_image
        args = {
          compute_image_ids = with.compute_images.rows[*].image_id
        }
      }

      node {
        base = node.compute_instance
        args = {
          compute_instance_ids = with.compute_instances.rows[*].instance_id
        }
      }

      node {
        base = node.kms_key
        args = {
          kms_key_ids = with.kms_keys.rows[*].kms_key_id
        }
      }

      node {
        base = node.kms_vault
        args = {
          kms_vault_ids = with.kms_vaults.rows[*].key_vault_id
        }
      }

      edge {
        base = edge.blockstorage_boot_volume_backup_to_compute_image
        args = {
          blockstorage_boot_volume_backup_ids = with.blockstorage_boot_volume_backups.rows[*].backup_id
        }
      }

      edge {
        base = edge.blockstorage_boot_volume_to_blockstorage_boot_volume_backup
        args = {
          blockstorage_boot_volume_ids = [self.input.boot_volume_id.value]
        }
      }

      edge {
        base = edge.blockstorage_boot_volume_to_blockstorage_boot_volume_replica
        args = {
          blockstorage_boot_volume_ids = [self.input.boot_volume_id.value]
        }
      }

      edge {
        base = edge.blockstorage_boot_volume_to_kms_vault
        args = {
          blockstorage_boot_volume_ids = [self.input.boot_volume_id.value]
        }
      }

      edge {
        base = edge.compute_instance_to_blockstorage_boot_volume
        args = {
          compute_instance_ids = with.compute_instances.rows[*].instance_id
        }
      }

      edge {
        base = edge.kms_vault_to_kms_key
        args = {
          kms_vault_ids = with.kms_vaults.rows[*].key_vault_id
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
        query = query.blockstorage_boot_volume_overview
        args = [self.input.boot_volume_id.value]

      }

      table {
        title = "Tags"
        width = 6
        query = query.blockstorage_boot_volume_tags
        args = [self.input.boot_volume_id.value]

      }
    }

    container {
      width = 6

      table {
        title = "Attached To"
        query = query.blockstorage_boot_volume_attached_instances
        args = [self.input.boot_volume_id.value]

        column "Instance ID" {
          display = "none"
        }

        column "Instance Name" {
          href = "${dashboard.compute_instance_detail.url_path}?input.instance_id={{.'Instance ID' | @uri}}"
        }
      }

      table {
        title = "Encryption Details"
        query = query.blockstorage_boot_volume_encryption
        args = [self.input.boot_volume_id.value]
      }
    }

    container{

      table {
        title = "Backup Policy"
        query = query.blockstorage_boot_volume_backup_policy
        args = [self.input.boot_volume_id.value]

        column "Policy ID" {
          display = "none"
        }
      }
    }
    }

  }


# Input queries

query "blockstorage_boot_volume_input" {
  sql = <<EOQ
    select
      v.display_name as label,
      v.id as value,
      json_build_object(
        'c.name', coalesce(c.title, 'root'),
        'v.region', region,
        't.name', t.name
      ) as tags
    from
      oci_core_boot_volume as v
      left join oci_identity_compartment as c on v.compartment_id = c.id
      left join oci_identity_tenancy as t on v.tenant_id = t.id
    where
      v.lifecycle_state <> 'TERMINATED'
    order by
      v.display_name;
  EOQ
}

# With queries

query "blockstorage_boot_volume_blockstorage_boot_volume_backups" {
  sql = <<EOQ
    select
      id as backup_id
    from
      oci_core_boot_volume_backup
    where
      boot_volume_id = $1;
  EOQ
}

query "blockstorage_boot_volume_blockstorage_boot_volume_replicas" {
  sql = <<EOQ
    select
      id as replica_id
    from
      oci_core_boot_volume_replica
    where
      boot_volume_id = $1;
  EOQ
}

query "blockstorage_boot_volume_compute_images" {
  sql = <<EOQ
    select
      image_id
    from
      oci_core_boot_volume_backup
    where
      boot_volume_id = $1;
  EOQ
}

query "blockstorage_boot_volume_compute_instances" {
  sql = <<EOQ
    select
      instance_id
    from
      oci_core_boot_volume_attachment
    where
      boot_volume_id = $1;
  EOQ
}

query "blockstorage_boot_volume_kms_keys" {
  sql = <<EOQ
    select
      kms_key_id
    from
      oci_core_boot_volume
    where
      kms_key_id is not null
      and id = $1;
  EOQ
}

query "blockstorage_boot_volume_kms_vaults" {
  sql = <<EOQ
    select
      k.vault_id as key_vault_id
    from
      oci_core_boot_volume as v,
      oci_kms_key as k
    where
      k.id = v.kms_key_id
      and v.id = $1;
  EOQ
}

# Card queries

query "blockstorage_boot_volume_storage" {
  sql = <<-EOQ
    select
      size_in_gbs as "Storage (GB)"
    from
      oci_core_boot_volume
    where
      id = $1;
  EOQ
}

query "blockstorage_boot_volume_vpu" {
  sql = <<-EOQ
    select
      vpus_per_gb as "VPUs"
    from
      oci_core_boot_volume
    where
      id = $1;
  EOQ
}

# Other detail page queries

query "blockstorage_boot_volume_overview" {
  sql = <<EOQ
    select
      display_name as "Name",
      time_created as "Time Created",
      availability_domain as "Availability Domain",
      is_auto_tune_enabled as "Auto Tune Enabled",
      is_hydrated as "Hydrated",
      id as "OCID",
      compartment_id as "Compartment ID"
    from
      oci_core_boot_volume
    where
      id = $1;
  EOQ
}

query "blockstorage_boot_volume_tags" {
  sql = <<EOQ
    with jsondata as (
      select
        tags::json as tags
      from
        oci_core_boot_volume
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
}

query "blockstorage_boot_volume_attached_instances" {
  sql = <<EOQ
    select
      i.id as "Instance ID",
      i.display_name as "Instance Name",
      i.lifecycle_state as "Lifecycle State",
      a.time_created as "Attachment Time"
    from
      oci_core_boot_volume_attachment as a
      left join oci_core_instance as i on a.instance_id = i.id
    where
      a.boot_volume_id = $1 and a.lifecycle_state <> 'TERMINATED';
  EOQ
}

query "blockstorage_boot_volume_encryption" {
  sql = <<EOQ
    select
      case when kms_key_id is not null and kms_key_id <> '' then 'Customer Managed' else 'Oracle Managed' end as "Encryption Status",
      kms_key_id as "KMS Key ID"
    from
      oci_core_boot_volume
    where
      id  = $1;
  EOQ
}

query "blockstorage_boot_volume_backup_policy" {
  sql = <<EOQ
    select
      p.id as "Instance ID",
      p.display_name as "Backup Policy Name",
      p.region as "Region",
      p.time_created as "Creation Time",
      v.volume_backup_policy_assignment_id as "Backup Policy Assignment ID"
    from
      oci_core_volume_backup_policy as p,
      oci_core_boot_volume as v
    where
      p.id = v.volume_backup_policy_id
      and v.id = $1
  EOQ
}
