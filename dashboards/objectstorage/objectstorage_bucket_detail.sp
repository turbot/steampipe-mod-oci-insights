dashboard "objectstorage_bucket_detail" {

  title = "OCI Object Storage Bucket Detail"

  tags = merge(local.objectstorage_common_tags, {
    type = "Detail"
  })

  input "bucket_id" {
    title = "Select a bucket:"
    query = query.objectstorage_bucket_input
    width = 4
  }

  container {

    card {
      width = 3

      query = query.objectstorage_bucket_read_only
      args = [self.input.bucket_id.value]
    }

    card {
      width = 3

      query = query.objectstorage_bucket_versioning
      args = [self.input.bucket_id.value]
    }

    card {
      query = query.objectstorage_bucket_public_access
      width = 3

      args = [self.input.bucket_id.value]
    }

  }

  with "identity_users_for_objectstorage_bucket" {
    query = query.identity_users_for_objectstorage_bucket
    args  = [self.input.bucket_id.value]
  }

  with "objectstorage_objects_for_objectstorage_bucket" {
    query = query.objectstorage_objects_for_objectstorage_bucket
    args  = [self.input.bucket_id.value]
  }

  with "kms_keys_for_objectstorage_bucket" {
    query = query.kms_keys_for_objectstorage_bucket
    args  = [self.input.bucket_id.value]
  }

  with "kms_vaults_for_objectstorage_bucket" {
    query = query.kms_vaults_for_objectstorage_bucket
    args  = [self.input.bucket_id.value]
  }

  container {

    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.identity_user
        args = {
          identity_user_ids = with.identity_users_for_objectstorage_bucket.rows[*].user_id
        }
      }

      node {
        base = node.objectstorage_bucket
        args = {
          objectstorage_bucket_ids = [self.input.bucket_id.value]
        }
      }

      node {
        base = node.objectstorage_object
        args = {
          objectstorage_object_ids = with.objectstorage_objects_for_objectstorage_bucket.rows[*].object_name
        }
      }

      node {
        base = node.kms_key
        args = {
          kms_key_ids = with.kms_keys_for_objectstorage_bucket.rows[*].kms_key_id
        }
      }

      node {
        base = node.kms_vault
        args = {
          kms_vault_ids = with.kms_vaults_for_objectstorage_bucket.rows[*].vault_id
        }
      }

     edge {
        base = edge.kms_key_to_kms_vault
        args = {
          kms_key_ids = with.kms_keys_for_objectstorage_bucket.rows[*].kms_key_id
        }
      }

      edge {
        base = edge.objectstorage_bucket_to_kms_key
        args = {
          objectstorage_bucket_ids = [self.input.bucket_id.value]
        }
      }

      edge {
        base = edge.objectstorage_bucket_to_identity_user
        args = {
          objectstorage_bucket_ids = [self.input.bucket_id.value]
        }
      }

      edge {
        base = edge.objectstorage_bucket_to_objectstorage_object
        args = {
          objectstorage_bucket_ids = [self.input.bucket_id.value]
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
        query = query.objectstorage_bucket_overview
        args = [self.input.bucket_id.value]

      }

      table {
        title = "Tags"
        width = 6
        query = query.objectstorage_bucket_tag
        args = [self.input.bucket_id.value]

      }
    }

    container {
      width = 6

      table {
        title = "Encryption Details"
        query = query.objectstorage_bucket_encryption
        args = [self.input.bucket_id.value]

        column "KMS Key ID" {
          href = "${dashboard.kms_key_detail.url_path}?input.key_id={{.'KMS Key ID' | @uri}}"
        }
      }

      table {
        title = "Public Access"
        query = query.objectstorage_bucket_access
        args = [self.input.bucket_id.value]
      }

    }

    container {

      table {
        title = "Object Lifecycle Policy"
        query = query.objectstorage_bucket_object_lifecycle_policy
        args = [self.input.bucket_id.value]
      }

    }

  }
}

# Input queries

