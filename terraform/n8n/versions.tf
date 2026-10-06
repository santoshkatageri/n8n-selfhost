terraform {
  required_version = ">= 1.5.0, < 2.0.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "= 9.8.0"
    }
  }
}
# Resource Manager supplies authentication and stores cloud state.
provider "oci" {
  region = "us-ashburn-1"
}
