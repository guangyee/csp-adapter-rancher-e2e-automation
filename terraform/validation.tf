output dns_validation{
  // hack since variable conditions don't work across variables. From https://github.com/hashicorp/terraform/issues/25609#issuecomment-1472119672
  value = null
  precondition {
    condition = var.dns_name == "" && var.zone_name == "" || var.dns_name != "" && var.zone_name != ""
    error_message = "zone_name and dns_name must both be set or both be empty"
  }
}