query "objectstorage_bucket_input" {
  sql = <<-EOQ
    select
      b.name as label,
      b.id as value,
      json_build_object(
        'c.name', coalesce(c.title, 'root'),
        'b.region', region,
        't.name', t.name
      ) as tags
    from
      oci_objectstorage_bucket as b
      left join oci_identity_compartment as c on b.compartment_id = c.id
      left join oci_identity_tenancy as t on b.tenant_id = t.id
    order by
      b.name;
  EOQ
}

# card queries

query "objectstorage_bucket_read_only" {
  sql = <<-EOQ
    select
      case when is_read_only then 'Enabled' else 'Disabled' end as value,
      'Read Only' as label
    from
      oci_objectstorage_bucket
    where
      id = $1;
  EOQ
}

query "objectstorage_bucket_versioning" {
  sql = <<-EOQ
    select
      case when versioning = 'Disabled' then 'Disabled' else 'Enabled' end as value,
      'Versioning Status' as label,
      case when versioning = 'Disabled' then 'alert' else 'ok' end as type
    from
      oci_objectstorage_bucket
    where
      id = $1;
  EOQ
}

query "objectstorage_bucket_public_access" {
  sql = <<-EOQ
    select
      case when public_access_type <> 'NoPublicAccess' then 'Enabled' else 'Disabled' end as value,
      'Public Access' as label,
      case when public_access_type <> 'NoPublicAccess' then 'alert' else 'ok' end as type
    from
      oci_objectstorage_bucket
    where
      id = $1;
  EOQ
}

# Other detail page queries

query "objectstorage_bucket_overview" {
  sql = <<-EOQ
   select
    name as "Name",
    time_created as "Time Created",
    namespace as "Namespace",
    storage_tier as "Storage Tier",
    id as "OCID",
    compartment_id as "Compartment ID"
  from
    oci_objectstorage_bucket
  where
    id = $1;
  EOQ
}

query "objectstorage_bucket_tag" {
  sql = <<-EOQ
   with jsondata as (
   select
     tags::json as tags
   from
     oci_objectstorage_bucket
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

query "objectstorage_bucket_encryption" {
  sql = <<-EOQ
   select
     case when kms_key_id is not null and kms_key_id <> '' then 'Customer Managed' else 'Oracle Managed' end as "Encryption Status",
     kms_key_id as "KMS Key ID"
   from
     oci_objectstorage_bucket
   where
     id  = $1
  EOQ
}

query "objectstorage_bucket_access" {
  sql = <<-EOQ
   select
    public_access_type as "Public Access Type"
  from
    oci_objectstorage_bucket
  where
    id = $1;
  EOQ
}

query "objectstorage_bucket_object_lifecycle_policy" {
  sql = <<-EOQ
   select
    i ->> 'name' as "Name",
    i ->> 'isEnabled' as "Enabled",
    object_lifecycle_policy ->> 'timeCreated' as "Time Created",
    i ->> 'action' as "Action",
    i ->> 'target' as "Target",
    i ->> 'timeAmount' as "Time Amount",
    i ->> 'timeUnit' as "Time Unit"
  from
    oci_objectstorage_bucket,
    jsonb_array_elements(object_lifecycle_policy -> 'items') as i
  where
    id = $1 and jsonb_typeof(object_lifecycle_policy -> 'items') = 'array';
  EOQ
}

# With queries

query "identity_users_for_objectstorage_bucket" {
  sql = <<-EOQ
    select
      created_by as user_id
    from
      oci_objectstorage_bucket
    where
      id = $1;
  EOQ
}

query "objectstorage_objects_for_objectstorage_bucket" {
  sql = <<-EOQ
    select
      o.name as object_name
    from
      oci_objectstorage_object as o
      left join oci_objectstorage_bucket as b on b.name = o.bucket_name
    where
      b.id = $1;
  EOQ
}

query "kms_keys_for_objectstorage_bucket" {
  sql = <<-EOQ
    select
      kms_key_id as kms_key_id
    from
      oci_objectstorage_bucket
    where
      kms_key_id is not null
      and id = $1;
  EOQ
}

query "kms_vaults_for_objectstorage_bucket" {
  sql = <<-EOQ
    select
      vault_id as vault_id
    from
      oci_objectstorage_bucket as b
      left join oci_kms_key as k on k.id = b.kms_key_id
    where
      vault_id is not null
      and b.id = $1;
  EOQ
}
