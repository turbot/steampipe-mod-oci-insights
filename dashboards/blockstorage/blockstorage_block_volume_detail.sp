dashboard "oci_block_storage_block_volume_detail" {

  title = "OCI Block Storage Block Volume Detail"

  tags = merge(local.blockstorage_common_tags, {
    type = "Detail"
  })

  input "block_volume_id" {
    title = "Select a block volume:"
    query = query.oci_block_storage_block_volume_input
    width = 4
  }

  container {

    card {
      width = 2

      query = query.oci_block_storage_block_volume_storage
      args = {
        id = self.input.block_volume_id.value
      }
    }

    card {
      width = 2

      query = query.oci_block_storage_block_volume_vpu
      args = {
        id = self.input.block_volume_id.value
      }
    }

  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      nodes = [
        node.oci_block_storage_block_volume_node,
        node.oci_block_storage_block_volume_to_compute_instance_node,
        node.oci_block_storage_block_volume_to_kms_key_node,
        node.oci_block_storage_block_volume_to_block_volume_backup_node,
        node.oci_block_storage_block_volume_to_block_volume_replica_node
      ]

      edges = [
        edge.oci_block_storage_block_volume_to_compute_instance_edge,
        edge.oci_block_storage_block_volume_to_kms_key_edge,
        edge.oci_block_storage_block_volume_to_block_volume_backup_edge,
        edge.oci_block_storage_block_volume_to_block_volume_replica_edge
      ]

      args = {
        id = self.input.block_volume_id.value
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
        query = query.oci_block_storage_block_volume_overview
        args = {
          id = self.input.block_volume_id.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.oci_block_storage_block_volume_tags
        args = {
          id = self.input.block_volume_id.value
        }

      }
    }

    container {
      width = 6

      table {
        title = "Attached To"
        query = query.oci_block_storage_block_volume_attached_instances
        args = {
          id = self.input.block_volume_id.value
        }

        column "Instance ID" {
          display = "none"
        }

        column "Instance Name" {
          href = "${dashboard.oci_compute_instance_detail.url_path}?input.instance_id={{.'Instance ID' | @uri}}"
        }
      }

      table {
        title = "Encryption Details"
        query = query.oci_block_storage_block_volume_encryption
        args = {
          id = self.input.block_volume_id.value
        }
      }
    }

  }
}

node "oci_block_storage_block_volume_node" {
  category = category.oci_block_storage_block_volume

  sql = <<-EOQ
    select
      id as id,
      title as title,
      jsonb_build_object(
        'Lifecycle State', lifecycle_state,
        'Region', region,
        'Compartment ID', compartment_id,
        'Tenant ID', tenant_id
      ) as properties
    from
        oci_core_volume
    where
      id = $1;
  EOQ

  param "id" {}
}

node "oci_block_storage_block_volume_to_compute_instance_node" {
  category = category.oci_compute_instance

  sql = <<-EOQ
    select
      i.id as id,
      i.title as title,
      jsonb_build_object(
        'ID', i.id,
        'Lifecycle State', i.lifecycle_state,
        'Region', i.region,
        'Compartment ID', i.compartment_id,
        'Tenant ID', i.tenant_id
      ) as properties
    from
      oci_core_volume_attachment as a
      left join oci_core_instance as i on a.instance_id = i.id
    where
      a.volume_id = $1;
  EOQ

  param "id" {}
}

edge "oci_block_storage_block_volume_to_compute_instance_edge" {
  title = "attached to"

  sql = <<-EOQ
    select
      a.volume_id as from_id,
      i.id as to_id
    from
        oci_core_volume_attachment as a
      left join oci_core_instance as i on a.instance_id = i.id
    where
      a.volume_id = $1;
  EOQ

  param "id" {}
}

