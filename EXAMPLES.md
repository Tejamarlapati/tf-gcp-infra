# Example VPC Configurations

---

## 1. Simple VPC setup configuration

Only sending the required parameters and letting the VPC module take care of filling the opinionated defaults.

**Input I** example creates the following:

1. VPC named `dev` without default routes
2. Two subnets:
   1. `webapp` with CIDR range set to 10.0.1.0/24
   2. `db` with CIDR range set to 10.0.2.0/24
3. Route `vpc-dev-route-public-access` to internet gateway for the VPC

### Input I

```hcl
project_id = "csye-6225-cloud-computing"
region     = "us-east1"
vpc_name   = "dev"
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

```

### Output I

```hcl
routes  = [
    {
        description            = "Route public-access under dev VPC"
        dest_range             = "0.0.0.0/0"
        id                     = (known after apply)
        name                   = "vpc-dev-route-public-access"
        network                = (known after apply)
        next_hop_gateway       = "default-internet-gateway"
        next_hop_ilb           = null
        next_hop_instance      = null
        next_hop_instance_zone = (known after apply)
        next_hop_ip            = (known after apply)
        next_hop_network       = (known after apply)
        next_hop_vpn_tunnel    = null
        priority               = 1000
        project                = "csye-6225-cloud-computing"
        self_link              = (known after apply)
        tags                   = [
            "public",
          ]
        timeouts               = null
      },
  ]
subnets = [
    {
        creation_timestamp         = (known after apply)
        description                = "Subnet webapp under dev VPC"
        external_ipv6_prefix       = (known after apply)
        fingerprint                = (known after apply)
        gateway_address            = (known after apply)
        id                         = (known after apply)
        internal_ipv6_prefix       = (known after apply)
        ip_cidr_range              = "10.0.1.0/24"
        ipv6_access_type           = null
        ipv6_cidr_range            = (known after apply)
        log_config                 = []
        name                       = "webapp"
        network                    = (known after apply)
        private_ip_google_access   = true
        private_ipv6_google_access = (known after apply)
        project                    = "csye-6225-cloud-computing"
        purpose                    = (known after apply)
        region                     = "us-east1"
        role                       = null
        secondary_ip_range         = (known after apply)
        self_link                  = (known after apply)
        stack_type                 = (known after apply)
        timeouts                   = null
      },
    {
        creation_timestamp         = (known after apply)
        description                = "Subnet db under dev VPC"
        external_ipv6_prefix       = (known after apply)
        fingerprint                = (known after apply)
        gateway_address            = (known after apply)
        id                         = (known after apply)
        internal_ipv6_prefix       = (known after apply)
        ip_cidr_range              = "10.0.2.0/24"
        ipv6_access_type           = null
        ipv6_cidr_range            = (known after apply)
        log_config                 = []
        name                       = "db"
        network                    = (known after apply)
        private_ip_google_access   = true
        private_ipv6_google_access = (known after apply)
        project                    = "csye-6225-cloud-computing"
        purpose                    = (known after apply)
        region                     = "us-east1"
        role                       = null
        secondary_ip_range         = (known after apply)
        self_link                  = (known after apply)
        stack_type                 = (known after apply)
        timeouts                   = null
      },
  ]
vpc     = {
    auto_create_subnetworks                   = false
    delete_default_routes_on_create           = true
    description                               = "dev - Virtual Private Cloud"
    enable_ula_internal_ipv6                  = null
    gateway_ipv4                              = (known after apply)
    id                                        = (known after apply)
    internal_ipv6_range                       = (known after apply)
    mtu                                       = (known after apply)
    name                                      = "dev"
    network_firewall_policy_enforcement_order = "AFTER_CLASSIC_FIREWALL"
    numeric_id                                = (known after apply)
    project                                   = "csye-6225-cloud-computing"
    routing_mode                              = "REGIONAL"
    self_link                                 = (known after apply)
    timeouts                                  = null
  }
```
