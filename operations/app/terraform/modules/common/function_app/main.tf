resource "azurerm_function_app" "pdi" {
  name                       = var.primary.name
  location                   = var.primary.location
  resource_group_name        = var.primary.resource_group_name
  app_service_plan_id        = var.primary.app_service_plan_id
  https_only                 = true
  os_type                    = "linux"
  version                    = var.primary.version
  enable_builtin_logging     = false
  storage_account_name       = var.primary.storage_account_name
  storage_account_access_key = var.primary.storage_account_access_key

  app_settings = var.app_settings

  site_config {
    ftps_state                = "Disabled"
    use_32_bit_worker_process = false
    vnet_route_all_enabled    = true
    always_on                 = var.primary.always_on
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = var.primary.environment
    managed-by  = "terraform"
  }

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "azurerm_app_service_virtual_network_swift_connection" "pdi" {
  app_service_id = azurerm_function_app.pdi.id
  subnet_id      = var.primary.subnet_id
}

resource "azurerm_key_vault_access_policy" "pdi" {
  key_vault_id = var.primary.application_key_vault_id
  tenant_id    = azurerm_function_app.pdi.identity.0.tenant_id
  object_id    = azurerm_function_app.pdi.identity.0.principal_id

  secret_permissions = [
    "Get",
  ]
}

resource "azurerm_function_app_slot" "blue" {
  name                       = "blue"
  location                   = var.primary.location
  resource_group_name        = var.primary.resource_group_name
  app_service_plan_id        = var.primary.app_service_plan_id
  https_only                 = true
  os_type                    = "linux"
  version                    = var.primary.version
  enable_builtin_logging     = false
  function_app_name          = azurerm_function_app.pdi.name
  storage_account_name       = var.primary.storage_account_name
  storage_account_access_key = var.primary.storage_account_access_key

  app_settings = var.app_settings

  site_config {
    ftps_state                = "Disabled"
    use_32_bit_worker_process = false
    vnet_route_all_enabled    = true
    auto_swap_slot_name       = "production"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = var.primary.environment
    managed-by  = "terraform"
  }

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "time_sleep" "wait_pdi_function_app" {
  create_duration = "2m"

  depends_on = [azurerm_function_app.pdi]
  triggers = {
    function_app = azurerm_function_app.pdi.identity.0.principal_id
  }
}

locals {
  pdi_publish_command = <<EOF
      az functionapp deployment source config-zip --resource-group ${var.primary.resource_group_name} \
      --name ${azurerm_function_app.pdi.name} --src ${data.archive_file.pdi_function_app.output_path} \
      --build-remote false --timeout 600
    EOF
}

data "archive_file" "pdi_function_app" {
  type        = "zip"
  source_dir  = var.primary.functions_path
  output_path = "function-app-pdi.zip"

  excludes = [
    ".venv",
    ".vscode",
    "local.settings.json",
    "getting_started.md",
    "README.md",
    ".gitignore"
  ]
}

resource "null_resource" "pdi_function_app_publish" {
  provisioner "local-exec" {
    command = local.pdi_publish_command
  }
  depends_on = [
    local.pdi_publish_command,
    azurerm_function_app.pdi,
    time_sleep.wait_pdi_function_app
  ]
  triggers = {
    input_json           = filemd5(data.archive_file.pdi_function_app.output_path)
    publish_code_command = local.pdi_publish_command
  }
}
