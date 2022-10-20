category "oci_block_storage_block_volume" {
  href = "/oci_insights.dashboard.oci_block_storage_block_volume_detail?input.block_volume_id={{.properties.'ID' | @uri}}"
  # icon = local.aws_ec2_classic_load_balancer_icon
  fold {
    title = "Block Storage Block Volumes"
    #icon      = local.aws_ec2_classic_load_balancer_icon
    threshold = 3
  }
}

category "oci_block_storage_block_volume_backup" {
  # icon = local.aws_ec2_classic_load_balancer_icon
  fold {
    title = "Block Storage Block Volume Backups"
    #icon      = local.aws_ec2_classic_load_balancer_icon
    threshold = 3
  }
}

category "oci_block_storage_block_volume_replica" {
  # icon = local.aws_ec2_classic_load_balancer_icon
  fold {
    title = "Block Storage Block Volume Replicas"
    #icon      = local.aws_ec2_classic_load_balancer_icon
    threshold = 3
  }
}

category "oci_block_storage_boot_volume" {
  href = "/oci_insights.dashboard.oci_block_storage_boot_volume_detail?input.boot_volume_id={{.properties.'ID' | @uri}}"
  # icon = local.aws_ec2_classic_load_balancer_icon
  fold {
    title = "Block Storage Boot Volumes"
    #icon      = local.aws_ec2_classic_load_balancer_icon
    threshold = 3
  }
}

category "oci_compute_instance" {
  href = "/oci_insights.dashboard.oci_compute_instance_detail?input.instance_id={{.properties.'ID' | @uri}}"
  # icon = local.aws_ec2_classic_load_balancer_icon
  fold {
    title = "Compute Instances"
    #icon      = local.aws_ec2_classic_load_balancer_icon
    threshold = 3
  }
}

category "oci_database_autonomous_database" {
  href = "/oci_insights.dashboard.oci_database_autonomous_database_detail?input.db_id={{.properties.'ID' | @uri}}"
  # icon = local.aws_ec2_classic_load_balancer_icon
  fold {
    title = "Database Autonomous Databases"
    #icon      = local.aws_ec2_classic_load_balancer_icon
    threshold = 3
  }
}

category "oci_filestorage_filesystem" {
  href = "/oci_insights.dashboard.oci_filestorage_filesystem_detail?input.filesystem_id={{.properties.'ID' | @uri}}"
  # icon = local.aws_ec2_classic_load_balancer_icon
  fold {
    title = "Filestorage Filesystems"
    #icon      = local.aws_ec2_classic_load_balancer_icon
    threshold = 3
  }
}

category "oci_identity_user" {
  href = "/oci_insights.dashboard.oci_identity_user_detail?input.user_id={{.properties.'ID' | @uri}}"
  # icon = local.aws_ec2_classic_load_balancer_icon
  fold {
    title = "Identity Users"
    #icon      = local.aws_ec2_classic_load_balancer_icon
    threshold = 3
  }
}

category "oci_kms_key" {
  href = "/oci_insights.dashboard.oci_kms_key_detail?input.key_id={{.properties.'ID' | @uri}}"
  # icon = local.aws_ec2_classic_load_balancer_icon
  fold {
    title = "KMS Keys"
    #icon      = local.aws_ec2_classic_load_balancer_icon
    threshold = 3
  }
}

category "oci_mysql_db_system" {
  href = "/oci_insights.dashboard.oci_mysql_db_system_detail?input.db_system_id={{.properties.'ID' | @uri}}"
  # icon = local.aws_ec2_classic_load_balancer_icon
  fold {
    title = "MySQL DB Systems"
    #icon      = local.aws_ec2_classic_load_balancer_icon
    threshold = 3
  }
}

category "oci_nosql_table" {
  href = "/oci_insights.dashboard.oci_nosql_table_detail?input.table_id={{.properties.'ID' | @uri}}"
  # icon = local.aws_ec2_classic_load_balancer_icon
  fold {
    title = "NoSQL Tables"
    #icon      = local.aws_ec2_classic_load_balancer_icon
    threshold = 3
  }
}

category "oci_objectstorage_bucket" {
  href = "/oci_insights.dashboard.oci_objectstorage_bucket_detail?input.bucket_id={{.properties.'ID' | @uri}}"
  # icon = local.aws_ec2_classic_load_balancer_icon
  fold {
    title = "Objectstorage Buckets"
    #icon      = local.aws_ec2_classic_load_balancer_icon
    threshold = 3
  }
}

category "oci_ons_notification_topic" {
  href = "/oci_insights.dashboard.oci_ons_notification_topic_detail?input.topic_id={{.properties.'ID' | @uri}}"
  # icon = local.aws_ec2_classic_load_balancer_icon
  fold {
    title = "ONS Notification Topics"
    #icon      = local.aws_ec2_classic_load_balancer_icon
    threshold = 3
  }
}

category "oci_vcn" {
  href = "/oci_insights.dashboard.oci_vcn_detail?input.vcn_id={{.properties.'ID' | @uri}}"
  # icon = local.aws_ec2_classic_load_balancer_icon
  fold {
    title = "VCNs"
    #icon      = local.aws_ec2_classic_load_balancer_icon
    threshold = 3
  }
}

category "oci_vcn_network_security_group" {
  href = "/oci_insights.dashboard.oci_vcn_network_security_group_detail?input.security_group_id={{.properties.'ID' | @uri}}"
  # icon = local.aws_ec2_classic_load_balancer_icon
  fold {
    title = "VCN Network Security Groups"
    #icon      = local.aws_ec2_classic_load_balancer_icon
    threshold = 3
  }
}

category "oci_vcn_security_list" {
  href = "/oci_insights.dashboard.oci_vcn_security_list_detail?input.security_list_id={{.properties.'ID' | @uri}}"
  # icon = local.aws_ec2_classic_load_balancer_icon
  fold {
    title = "VCN Security Lists"
    #icon      = local.aws_ec2_classic_load_balancer_icon
    threshold = 3
  }
}

category "oci_vcn_subnet" {
  href = "/oci_insights.dashboard.oci_vcn_subnet_detail?input.subnet_id={{.properties.'ID' | @uri}}"
  # icon = local.aws_ec2_classic_load_balancer_icon
  fold {
    title = "VCN Subnets"
    #icon      = local.aws_ec2_classic_load_balancer_icon
    threshold = 3
  }
}
