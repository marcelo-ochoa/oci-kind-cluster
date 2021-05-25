# Copyright (c) 2019, 2020 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
# 

resource "oci_objectstorage_bucket" "kind" {
  compartment_id = var.compartment_ocid
  name           = "oci-kind-${random_string.deploy_id.result}"
  namespace      = data.oci_objectstorage_namespace.user_namespace.namespace
  freeform_tags  = local.common_tags
  kms_key_id     = var.use_encryption_from_oci_vault ? (var.create_new_encryption_key ? oci_kms_key.oci_kind_key[0].id : var.encryption_key_id) : null
  depends_on     = [oci_identity_policy.oci_kind_basic_policies]
}

resource "oci_objectstorage_object" "oci_kind_wallet" {
  bucket    = oci_objectstorage_bucket.kind.name
  content   = data.oci_database_autonomous_database_wallet.autonomous_database_wallet.content
  namespace = data.oci_objectstorage_namespace.user_namespace.namespace
  object    = "oci_kind_atp_wallet"
}
resource "oci_objectstorage_preauthrequest" "oci_kind_wallet_preauth" {
  access_type  = "ObjectRead"
  bucket       = oci_objectstorage_bucket.kind.name
  name         = "oci_kind_wallet_preauth"
  namespace    = data.oci_objectstorage_namespace.user_namespace.namespace
  time_expires = timeadd(timestamp(), "30m")
  object       = oci_objectstorage_object.oci_kind_wallet.object
}

# Static assets bucket
resource "oci_objectstorage_bucket" "oci_kind_media" {
  compartment_id = (var.object_storage_oci_kind_media_compartment_ocid != "") ? var.object_storage_oci_kind_media_compartment_ocid : var.compartment_ocid
  name           = "oci-kind-media-${random_string.deploy_id.result}"
  namespace      = data.oci_objectstorage_namespace.user_namespace.namespace
  freeform_tags  = local.common_tags
  access_type    = (var.object_storage_oci_kind_media_visibility == "Private") ? "NoPublicAccess" : "ObjectReadWithoutList"
  kms_key_id     = var.use_encryption_from_oci_vault ? (var.create_new_encryption_key ? oci_kms_key.oci_kind_key[0].id : var.encryption_key_id) : null
}

# Static product media
resource "oci_objectstorage_object" "oci_kind_media" {
  for_each = fileset("./images", "**")

  bucket        = oci_objectstorage_bucket.oci_kind_media.name
  namespace     = oci_objectstorage_bucket.oci_kind_media.namespace
  object        = each.value
  source        = "./images/${each.value}"
  content_type  = "image/png"
  cache_control = "max-age=604800, public, no-transform"
}

resource "oci_objectstorage_bucket" "registry" {
  compartment_id = var.compartment_ocid
  name           = "oci-registry-${random_string.deploy_id.result}"
  namespace      = data.oci_objectstorage_namespace.user_namespace.namespace
  freeform_tags  = local.common_tags
  kms_key_id     = var.use_encryption_from_oci_vault ? (var.create_new_encryption_key ? oci_kms_key.oci_kind_key[0].id : var.encryption_key_id) : null
  depends_on     = [oci_identity_policy.oci_kind_basic_policies]
}

resource "oci_objectstorage_object" "registry" {
  bucket        = oci_objectstorage_bucket.registry.name
  namespace     = oci_objectstorage_bucket.registry.namespace
  object        = "README.md"
  source        = "./README.md"
  content_type  = "text/plain"
  cache_control = "max-age=604800, public, no-transform"
}

resource "oci_objectstorage_bucket" "portainer" {
  compartment_id = var.compartment_ocid
  name           = "oci-portainer-${random_string.deploy_id.result}"
  namespace      = data.oci_objectstorage_namespace.user_namespace.namespace
  freeform_tags  = local.common_tags
  kms_key_id     = var.use_encryption_from_oci_vault ? (var.create_new_encryption_key ? oci_kms_key.oci_kind_key[0].id : var.encryption_key_id) : null
  depends_on     = [oci_identity_policy.oci_kind_basic_policies]
}

resource "oci_objectstorage_object" "portainer" {
  bucket        = oci_objectstorage_bucket.portainer.name
  namespace     = oci_objectstorage_bucket.portainer.namespace
  object        = "README.md"
  source        = "./README.md"
  content_type  = "text/plain"
  cache_control = "max-age=604800, public, no-transform"
}
