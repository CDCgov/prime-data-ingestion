locals {
  function_apps = {
    default : { runtime = "python" },
    python : { runtime = "python" },
    java : { runtime = "java" },
    infra : { runtime = "python" },
  }
}


module "pdi_function_app" {
  for_each = local.function_apps
  source   = "../common/function_app"

  primary = {
    name                       = replace("${var.resource_prefix}-${each.key}-functionapp", "-default-", "-")
    location                   = var.location
    resource_group_name        = var.resource_group_name
    app_service_plan_id        = var.app_service_plan
    storage_account_name       = var.sa_functionapps.name
    storage_account_access_key = var.sa_functionapps.primary_access_key
    environment                = var.environment
    subnet_id                  = var.cdc_app_subnet_id
    application_key_vault_id   = var.application_key_vault_id
  }

  app_settings = {
    WEBSITE_DNS_SERVER = "168.63.129.16"

    # App Insights
    PRIVATE_KEY                           = "@Microsoft.KeyVault(SecretUri=https://${var.resource_prefix}-app-kv.vault.azure.net/secrets/PrivateKey)"
    PRIVATE_KEY_PASSWORD                  = "@Microsoft.KeyVault(SecretUri=https://${var.resource_prefix}-app-kv.vault.azure.net/secrets/PrivateKeyPassword)"
    AZURE_STORAGE_CONTAINER_NAME          = "bronze"
    APPINSIGHTS_INSTRUMENTATIONKEY        = var.ai_instrumentation_key
    APPLICATIONINSIGHTS_CONNECTION_STRING = var.ai_connection_string
    BUILD_FLAGS                           = "UseExpressBuild"
    FUNCTIONS_WORKER_RUNTIME              = each.value.runtime
    SCM_DO_BUILD_DURING_DEPLOYMENT        = true
    VDHSFTPHostname                       = "vdhsftp.vdh.virginia.gov"
    VDHSFTPPassword                       = "@Microsoft.KeyVault(SecretUri=https://${var.resource_prefix}-app-kv.vault.azure.net/secrets/VDHSFTPPassword)"
    VDHSFTPUsername                       = "USDS_CDC"
    XDG_CACHE_HOME                        = "/tmp/.cache"
    WEBSITE_RUN_FROM_PACKAGE              = 1
    DATA_STORAGE_ACCOUNT                  = var.sa_data_name
  }
}