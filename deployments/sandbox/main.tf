locals {
  name_suffix = "sand"
  location    = "centralus"
}

resource "azurerm_resource_group" "rg" {
  name     = "eventhub-sand"
  location = local.location
}

module "eventhub" {
  source              = "../../modules/eventhub"
  name_suffix         = local.name_suffix
  location            = local.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "standard"
  capacity            = 1

  eventhubs = [{
    name              = "evh-wpb"
    partitions        = 2
    message_retention = 1
    consumers         = []
    keys = [
      {
        name   = "send"
        listen = false
        send   = true
      },
      {
        name   = "listen"
        listen = true
        send   = false
      }
    ]
  }]
}
