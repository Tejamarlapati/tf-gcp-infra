# Terraform Google Cloud Infrastructure (tf-gcp-infra)

This repo contains terraform files to setup Infrastructure as Code on Google Cloud Platform.

---

[![Terraform PR Check](https://github.com/CSYE6225-Cloud-Computing-Organization/tf-gcp-infra/actions/workflows/terraform_pr.yml/badge.svg)](https://github.com/CSYE6225-Cloud-Computing-Organization/tf-gcp-infra/actions/workflows/terraform_pr.yml)

## Infrastructure as Code with Terraform and GCP

---

### Install and setup gCloud CLI

To install and set up the Google Cloud SDK (gCloud CLI), follow the instructions in the [official documentation](https://cloud.google.com/sdk/docs/install). Ensure that you have the necessary permissions and authentication set up to interact with your Google Cloud Platform projects.

### Install Terraform

To install Terraform, follow these general steps:

1. Download Terraform: Visit the [Terraform website](https://developer.hashicorp.com/terraform/install) and download the appropriate package for your operating system.
2. Follow the installation instructions as specified.
3. Verify Installation: Open a terminal or command prompt and run terraform -version to ensure Terraform has been installed correctly.

        $ terraform -version

        Terraform v1.7.3
        on darwin_arm64
        + provider registry.terraform.io/hashicorp/google v5.15.0

### Setup Terraform in repo

To set up Terraform within your repository, follow these steps:

1. **Navigate to Repository**: Open a terminal or command prompt and navigate to the root directory of your repository.
2. **Initialize Terraform**: Run terraform init to initialize Terraform within the repository. This command initializes various Terraform configurations and plugins required for your infrastructure.

        $ terraform init
        Initializing the backend...
        Initializing modules...

        Initializing provider plugins...
        - Reusing previous version of hashicorp/google from the dependency lock file
        - Using previously-installed hashicorp/google v5.15.0
        Terraform has been successfully initialized!

3. **Plan Infrastructure Changes**: After initialization, you can run terraform plan to see what changes Terraform will make to your infrastructure. Use -var-file to specify a variable file if needed.

        terraform plan -var-file=dev-vars.tfvars

4. **Apply Infrastructure Changes**: If the plan looks good, you can apply the changes by running terraform apply. Use -var-file to specify a variable file if needed.

        terraform apply -var-file=dev-vars.tfvars

5. **Destroy Infrastructure**: To destroy the infrastructure created by Terraform, you can run terraform destroy. Make sure to review the plan before proceeding.

        terraform destroy

---

### What's in  this repo

**root**: Contains files to deploy multiple VPCs along with subnets and routes based on variables from a local tfvars file.

**modules**: Contains implementation code for multiple standalone submodules.

1. **vpc**: Module to handle a VPC network, including:
    - Creation/updation of network
    - Creation/updation of subnetworks in the VPC
    - Creation/updation of routes for the VPC

---

## Usage

The following variables are required to create multiple VPC via terraform.

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

| Output       | Description                                                                   |
| ------------ | ----------------------------------------------------------------------------- |
| vpc_networks | List of VPCs with their names, self-links, and associated subnets and routes. |

#### Output Details

- **vpc_networks**: This output provides a list of VPCs with their respective details, including:
  - **name**: The name of the VPC.
  - **self_link**: The self-link URL of the VPC.
  - **subnets**: A list of subnets within the VPC, including their names, regions, and self-links.
  - **routes**: A list of routes within the VPC, including their names and self-links.

## Examples

### [Examples](EXAMPLES.md)
