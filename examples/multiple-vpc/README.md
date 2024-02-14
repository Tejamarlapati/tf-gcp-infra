# Multiple VPCs Setup

This repo contains terraform files to setup Infrastructure as Code on Google Cloud Platform.

---

## Infrastructure as Code with Terraform and GCP

### Installation

Please follow the installation instructions required for setting up the project [here](INSTALLATION.md).

### Enable gCloud services

This project relies on the following services to run for a project

- `compute.googleapis.com`

These can be enabled from cli after setting up the default project using the following commands:

    gcloud services enable compute.googleapis.com

For additional info regarding enabling cli via services, refer [here](https://cloud.google.com/sdk/gcloud/reference/services/enable).

---

## Usage

The following variables are required to create multiple VPCs via terraform.

| Variable                                | Type   | Required    | Description                                          | Default                                   |
| --------------------------------------- | ------ | ----------- | ---------------------------------------------------- | ----------------------------------------- |
| project_id                              | string | yes         | The ID of the GCP project.                           |                                           |
| region                                  | string |             | The default region in which to create the resources. | us-east-1                                 |
| vpcs                                    | list   | min: 1      | A list of VPC configurations.                        |                                           |
| vpcs[name]                              | string | yes         | The name of the VPC.                                 |                                           |
| vpcs[description]                       | string |             | The description of the VPC.                          | ${vpc.name} Virtual Private Cloud         |
| vpcs[routing_mode]                      | string |             | The network routing mode.                            | REGIONAL                                  |
| vpcs[auto_create_subnets]               | bool   |             | Whether to create subnets automatically.             | false                                     |
| vpcs[delete_default_routes_on_create]   | bool   |             | Whether to delete the default route on create.       | true                                      |
| vpcs[subnets]                           | list   | min: 1      | A list of subnet configurations within the VPC.      |                                           |
| vpcs[subnets][name]                     | string | yes         | The name of the subnet.                              |                                           |
| vpcs[subnets][ip_cidr_range]            | string | yes         | The IP CIDR range of the subnet.                     |                                           |
| vpcs[subnets][description]              | string |             | The description of the subnet.                       | ${subnet.name} subnet for ${vpc.name} VPC |
| vpcs[subnets][region]                   | string |             | The region in which the subnet will be created.      | ${var.region}                             |
| vpcs[subnets][private_ip_google_access] | bool   |             | Whether to enable private IP Google access.          | true                                      |
| vpcs[routes]                            | list   |             | A list of route configurations within the VPC.       |                                           |
| vpcs[routes][name]                      | string | yes         | The name of the route.                               |                                           |
| vpcs[routes][dest_range]                | string | yes         | The destination range of the route.                  |                                           |
| vpcs[routes][tags]                      | list   |             | The tags of the route.                               | []                                        |
| vpcs[routes][next_hop_gateway]          | string | <-\|        | The next hop gateway of the route.                   |                                           |
| vpcs[routes][next_hop_ip]               | string | <-\| one of | The next hop IP of the route.                        |                                           |
| vpcs[routes][next_hop_ilb]              | string | <-\|        | The next hop ILB of the route.                       |                                           |

### Outputs

After deploying the VPCs using Terraform, you can retrieve information about the created VPCs, including their names, self-links, subnets, and routes, using the following outputs:

| Output       | Description                                                     |
| ------------ | --------------------------------------------------------------- |
| vpc_networks | List of VPCs with their names, self-links, subnets, and routes. |

#### Output Details

| Attribute          | Description                       |
| ------------------ | --------------------------------- |
| name               | The name of the VPC.              |
| self_link          | The self-link URL of the VPC.     |
| subnets            | A list of subnets within the VPC. |
| subnets[name]      | The name of the subnet.           |
| subnets[region]    | The region of the subnet.         |
| subnets[self_link] | The self-link URL of the subnet.  |
| routes             | A list of routes within the VPC.  |
| routes[name]       | The name of the route.            |
| routes[self_link]  | The self-link URL of the route.   |

## Examples

### [Examples](EXAMPLES.md)
