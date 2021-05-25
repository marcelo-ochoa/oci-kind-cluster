# Copyright (c) 2019, 2020 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
# 

# creates an ATP database
resource "oci_database_autonomous_database" "oci_kind_autonomous_database" {
  admin_password           = random_string.autonomous_database_admin_password.result
  compartment_id           = var.compartment_ocid
  cpu_core_count           = var.autonomous_database_cpu_core_count
  data_storage_size_in_tbs = var.autonomous_database_data_storage_size_in_tbs
  db_name                  = "${var.autonomous_database_name}${random_string.deploy_id.result}"
  db_version               = var.autonomous_database_db_version
  display_name             = "${var.autonomous_database_name}-${random_string.deploy_id.result}"
  freeform_tags            = local.common_tags
  is_free_tier             = var.autonomous_database_is_free_tier
  license_model            = var.autonomous_database_license_model
  nsg_ids                  = (var.autonomous_database_visibility == "Private") ? [oci_core_network_security_group.atp_nsg[0].id] : []
  subnet_id                = (var.autonomous_database_visibility == "Private") ? oci_core_subnet.oci_kind_main_subnet.id : ""
}
