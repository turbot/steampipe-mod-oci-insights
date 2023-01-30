dashboard "blockstorage_block_volume_detail" {

  title = "OCI Block Storage Block Volume Detail"

  tags = merge(local.blockstorage_common_tags, {
    type = "Detail"
  })

  input "block_volume_id" {
    title = "Select a block volume:"
    query = query.blockstorage_block_volume_input
    width = 4
  }

  container {

    card {
      width = 3

      query = query.blockstorage_block_volume_storage
      args  = [self.input.block_volume_id.value]
    }

    card {
      width = 3

      query = query.blockstorage_block_volume_vpu
      args  = [self.input.block_volume_id.value]
    }

  }

  with "blockstorage_block_volume_backup_policies_for_blockstorage_block_volume" {
    query = query.blockstorage_block_volume_backup_policies_for_blockstorage_block_volume
    args  = [self.input.block_volume_id.value]
  }

  with "blockstorage_block_volume_backups_for_blockstorage_block_volume" {
    query = query.blockstorage_block_volume_backups_for_blockstorage_block_volume
    args  = [self.input.block_volume_id.value]
  }

  with "blockstorage_block_volume_default_backup_policies_for_blockstorage_block_volume" {
    query = query.blockstorage_block_volume_default_backup_policies_for_blockstorage_block_volume
    args  = [self.input.block_volume_id.value]
  }

  with "blockstorage_block_volume_replicas_for_blockstorage_block_volume" {
    query = query.blockstorage_block_volume_replicas_for_blockstorage_block_volume
    args  = [self.input.block_volume_id.value]
  }

  with "compute_instances_for_blockstorage_block_volume" {
    query = query.compute_instances_for_blockstorage_block_volume
    args  = [self.input.block_volume_id.value]
  }

  with "kms_keys_for_blockstorage_block_volume" {
    query = query.kms_keys_for_blockstorage_block_volume
    args  = [self.input.block_volume_id.value]
  }

  with "kms_vaults_for_blockstorage_block_volume" {
    query = query.kms_vaults_for_blockstorage_block_volume
    args  = [self.input.block_volume_id.value]
  }

  with "source_blockstorage_block_volume_clones_for_blockstorage_block_volume" {
    query = query.source_blockstorage_block_volume_clones_for_blockstorage_block_volume
    args  = [self.input.block_volume_id.value]
  }

  with "target_blockstorage_block_volume_clones_for_blockstorage_block_volume" {
    query = query.target_blockstorage_block_volume_clones_for_blockstorage_block_volume
    args  = [self.input.block_volume_id.value]
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.blockstorage_block_volume
        args = {
          blockstorage_block_volume_ids = [self.input.block_volume_id.value]
        }
      }

      node {
        base = node.blockstorage_block_volume
        args = {
          blockstorage_block_volume_ids = with.target_blockstorage_block_volume_clones_for_blockstorage_block_volume.rows[*].volume_id
        }
      }

      node {
        base = node.blockstorage_block_volume
        args = {
          blockstorage_block_volume_ids = with.source_blockstorage_block_volume_clones_for_blockstorage_block_volume.rows[*].volume_id
        }
      }

      node {
        base = node.blockstorage_block_volume_backup
        args = {
          blockstorage_block_volume_backup_ids = with.blockstorage_block_volume_backups_for_blockstorage_block_volume.rows[*].backup_id
        }
      }

      node {
        base = node.blockstorage_block_volume_backup_policy
        args = {
          blockstorage_block_volume_backup_policy_ids = with.blockstorage_block_volume_backup_policies_for_blockstorage_block_volume.rows[*].backup_policy_id
        }
      }

      node {
        base = node.blockstorage_block_volume_default_backup_policy
        args = {
          blockstorage_block_volume_default_backup_policy_ids = with.blockstorage_block_volume_default_backup_policies_for_blockstorage_block_volume.rows[*].backup_policy_id
        }
      }

      node {
        base = node.blockstorage_block_volume_replica
        args = {
          blockstorage_block_volume_replica_ids = with.blockstorage_block_volume_replicas_for_blockstorage_block_volume.rows[*].replica_volume_id
        }
      }

      node {
        base = node.compute_instance
        args = {
          compute_instance_ids = with.compute_instances_for_blockstorage_block_volume.rows[*].instance_id
        }
      }

      node {
        base = node.kms_key
        args = {
          kms_key_ids = with.kms_keys_for_blockstorage_block_volume.rows[*].kms_key_id
        }
      }

      node {
        base = node.kms_vault
        args = {
          kms_vault_ids = with.kms_vaults_for_blockstorage_block_volume.rows[*].key_vault_id
        }
      }

      edge {
        base = edge.blockstorage_block_volume_backup_policy_to_blockstorage_block_volume_backup
        args = {
          blockstorage_block_volume_backup_policy_ids = with.blockstorage_block_volume_backup_policies_for_blockstorage_block_volume.rows[*].backup_policy_id
        }
      }

      edge {
        base = edge.blockstorage_block_volume_default_backup_policy_to_blockstorage_block_volume_backup
        args = {
          blockstorage_block_volume_default_backup_policy_ids = with.blockstorage_block_volume_default_backup_policies_for_blockstorage_block_volume.rows[*].backup_policy_id
        }
      }

      edge {
        base = edge.blockstorage_block_volume_to_blockstorage_block_volume_backup
        args = {
          blockstorage_block_volume_ids = [self.input.block_volume_id.value]
        }
      }

      edge {
        base = edge.blockstorage_block_volume_to_blockstorage_block_volume_backup_policy
        args = {
          blockstorage_block_volume_ids = [self.input.block_volume_id.value]
        }
      }

      edge {
        base = edge.blockstorage_block_volume_to_blockstorage_block_volume_clone
        args = {
          blockstorage_block_volume_ids = [self.input.block_volume_id.value]
        }
      }

      edge {
        base = edge.blockstorage_block_volume_to_blockstorage_block_volume_clone
        args = {
          blockstorage_block_volume_ids = with.target_blockstorage_block_volume_clones_for_blockstorage_block_volume.rows[*].volume_id
        }
      }

      edge {
        base = edge.blockstorage_block_volume_to_blockstorage_block_volume_default_backup_policy
        args = {
          blockstorage_block_volume_ids = [self.input.block_volume_id.value]
        }
      }

      edge {
        base = edge.blockstorage_block_volume_to_blockstorage_block_volume_replica
        args = {
          blockstorage_block_volume_ids = [self.input.block_volume_id.value]
        }
      }

      edge {
        base = edge.blockstorage_block_volume_to_kms_vault
        args = {
          blockstorage_block_volume_ids = [self.input.block_volume_id.value]
        }
      }

      edge {
        base = edge.compute_instance_to_blockstorage_block_volume
        args = {
          compute_instance_ids = with.compute_instances_for_blockstorage_block_volume.rows[*].instance_id
        }
      }

      edge {
        base = edge.kms_vault_to_kms_key
        args = {
          kms_vault_ids = with.kms_vaults_for_blockstorage_block_volume.rows[*].key_vault_id
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
        query = query.blockstorage_block_volume_overview
        args  = [self.input.block_volume_id.value]

      }

      table {
        title = "Tags"
        width = 6
        query = query.blockstorage_block_volume_tags
        args  = [self.input.block_volume_id.value]

      }
    }

    container {
      width = 6

      table {
        title = "Attached To"
        query = query.blockstorage_block_volume_attached_instances
        args  = [self.input.block_volume_id.value]

        column "Instance ID" {
          display = "none"
        }

        column "Instance Name" {
          href = "${dashboard.compute_instance_detail.url_path}?input.instance_id={{.'Instance ID' | @uri}}"
        }
      }

      table {
        title = "Encryption Details"
        query = query.blockstorage_block_volume_encryption
        args  = [self.input.block_volume_id.value]

        column "Key Name" {
          href = "${dashboard.kms_key_detail.url_path}?input.key_id={{.'KMS Key ID' | @uri}}"
        }
      }

      table {
        title = "Backup Policy Schedules"
        query = query.blockstorage_block_volume_backup_policy_schedules
        args  = [self.input.block_volume_id.value]
      }
    }

  }
}

