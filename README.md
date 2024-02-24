# Terraform Google Cloud Infrastructure (tf-gcp-infra)

This repo contains terraform files to setup Infrastructure as Code on Google Cloud Platform.

---

## Infrastructure as Code with Terraform and GCP

### Installation

Please follow the installation instructions required for setting up the project [here](INSTALLATION.md).

### Enable gCloud services

This project relies on the following services to run for a project

- `compute.googleapis.com`
- `servicenetworking.googleapis.com`

These can be enabled from cli after setting up the default project using the following commands:

    gcloud services enable {service-name}.googleapis.com

For additional info regarding enabling cli via services, refer [here](https://cloud.google.com/sdk/gcloud/reference/services/enable).

### What's in  this repo

**root**: Contains files to deploy a VPC along with subnets and routes based on variables from a local tfvars file.

**modules**: Contains implementation code for multiple standalone submodules.

---

## Usage

The following variables are required to create a VPC via terraform.
| Variable                              | Type   | Required       | Description                                                           | Default                                       |
| ------------------------------------- | ------ | -------------- | --------------------------------------------------------------------- | --------------------------------------------- |
| project_id                            | string | yes            | The ID of the GCP project.                                            |                                               |
| region                                | string |                | The default region in which to create the resources.                  | us-east-1                                     |
| vpc_name                              | string | yes            | Name of the Virtual Private Cloud (VPC).                              |                                               |
| vpc_description                       | string |                | Description of the Virtual Private Cloud (VPC).                       | {vpc_name} - Virtual Private Cloud            |
| vpc_routing_mode                      | string |                | VPC routing mode.                                                     | REGIONAL                                      |
| vpc_auto_create_subnets               | bool   |                | Whether to create subnets in the VPC.                                 | false                                         |
| vpc_delete_default_routes_on_create   | bool   |                | Whether to delete the default route created by the VPC.               | true                                          |
| subnets                               | list   | *conditionally | A list of subnet configurations within the VPC.                       |                                               |
| subnets[name]                         | string | yes            | The name of the subnet.                                               |                                               |
| subnets[ip_cidr_range]                | string | yes            | The range of internal IP addresses for this subnet.                   |                                               |
| subnets[description]                  | string |                | The description of the subnet.                                        | Subnet {subnet.name} under {var.vpc_name} VPC |
| subnets[region]                       | string |                | The region in which the subnet will be created.                       | {var.region}                                  |
| subnets[private_ip_google_access]     | bool   |                | Whether VMs can access Google services without external IP addresses. | true                                          |
| routes                                | list   |                | A list of route configurations within the VPC.                        |                                               |
| routes[name]                          | string | yes            | The name of the route.                                                |                                               |
| routes[dest_range]                    | string | yes            | The destination range of the route.                                   |                                               |
| routes[description]                   | string |                | The description of the route.                                         | Route {name} under {var.vpc_name} VPC         |
| routes[tags]                          | list   |                | A list of instance tags to which this route applies.                  | []                                            |
| routes[next_hop_gateway]              | string | <-\|           | The next hop gateway of the route.                                    |                                               |
| routes[next_hop_ip]                   | string | <-\|           | The next hop IP of the route.                                         |                                               |
| routes[next_hop_ilb]                  | string | <-\|  one of   | The next hop ILB of the route.                                        |                                               |
| routes[next_hop_instance]             | string | <-\|           | The next hop instance of the route.                                   |                                               |
| routes[next_hop_instance_zone]        | string | <-\|           | The zone of the next hop instance of the route.                       |                                               |
| firewall_rules                        | list   |                | A list of firewall rule configurations within the VPC.                |                                               |
| firewall_rules[name]                  | string | yes            | The name of the firewall rule.                                        |                                               |
| firewall_rules[description]           | string |                | The description of the firewall rule.                                 | Firewall rule {name} under {var.vpc_name} VPC |
| firewall_rules[direction]             | string | yes            | The direction of traffic to which this firewall applies.              |                                               |
| firewall_rules[priority]              | number |                | The priority of firewall rule.                                        | 1000                                          |
| firewall_rules[source_ranges]         | list   |                | A list of source IP ranges to which this firewall applies.            | null                                          |
| firewall_rules[destination_ranges]    | list   |                | A list of destination IP ranges to which this firewall applies.       | null                                          |
| firewall_rules[source_tags]           | list   |                | A list of source instance tags to which this firewall applies.        | null                                          |
| firewall_rules[target_tags]           | list   |                | A list of target instance tags to which this firewall applies.        | null                                          |
| firewall_rules[allowed]               | list   |                | A list of allowed protocols and ports.                                | null                                          |
| firewall_rules[allowed]\[protocol]    | string | yes            | The protocol to allow.                                                |                                               |
| firewall_rules[allowed]\[ports]       | list   | yes            | The ports to allow.                                                   |                                               |
| firewall_rules[denied]                | list   |                | A list of denied protocols and ports.                                 | null                                          |
| firewall_rules[denied]\[protocol]     | string | yes            | The protocol to deny.                                                 |                                               |
| firewall_rules[denied]\[ports]        | list   | yes            | The ports to deny.                                                    |                                               |
| webapp_compute_instance               | object |                | Configuration for the web server compute instance.                    |                                               |
| webapp_compute_instance[name]         | string | yes            | The name of the instance.                                             |                                               |
| webapp_compute_instance[machine_type] | string | yes            | The machine type of the instance.                                     |                                               |
| webapp_compute_instance[zone]         | string | yes            | The zone in which the instance is created.                            |                                               |
| webapp_compute_instance[tags]         | list   |                | A list of instance tags.                                              | null                                          |
| webapp_compute_instance[image]        | string | yes            | The image of the instance.                                            |                                               |
| webapp_compute_instance[disk_size]    | number | yes            | The size of the boot disk.                                            |                                               |
| webapp_compute_instance[disk_type]    | string | yes            | The type of the boot disk.                                            |                                               |
| webapp_compute_instance[subnet_name]  | string |                | The name of the subnet to bind this instance to.                      | Defaults to VPC network                       |

\*conditionally => `subnets` (list(object{...})) are required if `vpc_auto_create_subnets` is set to `false` or else the subnets wouldn't be created for the VPC

### Outputs

After deploying the VPCs using Terraform, you can retrieve information about the created VPCs, including their names, self-links, subnets, and routes, using the following outputs:

| Output            | Description                                             |
| ----------------- | ------------------------------------------------------- |
| vpc               | The VPC created by this module.                         |
| subnets           | List of subnets created for the VPC.                    |
| routes            | List of routes created for the VPC.                     |
| firewall_rules    | List of firewall rules created for the VPC.             |
| web_server        | The web server compute instance created by this module. |
| database_instance | The SQL Database instance created by this module.       |

## Examples

### [Examples](EXAMPLES.md)