node "oci_block_storage_block_volume_to_kms_key_node" {
  category = category.oci_kms_key

  sql = <<-EOQ
    select
      k.id as id,
      k.title as title,
      jsonb_build_object(
        'ID', k.id,
        'Lifecycle State', k.lifecycle_state,
        'Region', k.region,
        'Compartment ID', k.compartment_id,
        'Tenant ID', k.tenant_id
      ) as properties
    from
      oci_kms_key as k
      left join oci_core_volume as v on v.kms_key_id = k.id
    where
      v.id = $1;
  EOQ

  param "id" {}
}

edge "oci_block_storage_block_volume_to_kms_key_edge" {
  title = "encrypted with"

  sql = <<-EOQ
    select
      v.id as from_id,
      k.id as to_id
    from
      oci_kms_key as k
      left join oci_core_volume as v on v.kms_key_id = k.id
    where
      v.id = $1;
  EOQ

  param "id" {}
}

node "oci_block_storage_block_volume_to_block_volume_backup_node" {
  category = category.oci_block_storage_block_volume_backup

  sql = <<-EOQ
    select
      b.id as id,
      b.title as title,
      jsonb_build_object(
        'ID', b.id,
        'Lifecycle State', b.lifecycle_state,
        'Region', b.region,
        'Compartment ID', b.compartment_id,
        'Tenant ID', b.tenant_id
      ) as properties
    from
      oci_core_volume_backup as b
      left join oci_core_volume as v on v.id = b.volume_id
    where
      v.id = $1;
  EOQ

  param "id" {}
}

edge "oci_block_storage_block_volume_to_block_volume_backup_edge" {
  title = "backup"

  sql = <<-EOQ
    select
      v.id as from_id,
      b.id as to_id
    from
      oci_core_volume_backup as b
      left join oci_core_volume as v on v.id = b.volume_id
    where
      v.id = $1;
  EOQ

  param "id" {}
}

node "oci_block_storage_block_volume_to_block_volume_replica_node" {
  category = category.oci_block_storage_block_volume_replica

  sql = <<-EOQ
    select
      r.id as id,
      r.title as title,
      jsonb_build_object(
        'ID', r.id,
        'Lifecycle State', r.lifecycle_state,
        'Region', r.region,
        'Compartment ID', r.compartment_id,
        'Tenant ID', r.tenant_id
      ) as properties
    from
      oci_core_block_volume_replica as r
      left join oci_core_volume as v on v.id = r.block_volume_id
    where
      v.id = $1;
  EOQ

  param "id" {}
}

edge "oci_block_storage_block_volume_to_block_volume_replica_edge" {
  title = "replica"

  sql = <<-EOQ
    select
      v.id as from_id,
      r.id as to_id
    from
      oci_core_block_volume_replica as r
      left join oci_core_volume as v on v.id = r.block_volume_id
    where
      v.id = $1;
  EOQ

  param "id" {}
}

query "oci_block_storage_block_volume_input" {
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
      oci_core_volume as v
      left join oci_identity_compartment as c on v.compartment_id = c.id
      left join oci_identity_tenancy as t on v.tenant_id = t.id
    where
      v.lifecycle_state <> 'TERMINATED'
    order by
      v.display_name;
  EOQ
}

query "oci_block_storage_block_volume_storage" {
  sql = <<-EOQ
    select
      size_in_gbs as "Storage (GB)"
    from
      oci_core_volume
    where
      id = $1;
  EOQ

  param "id" {}
}

query "oci_block_storage_block_volume_vpu" {
  sql = <<-EOQ
    select
      vpus_per_gb as "VPUs"
    from
      oci_core_volume
    where
      id = $1;
  EOQ

  param "id" {}
}

query "oci_block_storage_block_volume_overview" {
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

  param "id" {}
}

query "oci_block_storage_block_volume_tags" {
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

  param "id" {}
}

query "oci_block_storage_block_volume_attached_instances" {
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

  param "id" {}
}

query "oci_block_storage_block_volume_encryption" {
  sql = <<EOQ
    select
      case when kms_key_id is not null and kms_key_id <> '' then 'Customer Managed' else 'Oracle Managed' end as "Encryption Status",
      kms_key_id as "KMS Key ID"
    from
      oci_core_volume
    where
      id  = $1;
  EOQ

  param "id" {}
}
