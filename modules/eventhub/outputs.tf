output "namespace_name" {
  value = azurerm_eventhub_namespace.namespace.name
}

output "keys" {
  description = "Map of hubs with keys => primary_key mapping."
  sensitive   = true
  value = { for k in azurerm_eventhub_authorization_rule.authorization_rule : k.name => {
    eventHub = k.eventhub_name
    name     = k.name
    secret   = k.primary_key
    }
  }
}