# Input queries

query "blockstorage_block_volume_input" {
  sql = <<EOQ
    select
      b.display_name as label,
      b.id as value,
      json_build_object(
        'b.id', concat('id: ', right(reverse(split_part(reverse(b.id), '.', 1)), 8)),
        'b.region', concat('region: ', region),
        'c.name', concat('compartment: ', coalesce(c.title, 'root')),
        't.name', concat('tenant: ', t.name)
      ) as tags
    from
      oci_core_volume as b
      left join oci_identity_compartment as c on b.compartment_id = c.id
      left join oci_identity_tenancy as t on b.compartment_id = t.id
    where
      b.lifecycle_state <> 'TERMINATED'
    order by
      b.display_name;
  EOQ
}

# With queries

query "blockstorage_block_volume_backup_policies_for_blockstorage_block_volume" {
  sql = <<EOQ
    select
      p.id as backup_policy_id
    from
      oci_core_volume as v,
      oci_core_volume_backup_policy as p
    where
      v.volume_backup_policy_id = p.id
      and v.id  = $1;
  EOQ
}

query "blockstorage_block_volume_backups_for_blockstorage_block_volume" {
  sql = <<EOQ
    select
      id as backup_id
    from
      oci_core_volume_backup
    where
      volume_id  = $1;
  EOQ
}

