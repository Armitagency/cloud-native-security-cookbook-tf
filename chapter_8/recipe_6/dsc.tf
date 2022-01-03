locals {
  custom_data = <<CONTENT
wget ${join("/", [
  "https://github.com/microsoft/omi/releases/download",
  "v1.6.8-1/omi-1.6.8-1.ssl_100.ulinux.x64.deb"
)}
dpkg -i ./omi-1.6.8-1.ssl_100.ulinux.x64.deb

wget ${join("/", [
  "https://github.com/microsoft/PowerShell-DSC-for-Linux",
  "releases/download/v1.2.1-0/dsc-1.2.1-0.ssl_100.x64.deb"
)}
dpkg -i ./dsc-1.2.1-0.ssl_100.x64.deb

${join(" ", [
  "/opt/microsoft/dsc/Scripts/Register.py",
  azurerm_automation_account.this.dsc_primary_access_key,
  azurerm_automation_account.this.dsc_server_endpoint,
  azurerm_automation_dsc_configuration.example.name
])}
CONTENT
}

resource "azurerm_automation_module" "nx" {
  name                    = "nx"
  resource_group_name     = azurerm_resource_group.management.name
  automation_account_name = azurerm_automation_account.this.name

  module_link {
    uri = "https://www.powershellgallery.com/api/v2/package/nx/1.0"
  }
}

resource "azurerm_automation_dsc_configuration" "example" {
  name                    = "LinuxConfig"
  resource_group_name     = azurerm_resource_group.management.name
  location                = azurerm_resource_group.management.location
  automation_account_name = azurerm_automation_account.this.name
  content_embedded        = <<CONTENT
Configuration LinuxConfig
{
    Import-DscResource -ModuleName 'nx'

    Node IsPresent
    {
	    nxPackage apache2
	    {
        Name              = 'apache2'
        Ensure            = 'Present'
        PackageManager    = 'Apt'
      }
    }

    Node IsNotPresent
    {
	    nxPackage apache2
	    {
        Name              = 'apache2'
        Ensure            = 'Absent'
      }
    }
}
CONTENT

  depends_on = [
    azurerm_automation_module.nx
  ]
}
