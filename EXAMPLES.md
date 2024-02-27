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
project_id = "csye6225-cloud-computing-dev"
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
      name                   = "vpc-dev-route-public-access"
      self_link              = (known after apply)
    },
  ]
subnets = [
    {
        name                       = "webapp"
        self_link                  = (known after apply)
      },
    {
        name                       = "db"
        self_link                  = (known after apply)
      },
  ]
vpc     = {
    name                       = "dev"
    self_link                  = (known after apply)
  }
```

## 2. Configuration for VPC setup with firewall rules and web server

Only sending the required parameters and letting the VPC module take care of filling the opinionated defaults.

**Input I** example creates the following:

1. VPC named `dev` without default routes
2. Two subnets:
   1. `webapp` with CIDR range set to 10.0.1.0/24
   2. `db` with CIDR range set to 10.0.2.0/24
3. Route `vpc-dev-route-public-access` to internet gateway for the VPC with tags `public` and `webapp`
4. Creates a firewall rule `allow-webapp-subnet-http` to allow `TCP` protocol on port `80` to `webapp` subnet
5. Creates a webapp compute instance `webapp-server` using `webapp` subnet as well as a public ip

### Input II

```hcl
project_id = "csye6225-cloud-computing-dev"
region     = "us-east1"

vpc_name = "dev"

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
    tags             = ["public", "webapp"]
  }
]

firewall_rules = [{
  name               = "allow-webapp-subnet-http"
  direction          = "INGRESS"
  action             = "ALLOW"
  target_tags        = ["webapp"]
  source_ranges      = ["0.0.0.0/0"]
  destination_ranges = ["10.0.1.0/24"]
  allowed = [{
    protocol = "tcp"
    ports    = ["80"]
  }]
}]

webapp_compute_instance = {
  name         = "webapp-server"
  machine_type = "e2-micro"
  tags         = ["webapp"]
  subnet_name  = "webapp"
  zone         = "us-east1-b"
  # Compute Engine Instance Properties
  image     = "csye6225-webapp-image-1708270115"
  disk_type = "pd-balanced"
  disk_size = 100
}
```

### Output II

```hcl
firewall_rules = [
    {
        name      = "allow-webapp-subnet-http"
        self_link = (known after apply)
      },
  ]
routes         = [
    {
        name      = "vpc-dev-route-public-access"
        self_link = (known after apply)
      },
  ]
subnets        = [
    {
        name      = "webapp"
        self_link = (known after apply)
      },
    {
        name      = "db"
        self_link = (known after apply)
      },
  ]
vpc            = {
    name      = "dev"
    self_link = (known after apply)
  }
web_server     = [
    {
        name      = "webapp-server"
        self_link = (known after apply)
      },
  ]
```

## 3. Configuration for VPC setup with firewall rules, web server and Cloud SQL Instance

**Input III** example creates the following:

1. VPC named `dev-v2` without default routes
2. Two subnets:
   1. `webapp` with CIDR range set to 10.0.1.0/24
   2. `db` with CIDR range set to 10.0.2.0/24
3. Route `vpc-dev-route-public-access` to internet gateway for the VPC with tags `public` and `webapp`
4. Creates a firewall rule `allow-webapp-subnet-http` to allow `TCP` protocol on port `80` to `webapp` subnet
5. Creates a cloud sql instance `db-instance-{random_id}` with `db-g1-small` tier and `POSTGRES_15` database version
   1. Hosts the SQL instance with private IP and creates a connection to VPC using **VPC peering**
   2. Sets up a new database `webapp`
   3. Creates random user and password for the database
6. Creates a webapp compute instance `webapp-server` using `webapp` subnet as well as a public ip
   1. Executes a startup script to create .env file to connect to the Cloud SQL database

### Input III

```hcl
project_id = "csye6225-cloud-computing-dev"
region     = "us-east1"

vpc_name = "dev-v2"

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
    tags             = ["public", "webapp"]
  }
]

firewall_rules = [{
  name               = "allow-webapp-subnet-http"
  direction          = "INGRESS"
  action             = "ALLOW"
  target_tags        = ["webapp"]
  source_ranges      = ["0.0.0.0/0"]
  destination_ranges = ["10.0.1.0/24"]
  allowed = [{
    protocol = "tcp"
    ports    = ["80"]
  }]
}]

webapp_compute_instance = {
  name         = "webapp-server"
  machine_type = "e2-micro"
  tags         = ["webapp"]

  subnet_name = "webapp"
  zone        = "us-east1-b"

  # Compute Engine Instance Properties
  image     = "csye6225-webapp-image-1708745693"
  disk_type = "pd-balanced"
  disk_size = 100
}


database_sql_instance = {
  name   = "db-instance"
  region = "us-east1"
  tier   = "db-g1-small"

  deletion_protection = false
  availability_type   = "REGIONAL"
  disk_type           = "pd-ssd"
  disk_size           = 100
  database_version    = "POSTGRES_15"

  database_name       = "webapp"
  database_username   = "webapp"
  ip_configuration = {
    ipv4_enabled                                  = false
    require_ssl                                   = false
    ssl_mode                                      = "ENCRYPTED_ONLY"
    enable_private_path_for_google_cloud_services = true
  }

  private_access_config = {
    name          = "db-private-ip"
    address_type  = "INTERNAL"
    address       = null
    purpose       = "VPC_PEERING"
    prefix_length = 24
  }
}
```

### Output III

```hcl
database_instance = {
    database  = {
        name      = "webapp"
        self_link = (known after apply)
      }
    name      = (known after apply)
    region    = "us-east1"
    self_link = (known after apply)
  }
firewall_rules = [
    {
        name      = "allow-webapp-subnet-http"
        self_link = (known after apply)
      },
  ]
routes         = [
    {
        name      = "vpc-dev-route-public-access"
        self_link = (known after apply)
      },
  ]
subnets        = [
    {
        name      = "webapp"
        self_link = (known after apply)
      },
    {
        name      = "db"
        self_link = (known after apply)
      },
  ]
vpc            = {
    name      = "dev"
    self_link = (known after apply)
  }
web_server     = [
    {
        name      = "webapp-server"
        self_link = (known after apply)
      },
  ]
```
