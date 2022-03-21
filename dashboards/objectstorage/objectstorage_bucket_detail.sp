dashboard "oci_objectstorage_bucket_detail" {

  title = "OCI Object Storage Bucket Detail"

  tags = merge(local.objectstorage_common_tags, {
    type = "Detail"
  })

  input "bucket_id" {
    title = "Select a bucket:"
    query = query.oci_objectstorage_bucket_input
    width = 4
  }

  container {

    card {
      width = 2

      query = query.oci_objectstorage_bucket_versioning
      args = {
        id = self.input.bucket_id.value
      }
    }

    card {
      query = query.oci_objectstorage_bucket_public_access
      width = 2

      args = {
        id = self.input.bucket_id.value
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
        query = query.oci_objectstorage_bucket_overview
        args = {
          id = self.input.bucket_id.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.oci_objectstorage_bucket_tag
        args = {
          id = self.input.bucket_id.value
        }

      }
    }

    container {
      width = 6

      table {
        title = "Encryption Details"
        query = query.oci_objectstorage_bucket_encryption
        args = {
          id = self.input.bucket_id.value
        }
      }

      table {
        title = "Public Access"
        query = query.oci_objectstorage_bucket_access
        args = {
          id = self.input.bucket_id.value
        }
      }

    }

    container {

      table {
        title = "Object Lifecycle Policy"
        query = query.oci_objectstorage_bucket_object_lifecycle_policy
        args = {
          id = self.input.bucket_id.value
        }
      }

    }

  }
}

query "oci_objectstorage_bucket_input" {
  sql = <<EOQ
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

query "oci_objectstorage_bucket_versioning" {
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

  param "id" {}
}

query "oci_objectstorage_bucket_public_access" {
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

  param "id" {}
}

query "oci_objectstorage_bucket_overview" {
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

  param "id" {}
}

query "oci_objectstorage_bucket_tag" {
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

  param "id" {}
}

query "oci_objectstorage_bucket_encryption" {
  sql = <<-EOQ
   select
     case when kms_key_id is not null and kms_key_id <> '' then 'Customer Managed' else 'Oracle Managed' end as "Encryption Status",
     kms_key_id as "KMS Key ID"
   from
     oci_objectstorage_bucket
   where
     id  = $1
  EOQ

  param "id" {}
}

query "oci_objectstorage_bucket_access" {
  sql = <<-EOQ
   select
    public_access_type as "Public Access Type",
    is_read_only as "Read Only"
  from
    oci_objectstorage_bucket
  where
    id = $1;
  EOQ

  param "id" {}
}

query "oci_objectstorage_bucket_object_lifecycle_policy" {
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

  param "id" {}
}
