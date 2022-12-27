locals {
  kms_common_tags = {
    service = "OCI/KMS"
  }
}

category "kms_key" {
  title = "KMS Key"
  icon  = "key"
  color = local.security_color
}

category "kms_key_version" {
  title = "KMS Key Version"
  icon  = "hard_drive"
  color = local.security_color
}

category "kms_vault" {
  title = "KMS Vault"
  icon  = "key"
  color = local.security_color
}