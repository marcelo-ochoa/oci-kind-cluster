# Copyright (c) 2019, 2020 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
# 

resource "oci_load_balancer_load_balancer" "oci_kind_lb" {
  compartment_id = (var.lb_compartment_ocid != "") ? var.lb_compartment_ocid : var.compartment_ocid
  display_name   = "oci-kind-${random_string.deploy_id.result}"
  shape          = var.lb_shape
  subnet_ids     = [oci_core_subnet.oci_kind_lb_subnet.id]
  is_private     = "false"
  freeform_tags  = local.common_tags
  # Choose flexible as shape in var.lb_shape
  shape_details {
        #Required
        maximum_bandwidth_in_mbps = 10
        minimum_bandwidth_in_mbps = 10
    }
}

resource "oci_load_balancer_backend_set" "oci_kind_bes" {
  name             = "oci-kind-${random_string.deploy_id.result}"
  load_balancer_id = oci_load_balancer_load_balancer.oci_kind_lb.id
  policy           = "IP_HASH"

  health_checker {
    port                = "80"
    protocol            = "HTTP"
    response_body_regex = ".*"
    url_path            = "/"
    return_code         = 404
    interval_ms         = 5000
    timeout_in_millis   = 2000
    retries             = 10
  }
}

resource "oci_load_balancer_backend" "oci-kind-be" {
  load_balancer_id = oci_load_balancer_load_balancer.oci_kind_lb.id
  backendset_name  = oci_load_balancer_backend_set.oci_kind_bes.name
  ip_address       = element(oci_core_instance.app_instance.*.private_ip, count.index)
  port             = 80
  backup           = false
  drain            = false
  offline          = false
  weight           = 1

  count = (var.num_nodes > 2) ? 2 : var.num_nodes
}

resource "oci_load_balancer_listener" "oci_kind_listener_80" {
  load_balancer_id         = oci_load_balancer_load_balancer.oci_kind_lb.id
  default_backend_set_name = oci_load_balancer_backend_set.oci_kind_bes.name
  name                     = "oci-kind-${random_string.deploy_id.result}-80"
  port                     = 80
  protocol                 = "HTTP"

  connection_configuration {
    idle_timeout_in_seconds = "30"
  }
}

resource "oci_load_balancer_listener" "oci_kind_listener_443" {
  load_balancer_id         = oci_load_balancer_load_balancer.oci_kind_lb.id
  default_backend_set_name = oci_load_balancer_backend_set.oci_kind_bes.name
  name                     = "oci-kind-${random_string.deploy_id.result}-443"
  port                     = 443
  protocol                 = "HTTP"

  connection_configuration {
    idle_timeout_in_seconds = "30"
  }
}