# A Docker kind Cluster deployed as terraform scripts

This is a Terraform configuration that deploys a two node kind cluster on [Oracle Cloud Infrastructure (OCI)][oci].

It also included an HA storage implemented in GlusterFS and docker plugins for Gluster FS and Oracle Object Storage.

## Topology

The application uses a typical topology for a 3-tier web application as follows

![OciKind Basic Infra](https://miro.medium.com/max/700/1*WDh1kMHnQTg2Ed9orIq7-w.png)

### Components

| Component             | What                                                                                                           | Why                                                                                                                                                                                                                                    | Learn                 |
| --------------------- | -------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------- |
| Compute Instances     | 2 Always Free tier eligible compute instance                                                              | These VMs host the application                                                                                                                                                                                                         | [Learn More][inst]    |
| Autonomous Database   | 1 Always Free tier eligible Autonomous Database instance                                                       | The database used by the application                                                                                                                                                                                                   | [Learn More][adb]     |
| Vault                 | Optional use of OCI Vault keys for Key Management (KMS).       | Encrypt boot volumes of the compute instances and Object Storage buckets.                                             | [Learn More][kms] |
| Load Balancer         | 1 Always Free tier eligible load balancer                                                                      | Routes traffic between the nodes hosting the application                                                                                                                                                                               | [Learn More][lb]      |
| Virtual Cloud Network | This resource provides a virtual network in the cloud                                                          | The virtual network used by the application to host all its networking components                                                                                                                                                      | [Learn More][vcn]     |
| Private Subnet        | A subnet within the network that does not allow the network components to have publicly reachable IP addresses | The private subnet is used to house the compute instances. Being private, they ensure that the application nodes are not exposed to the internet                                                                                       | [Learn More][vcn]     |
| Public Subnet         | A subnet that allows public IPs.                                                                               | The subnet that houses the public load balancer. Components in this subnet can be allocated public IP addresses and be exposed to the internet through the InternetGateway.                                                            | [Learn More][vcn]     |
| Internet Gateway      | A virtual router that allows direct internet access.                                                           | This enables the load balancer to be reachable from the internet.                                                                                                                                                                      | [Learn More][igw]     |
| NAT Gateway           | (Not available on Always-free only) A virtual router that allows internet access without exposing the source directly to the internet              | It gives the compute instances (with no public IP addresses) access to the internet without exposing them to incoming internet connections.                                                                                            | [Learn More][natgw]   |
| Service Gateway       | (Not available on Always-free only) A virtual router that enables private traffic to OCI services from a VCN                                       | Provides a path for private network traffic between your VCN and services like Object Storage or ATP.                                                                                                                                  | [Learn More][svcgw]   |
| Route Tables          | Route tables route traffic that leaves the VCN.                                                                | The public subnet route rules direct traffic to use the Internet Gateway, while the private subnet route rules enable the compute instances to reach the internet through the NAT gateway and OCI services through the service gateway | [Learn More][rt]      |
| Security Lists        | Security Lists act like a firewall with the rules determining what type of traffic is allowed in or out.       | Security rules enable HTTP traffic to the LoadBalancer from anywhere. Also enables are HTTP and SSH traffic to the compute instances, but only from the subnet where the load balancer is.                                             | [Learn More][seclist] |

## Using local or CloudShell terraform

Clone <https://github.com/marcelo-ochoa/oci-kind-cluster>

- Rename the file `terraform.tfvars.example` to `terraform.tfvars`
- Change the credentials variables to your user and any other desirable variables
- Run `terraform init` to init the terraform providers
- Run `terraform apply` to create the resources on OCI

## Using Resource Manager GitHub Connector

Just Fork <https://github.com/marcelo-ochoa/oci-kind-cluster> using your GitHub account and import using OCI Resource Manager. See how it works on this video:

[![](http://img.youtube.com/vi/mnF090QRqO4/0.jpg)](http://www.youtube.com/watch?v=mnF090QRqO4&start=245 "OCI Resource Manager GitHub Integration")

## Deploy as Zip file

Clone <https://github.com/marcelo-ochoa/oci-kind-cluster>

- Go into directory oci-kind-cluster and zip it using "zip -r ../oci-kind-cluster.zip *"
- Upload oci-kind-cluster.zip on using OCI Resource Manager pane

[oci]: https://cloud.oracle.com/en_US/cloud-infrastructure
[orm]: https://docs.cloud.oracle.com/iaas/Content/ResourceManager/Concepts/resourcemanager.htm
[tf]: https://www.terraform.io
[net]: https://docs.cloud.oracle.com/iaas/Content/Network/Concepts/overview.htm
[vcn]: https://docs.cloud.oracle.com/iaas/Content/Network/Tasks/managingVCNs.htm
[lb]: https://docs.cloud.oracle.com/iaas/Content/Balance/Concepts/balanceoverview.htm
[igw]: https://docs.cloud.oracle.com/iaas/Content/Network/Tasks/managingIGs.htm
[natgw]: https://docs.cloud.oracle.com/iaas/Content/Network/Tasks/NATgateway.htm
[svcgw]: https://docs.cloud.oracle.com/iaas/Content/Network/Tasks/servicegateway.htm
[rt]: https://docs.cloud.oracle.com/iaas/Content/Network/Tasks/managingroutetables.htm
[seclist]: https://docs.cloud.oracle.com/iaas/Content/Network/Concepts/securitylists.htm
[adb]: https://docs.cloud.oracle.com/iaas/Content/Database/Concepts/adboverview.htm
[inst]: https://docs.cloud.oracle.com/iaas/Content/Compute/Concepts/computeoverview.htm
[kms]: https://docs.cloud.oracle.com/en-us/iaas/Content/KeyManagement/Concepts/keyoverview.htm
[magic_button]: https://oci-resourcemanager-plugin.plugins.oci.oraclecloud.com/latest/deploy-to-oracle-cloud.svg
[magic_oci_kind_basic_stack]: https://console.us-ashburn-1.oraclecloud.com/resourcemanager/stacks/create?region=home&zipUrl=https://github.com/oracle-quickstart/oci-cloudnative/releases/latest/download/oci-kind-basic-stack-latest.zip
