locals {
  consumers = { for hc in flatten([for h in var.eventhubs :
    [for c in h.consumers : {
      hub  = h.name
      name = c
  }]]) : format("%s.%s", hc.hub, hc.name) => hc }

  keys = { for hk in flatten([for h in var.eventhubs :
    [for k in h.keys : {
      hub = h.name
      key = k
  }]]) : format("%s.%s", hk.hub, hk.key.name) => hk }

  hubs = { for h in var.eventhubs : h.name => h }

  authorization_rules = { for a in var.authorization_rules : a.name => a }
}

resource "azurerm_eventhub_namespace" "namespace" {
  name                = "evhns-${var.name_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  capacity            = var.capacity

  auto_inflate_enabled     = var.auto_inflate != null ? var.auto_inflate.enabled : null
  maximum_throughput_units = var.auto_inflate != null ? var.auto_inflate.maximum_throughput_units : null

  dynamic "network_rulesets" {
    for_each = var.network_rules != null ? ["true"] : []
    content {
      default_action = "Deny"
      dynamic "ip_rule" {
        for_each = var.network_rules.ip_rules
        iterator = iprule
        content {
          ip_mask = iprule.value
        }
      }
      dynamic "virtual_network_rule" {
        for_each = var.network_rules.subnet_ids
        iterator = subnet
        content {
          subnet_id = subnet.value
        }
      }
    }
  }
}

resource "azurerm_eventhub_namespace_authorization_rule" "namespace_authorization" {
  for_each = local.authorization_rules

  name                = each.key
  namespace_name      = azurerm_eventhub_namespace.namespace.name
  resource_group_name = var.resource_group_name
  listen              = each.value.listen
  send                = each.value.send
  manage              = each.value.manage
}

resource "azurerm_eventhub" "eventhub" {
  for_each = local.hubs

  name                = each.key
  namespace_name      = azurerm_eventhub_namespace.namespace.name
  resource_group_name = var.resource_group_name
  partition_count     = each.value.partitions
  message_retention   = each.value.message_retention
}

resource "azurerm_eventhub_consumer_group" "consumer_group" {
  for_each = local.consumers

  name                = each.value.name
  namespace_name      = azurerm_eventhub_namespace.namespace.name
  eventhub_name       = each.value.hub
  resource_group_name = var.resource_group_name

  depends_on = [
    azurerm_eventhub.eventhub
  ]
}

resource "azurerm_eventhub_authorization_rule" "authorization_rule" {
  for_each = local.keys

  name                = format("%s-%s", each.value.hub, each.value.key.name)
  namespace_name      = azurerm_eventhub_namespace.namespace.name
  eventhub_name       = each.value.hub
  resource_group_name = var.resource_group_name
  listen              = each.value.key.listen
  send                = each.value.key.send
  manage              = false

  depends_on = [
    azurerm_eventhub.eventhub
  ]
}
