$location = "francecentral"
$resourceGroupName = "mate-azure-task-16"
$virtualNetworkName = "todoapp"
$vnetAddressPrefix = "10.20.30.0/24"
$webSubnetName = "webservers"
$webSubnetIpRange = "10.20.30.0/26"
$dbSubnetName = "database"
$dbSubnetIpRange = "10.20.30.64/26"
$mngSubnetName = "management"
$mngSubnetIpRange = "10.20.30.128/26"

Write-Host "Creating a resource group $resourceGroupName ..."
New-AzResourceGroup `
    -Name $resourceGroupName `
    -Location $location

$nsg_rule_inbound = New-AzNetworkSecurityRuleConfig `
    -Name all-inbound-rule `
    -Description "Allow all subnets Inbound" `
    -Access Allow `
    -Protocol * `
    -Direction Inbound `
    -Priority 150 `
    -SourceAddressPrefix $vnetAddressPrefix `
    -SourcePortRange * `
    -DestinationAddressPrefix $vnetAddressPrefix `
    -DestinationPortRange *

$nsg_rule_outbound = New-AzNetworkSecurityRuleConfig `
    -Name all-outbound-rule `
    -Description "Allow all subnets Outbound" `
    -Access Allow `
    -Protocol * `
    -Direction Outbound `
    -Priority 150 `
    -SourceAddressPrefix $vnetAddressPrefix `
    -SourcePortRange * `
    -DestinationAddressPrefix $vnetAddressPrefix `
    -DestinationPortRange *

Write-Host "Creating webSubnet network security group..."
$web_nsg_http_https_rule = New-AzNetworkSecurityRuleConfig -Name web-http-https-rule `
    -Description "Allow HTTP and HTTPS" `
    -Access Allow `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 100 `
    -SourceAddressPrefix * `
    -SourcePortRange * `
    -DestinationAddressPrefix $webSubnetIpRange `
    -DestinationPortRange 80, 443

$web_nsg = New-AzNetworkSecurityGroup `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -Name $webSubnetName `
    -SecurityRules $web_nsg_http_https_rule, $nsg_rule_inbound, $nsg_rule_outbound

Write-Host "Creating mngSubnet network security group..."
$mng_nsg_rule_ssh = New-AzNetworkSecurityRuleConfig `
    -Name ssh-rule `
    -Description "Allow SSH" `
    -Access Allow `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 101 `
    -SourceAddressPrefix * `
    -SourcePortRange * `
    -DestinationAddressPrefix $mngSubnetIpRange `
    -DestinationPortRange 22

$mng_nsg = New-AzNetworkSecurityGroup `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -Name $mngSubnetName `
    -SecurityRules $mng_nsg_rule_ssh, $nsg_rule_inbound, $nsg_rule_outbound

Write-Host "Creating dbSubnet network security group..."
$db_nsg_rule = New-AzNetworkSecurityRuleConfig `
    -Name sql-from-web `
    -Description "Allow SQL from virtual netowrk" `
    -Access Allow `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 102 `
    -SourceAddressPrefix $vnetAddressPrefix `
    -SourcePortRange * `
    -DestinationAddressPrefix $dbSubnetIpRange `
    -DestinationPortRange 5432 # PostgreSQL

$db_nsg = New-AzNetworkSecurityGroup `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -Name $dbSubnetName `
    -SecurityRules $db_nsg_rule

Write-Host "Creating a virtual network ..."
$webSubnet = New-AzVirtualNetworkSubnetConfig `
    -Name $webSubnetName `
    -AddressPrefix $webSubnetIpRange `
    -NetworkSecurityGroup $web_nsg

$dbSubnet = New-AzVirtualNetworkSubnetConfig `
    -Name $dbSubnetName `
    -AddressPrefix $dbSubnetIpRange `
    -NetworkSecurityGroup $db_nsg

$mngSubnet = New-AzVirtualNetworkSubnetConfig `
    -Name $mngSubnetName `
    -AddressPrefix $mngSubnetIpRange `
    -NetworkSecurityGroup $mng_nsg

New-AzVirtualNetwork `
    -Name $virtualNetworkName `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -AddressPrefix $vnetAddressPrefix `
    -Subnet $webSubnet, $dbSubnet, $mngSubnet
