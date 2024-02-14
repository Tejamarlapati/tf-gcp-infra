# Installation

## Install and setup gCloud CLI

To install and set up the Google Cloud SDK (gCloud CLI), follow the instructions in the [official documentation](https://cloud.google.com/sdk/docs/install). Ensure that you have the necessary permissions and authentication set up to interact with your Google Cloud Platform projects.

## Install Terraform

To install Terraform, follow these general steps:

1. Download Terraform: Visit the [Terraform website](https://developer.hashicorp.com/terraform/install) and download the appropriate package for your operating system.
2. Follow the installation instructions as specified.
3. Verify Installation: Open a terminal or command prompt and run terraform -version to ensure Terraform has been installed correctly.

        $ terraform -version

        Terraform v1.7.3
        on darwin_arm64
        + provider registry.terraform.io/hashicorp/google v5.15.0

## Setup Terraform in repo

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
