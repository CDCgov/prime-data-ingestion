output "pdi_function_app" {
  value = azurerm_function_app.pdi
}

output "pdi_function_app_uuid" {
  value = azurerm_function_app.pdi.identity[0].principal_id
}

output "infrastructure_function_app_id" {
  value = module.pdi_function_app["infra"].submodule_function_app.id
}

output "infrastructure_function_app_uuid" {
  value = module.pdi_function_app["infra"].submodule_function_app.identity[0].principal_id
}

output "java_function_app_id" {
  value = module.pdi_function_app["java"].submodule_function_app.id
}

output "java_function_app_uuid" {
  value = module.pdi_function_app["java"].submodule_function_app.identity[0].principal_id
}

output "python_function_app_id" {
  value = module.pdi_function_app["python"].submodule_function_app.id
}

output "python_function_app_uuid" {
  value = module.pdi_function_app["python"].submodule_function_app.identity[0].principal_id
}
