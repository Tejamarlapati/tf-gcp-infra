# VPC Module

This Terraform module creates a Virtual Private Cloud (VPC) on Google Cloud Platform (GCP) along with its subnets and routes.

## Inputs

| Name                                   | Description                                               | Type            | Required        |
| -------------------------------------- | --------------------------------------------------------- | --------------- | --------------- |
| `vpc`                                  | Configuration object for the VPC                          | `object({...})` | Yes             |
| `vpc.name`                             | Name of the VPC                                           | `string`        | Yes             |
| `vpc.description`                      | Description of the VPC                                    | `string`        | Yes             |
| `vpc.routing_mode`                     | Routing mode for the VPC (e.g., "GLOBAL" or "REGIONAL")   | `string`        | Yes             |
| `vpc.auto_create_subnets`              | Whether to auto-create subnets within the VPC             | `bool`          | Yes             |
| `vpc.delete_default_routes_on_create`  | Whether to delete default routes on VPC creation          | `bool`          | Yes             |
| `vpc.subnets`                          | List of subnets to create within the VPC                  | `list({...})`   | Yes             |
| `vpc.subnets.name`                     | Name of the subnet                                        | `string`        | Yes             |
| `vpc.subnets.ip_cidr_range`            | CIDR range for the subnet                                 | `string`        | Yes             |
| `vpc.subnets.description`              | Description of the subnet                                 | `string`        | Yes             |
| `vpc.subnets.region`                   | Region for the subnet                                     | `string`        | Yes             |
| `vpc.subnets.private_ip_google_access` | Whether to enable private IP Google access for the subnet | `bool`          | Yes             |
| `vpc.routes`                           | List of routes to create within the VPC                   | `list({...})`   | Yes             |
| `vpc.routes.name`                      | Name of the route                                         | `string`        | Yes             |
| `vpc.routes.dest_range`                | Destination range for the route                           | `string`        | Yes             |
| `vpc.routes.next_hop_gateway`          | Next hop gateway for the route (optional)                 | `string`        | One of next_hop |
| `vpc.routes.next_hop_ip`               | Next hop IP address for the route (optional)              | `string`        | One of next_hop |
| `vpc.routes.next_hop_ilb`              | Next hop internal load balancer for the route (optional)  | `string`        | One of next_hop |
| `vpc.routes.tags`                      | List of tags for the route (optional)                     | `list(string)`  | No              |

## Outputs

| Name      | Description                                                        | Type                  |
| --------- | ------------------------------------------------------------------ | --------------------- |
| `network` | A reference to the VPC network                                     | `object({...})`       |
| `subnets` | A list of subnets. Each element contains a reference to the subnet | `list(object({...}))` |
| `routes`  | A list of routes. Each element contains a reference to the route   | `list(object({...}))` |

## Usage

```hcl
module "vpc" {
  source = "path/to/module"

  vpc = {
    name                            = "example-vpc"
    description                     = "Example VPC"
    routing_mode                    = "GLOBAL"
    auto_create_subnets             = true
    delete_default_routes_on_create = false

    subnets = [
      {
        name                     = "subnet-1"
        description              = "Subnet 1"
        region                   = "us-central1"
        ip_cidr_range            = "10.1.0.0/24"
        private_ip_google_access = true
      },
      # Add more subnets as needed
    ]

    routes = [
      {
        name             = "route-1"
        dest_range       = "10.2.0.0/16"
        next_hop_gateway = "example-gateway"
        tags             = ["tag1", "tag2"]
      },
      # Add more routes as needed
    ]
  }
}

```
