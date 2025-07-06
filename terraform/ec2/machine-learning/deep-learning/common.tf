# locals {
#   common_tags = {
#     Project     = var.project_name
#     Environment = "dev"
#     ManagedBy   = "terraform"
#     Owner       = "otto"
#   }
# }


# TODO: Get this working with a module
module "common_tags" {
  source = "git::https://github.com/oquaglio/terraform-core-modules.git//modules/common_tags?ref=main"

  # Optional overrides:
  project_name = var.project_name
  environment  = "dev"
}
