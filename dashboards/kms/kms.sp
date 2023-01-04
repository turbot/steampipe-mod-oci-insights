locals {
  kms_common_tags = {
    service = "OCI/KMS"
  }
}

category "kms_key" {
  title = "KMS Key"
  href  = "/oci_insights.dashboard.kms_key_detail?input.key_id={{.properties.'ID' | @uri}}"
  icon  = "key"
  color = local.security_color
}

category "kms_key_version" {
  title = "KMS Key Version"
  icon  = "key"
  color = local.security_color
}

category "kms_vault" {
  title = "KMS Vault"
  icon  = "key"
  color = local.security_color
}

category "kms_vault_secret" {
  title = "KMS Vault Secret"
  icon  = "enhanced_encryption"
  color = local.security_color
}