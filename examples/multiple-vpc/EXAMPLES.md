# Example VPC Configurations

---

## 1. Simple VPC setup configuration

Only sending the required parameters and letting the VPC module take care of filling the opinionated defaults. This example creates the following:

1. VPC named `dev` without default routes
2. Two subnets:
   1. `webapp` with CIDR range set to 10.0.1.0/24
   2. `db` with CIDR range set to 10.0.2.0/24
3. Route `vpc-dev-route-public-access` to internet gateway for the VPC

### Input I

```hcl
project_id = "csye6225-cloud-computing-dev"

region = "us-east1"

vpcs = [
  {
    name = "dev"
    subnets = [
      {
        name          = "webapp"
        ip_cidr_range = "10.0.1.0/24"
      },
      {
        name          = "db"
        ip_cidr_range = "10.0.2.0/24"
      }
    ]
    routes = [
      {
        name             = "public-access"
        dest_range       = "0.0.0.0/0"
        next_hop_gateway = "default-internet-gateway"
        tags             = ["public"]
      }
    ]
  }
]
```

### Output I

```hcl
vpc_networks = [
  {
    "name" = "dev"
    "routes" = [
      {
        "name" = "vpc-dev-route-public-access"
        "self_link" = "https://www.googleapis.com/compute/v1/projects/csye6225-cloud-computing-dev/global/routes/vpc-dev-route-public-access"
      },
    ]
    "self_link" = "https://www.googleapis.com/compute/v1/projects/csye6225-cloud-computing-dev/global/networks/dev"
    "subnets" = [
      {
        "name" = "db"
        "region" = "us-east1"
        "self_link" = "https://www.googleapis.com/compute/v1/projects/csye6225-cloud-computing-dev/regions/us-east1/subnetworks/db"
      },
      {
        "name" = "webapp"
        "region" = "us-east1"
        "self_link" = "https://www.googleapis.com/compute/v1/projects/csye6225-cloud-computing-dev/regions/us-east1/subnetworks/webapp"
      },
    ]
  },
]
```

## 2. Non-Defaults VPC setup configuration

Sending optional parameters along with required parameters and letting the VPC module take care of filling the opinionated defaults. This example creates the following:

1. VPC named `dev-us-east1` without default routes
   1. Two subnets under `dev-us-east1`
      1. `webapp` with CIDR range set to 10.0.1.0/24
      2. `db` with CIDR range set to 10.0.2.0/24
   2. Route `vpc-dev-us-east1-route-public-access` to internet gateway for the VPC
2. VPC named `dev-us-west1` without default routes
   1. Two subnets under `dev-us-east1`
      1. `webapp` with CIDR range set to 10.0.10.0/24
      2. `db` with CIDR range set to 10.0.11.0/24

### Input II

```hcl
project_id = "csye6225-cloud-computing-dev"

region = "us-east1"

vpcs = [
  {
    name                            = "dev-us-east1"
    routing_mode                    = "REGIONAL"
    auto_create_subnetworks         = false
    delete_default_routes_on_create = true
    subnets = [
      {
        name                     = "webapp"
        region                   = "us-east1"
        ip_cidr_range            = "10.0.1.0/24"
        private_ip_google_access = false
      },
      {
        name                     = "db"
        region                   = "us-east1"
        ip_cidr_range            = "10.0.2.0/24"
        private_ip_google_access = true
      }
    ]
    routes = [
      {
        name             = "public-access"
        dest_range       = "0.0.0.0/0"
        next_hop_gateway = "default-internet-gateway"
        tags             = ["public"]
      }
    ]
  },
  {
    name = "dev-us-west1"
    subnets = [
      {
        name          = "webapp"
        region        = "us-west1"
        ip_cidr_range = "10.0.10.0/24"
      },
      {
        name          = "db"
        region        = "us-west1"
        ip_cidr_range = "10.0.11.0/24"
      }
    ]
  }
]
```

### Output II

```hcl
vpc_networks = [
  {
    "name" = "dev-us-east1"
    "routes" = [
      {
        "name" = "vpc-dev-us-east1-route-public-access"
        "self_link" = "https://www.googleapis.com/compute/v1/projects/csye6225-cloud-computing-dev/global/routes/vpc-dev-us-east1-route-public-access"
      },
    ]
    "self_link" = "https://www.googleapis.com/compute/v1/projects/csye6225-cloud-computing-dev/global/networks/dev-us-east1"
    "subnets" = [
      {
        "name" = "db"
        "region" = "us-east1"
        "self_link" = "https://www.googleapis.com/compute/v1/projects/csye6225-cloud-computing-dev/regions/us-east1/subnetworks/db"
      },
      {
        "name" = "webapp"
        "region" = "us-east1"
        "self_link" = "https://www.googleapis.com/compute/v1/projects/csye6225-cloud-computing-dev/regions/us-east1/subnetworks/webapp"
      },
    ]
  },
  {
    "name" = "dev-us-west1"
    "routes" = []
    "self_link" = "https://www.googleapis.com/compute/v1/projects/csye6225-cloud-computing-dev/global/networks/dev-us-west1"
    "subnets" = [
      {
        "name" = "db"
        "region" = "us-west1"
        "self_link" = "https://www.googleapis.com/compute/v1/projects/csye6225-cloud-computing-dev/regions/us-west1/subnetworks/db"
      },
      {
        "name" = "webapp"
        "region" = "us-west1"
        "self_link" = "https://www.googleapis.com/compute/v1/projects/csye6225-cloud-computing-dev/regions/us-west1/subnetworks/webapp"
      },
    ]
  },
]
```
