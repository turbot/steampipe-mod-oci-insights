query "oci_objectstorage_bucket_input" {
  sql = <<EOQ
    select
      id as label,
      id as value
    from
      oci_objectstorage_bucket
    order by
      id;
EOQ
}

query "oci_objectstorage_bucket_name_for_bucket" {
  sql = <<-EOQ
    select
      name as "Bucket"
    from
      oci_objectstorage_bucket
    where
      id = $1;
  EOQ

  param "id" {}
}

query "oci_objectstorage_bucket_versioning_for_bucket" {
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

query "oci_objectstorage_bucket_public_access_for_bucket" {
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

dashboard "oci_objectstorage_bucket_detail" {
  title = "OCI Object Storage Bucket Detail"

  tags = merge(local.objectstorage_common_tags, {
    type     = "Report"
    category = "Detail"
  })

  input "bucket_id" {
    title = "Select a bucket:"
    sql   = query.oci_objectstorage_bucket_input.sql
    width = 4
  }

  container {

    # Assessments
    card {
      width = 3

      query = query.oci_objectstorage_bucket_name_for_bucket
      args = {
        id = self.input.bucket_id.value
      }
    }

    card {
      width = 2

      query = query.oci_objectstorage_bucket_versioning_for_bucket
      args = {
        id = self.input.bucket_id.value
      }
    }

    card {
      query = query.oci_objectstorage_bucket_public_access_for_bucket
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

        sql = <<-EOQ
          select
            name as "Name",
            time_created as "Time Created",
            public_access_type as "Public Access Type",
            versioning as "Versioning",
            id as "OCID",
            compartment_id as "Compartment ID"
          from
            oci_objectstorage_bucket
          where
           id = $1;
        EOQ

        param "id" {}

        args = {
          id = self.input.bucket_id.value
        }

      }

      table {
        title = "Tags"
        width = 6

        sql = <<-EOQ
          WITH jsondata AS (
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

        args = {
          id = self.input.bucket_id.value
        }

      }
    }

    container {
      width = 6

      table {
        title = "Storage Tier"
        sql   = <<-EOQ
          select
            name as "Name",
            time_created as "Time Created",
            storage_tier as "Storage Tier"
          from
            oci_objectstorage_bucket
          where
           id  = $1;
        EOQ

        param "id" {}

        args = {
          id = self.input.bucket_id.value
        }
      }

      table {
        title = "Encryption"
        sql   = <<-EOQ
          select
            name as "Name",
            time_created as "Time Created",
            case when kms_key_id is not null then 'Customer Managed' else 'Oracle Managed' end as "Encryption Status"
          from
            oci_objectstorage_bucket
          where
           id  = $1
        EOQ

        param "id" {}

        args = {
          id = self.input.bucket_id.value
        }
      }
    }

  }
}
