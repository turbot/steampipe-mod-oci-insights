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
  title = "KMS Ket Version"
  icon  = "hard-drive"
  color = local.security_color
}

category "kms_vault" {
  title = "KMS Vault"
  icon  = "hard-drive"
  color = local.security_color
}