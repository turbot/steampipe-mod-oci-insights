dashboard "oci_block_storage_block_volume_detail" {

  title = "OCI Block Storage Block Volume Detail"

  tags = merge(local.blockstorage_common_tags, {
    type = "Detail"
  })

  input "volume_id" {
    title = "Select a block volume:"
    query = query.oci_block_storage_block_volume_input
    width = 4
  }

  container {

    card {
      width = 2

      query = query.oci_block_storage_block_volume_storage
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
        query = query.oci_block_storage_block_volume_overview
        args = {
          id = self.input.volume_id.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.oci_block_storage_block_volume_tags
        args = {
          id = self.input.volume_id.value
        }

      }
    }

    container {
      width = 6

      table {
        title = "Attached To"
        query = query.oci_block_storage_block_volume_attached_instances
        args = {
          id = self.input.volume_id.value
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
          id = self.input.volume_id.value
        }
      }
    }

  }
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
      id = $1 and lifecycle_state <> 'TERMINATED';
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
      id = $1 and lifecycle_state <> 'TERMINATED';
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
      a.volume_id = $1 and a.lifecycle_state <> 'TERMINATED';
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
      id  = $1 and lifecycle_state <> 'TERMINATED';
  EOQ

  param "id" {}
}