query "blockstorage_block_volume_default_backup_policies_for_blockstorage_block_volume" {
  sql = <<EOQ
    select
      p.id as backup_policy_id
    from
      oci_core_volume as v,
      oci_core_volume_default_backup_policy as p
    where
      v.volume_backup_policy_id = p.id
      and v.id  = $1;
  EOQ
}

query "blockstorage_block_volume_replicas_for_blockstorage_block_volume" {
  sql = <<EOQ
    select
      id as replica_volume_id
    from
      oci_core_block_volume_replica
    where
      block_volume_id  = $1;
  EOQ
}

query "compute_instances_for_blockstorage_block_volume" {
  sql = <<EOQ
    select
      instance_id
    from
      oci_core_volume_attachment
    where
      instance_id is not null
      and volume_id  = $1;
  EOQ
}

query "kms_keys_for_blockstorage_block_volume" {
  sql = <<EOQ
    select
      kms_key_id
    from
      oci_core_volume
    where
      kms_key_id is not null
      and id  = $1;
  EOQ
}

query "kms_vaults_for_blockstorage_block_volume" {
  sql = <<EOQ
    select
      k.vault_id as key_vault_id
    from
      oci_core_volume as v,
      oci_kms_key as k
    where
      k.id = v.kms_key_id
      and v.id  = $1;
  EOQ
}

query "source_blockstorage_block_volume_clones_for_blockstorage_block_volume" {
  sql = <<EOQ
    select
      source_details ->> 'id' as volume_id
    from
      oci_core_volume as v
    where
      source_details is not null
      and id = $1;
  EOQ
}

query "target_blockstorage_block_volume_clones_for_blockstorage_block_volume" {
  sql = <<EOQ
    select
      id as volume_id
    from
      oci_core_volume as v
    where
      source_details ->> 'id' = $1;
  EOQ
}

# Card queries

query "blockstorage_block_volume_storage" {
  sql = <<-EOQ
    select
      size_in_gbs as "Storage (GB)"
    from
      oci_core_volume
    where
      id = $1;
  EOQ
}

query "blockstorage_block_volume_vpu" {
  sql = <<-EOQ
    select
      vpus_per_gb as "VPUs"
    from
      oci_core_volume
    where
      id = $1;
  EOQ
}

# Other detail page queries

query "blockstorage_block_volume_overview" {
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
      oci_core_volume
    where
      id = $1;
  EOQ
}

query "blockstorage_block_volume_tags" {
  sql = <<EOQ
    with jsondata as (
      select
        tags::json as tags
      from
        oci_core_volume
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

query "blockstorage_block_volume_attached_instances" {
  sql = <<EOQ
    select
      i.id as "Instance ID",
      i.display_name as "Instance Name",
      i.lifecycle_state as "Lifecycle State",
      a.time_created as "Attachment Time"
    from
      oci_core_volume_attachment as a
      left join oci_core_instance as i on a.instance_id = i.id
    where
      a.volume_id = $1;
  EOQ
}

query "blockstorage_block_volume_encryption" {
  sql = <<EOQ
    select
      k.name as "Key Name",
      case when kms_key_id is not null and kms_key_id <> '' then 'Customer Managed' else 'Oracle Managed' end as "Encryption Status",
      kms_key_id as "KMS Key ID"
    from
      oci_core_volume as v
      left join oci_kms_key as k
      on v.kms_key_id = k.id
    where
      v.id  = $1;
  EOQ
}

query "blockstorage_block_volume_backup_policy_schedules" {
  sql = <<EOQ
    select
      s ->> 'period' as "Period",
      s ->> 'timeZone' as "Time Zone",
      s ->> 'hourOfDay' as "Hour Of Day",
      s ->> 'backupType' as "Backup Type",
      s ->> 'dayOfMonth' as "Day Of Month",
      s ->> 'offsetType' as "Offset Type",
      s ->> 'offsetSeconds' as "Offset Seconds",
      s ->> 'retentionSeconds' as "Retention Seconds"
    from
      oci_core_volume as v,
      oci_core_volume_backup_policy as p,
      jsonb_array_elements(schedules) as s
    where
      p.id = v.volume_backup_policy_id
      and v.id = $1
    union
      select
      s ->> 'period' as "Period",
      s ->> 'timeZone' as "Time Zone",
      s ->> 'hourOfDay' as "Hour Of Day",
      s ->> 'backupType' as "Backup Type",
      s ->> 'dayOfMonth' as "Day Of Month",
      s ->> 'offsetType' as "Offset Type",
      s ->> 'offsetSeconds' as "Offset Seconds",
      s ->> 'retentionSeconds' as "Retention Seconds"
    from
      oci_core_volume as v,
      oci_core_volume_default_backup_policy as p,
      jsonb_array_elements(schedules) as s
    where
      p.id = v.volume_backup_policy_id
      and v.id = $1;
  EOQ
}
