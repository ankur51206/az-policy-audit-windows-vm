provider "azurerm" {
  features {}
}

resource "azurerm_policy_definition" "policy" {
  name         = "auditwinmachine"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Audit Windows machines that are not joined to the specified domain"

  metadata = <<METADATA
    {
    "category": "General"
    }
METADATA


  parameters = <<PARAMETERS
{
	"IncludeArcMachines": {
		"type": "String",
		"metadata": {
			"displayName": "Include Arc connected servers",
			"description": "By selecting this option, you agree to be charged monthly per Arc connected machine.",
			"portalReview": "true"
		},
		"allowedValues": [
			"true",
			"false"
		],
		"defaultValue": "false"
	},
	"DomainName": {
		"type": "String",
		"metadata": {
			"displayName": "Domain Name (FQDN)",
			"description": "The fully qualified domain name (FQDN) that the Windows machines should be joined to"
		},
		"defaultValue": "domainname1.com"

	}
}
PARAMETERS

  policy_rule = <<POLICY_RULE
    {
     "if": {
        "anyOf": [
          {
            "allOf": [
              {
                "field": "type",
                "equals": "Microsoft.Compute/virtualMachines"
              },
              {
                "anyOf": [
                  {
                    "field": "Microsoft.Compute/imagePublisher",
                    "in": [
                      "esri",
                      "incredibuild",
                      "MicrosoftDynamicsAX",
                      "MicrosoftSharepoint",
                      "MicrosoftVisualStudio",
                      "MicrosoftWindowsDesktop",
                      "MicrosoftWindowsServerHPCPack"
                    ]
                  },
                  {
                    "allOf": [
                      {
                        "field": "Microsoft.Compute/imagePublisher",
                        "equals": "MicrosoftWindowsServer"
                      },
                      {
                        "field": "Microsoft.Compute/imageSKU",
                        "notLike": "2008*"
                      }
                    ]
                  },
                  {
                    "allOf": [
                      {
                        "field": "Microsoft.Compute/imagePublisher",
                        "equals": "MicrosoftSQLServer"
                      },
                      {
                        "field": "Microsoft.Compute/imageOffer",
                        "notLike": "SQL2008*"
                      }
                    ]
                  },
                  {
                    "allOf": [
                      {
                        "field": "Microsoft.Compute/imagePublisher",
                        "equals": "microsoft-dsvm"
                      },
                      {
                        "field": "Microsoft.Compute/imageOffer",
                        "like": "dsvm-win*"
                      }
                    ]
                  },
                  {
                    "allOf": [
                      {
                        "field": "Microsoft.Compute/imagePublisher",
                        "equals": "microsoft-ads"
                      },
                      {
                        "field": "Microsoft.Compute/imageOffer",
                        "in": [
                          "standard-data-science-vm",
                          "windows-data-science-vm"
                        ]
                      }
                    ]
                  },
                  {
                    "allOf": [
                      {
                        "field": "Microsoft.Compute/imagePublisher",
                        "equals": "batch"
                      },
                      {
                        "field": "Microsoft.Compute/imageOffer",
                        "equals": "rendering-windows2016"
                      }
                    ]
                  },
                  {
                    "allOf": [
                      {
                        "field": "Microsoft.Compute/imagePublisher",
                        "equals": "center-for-internet-security-inc"
                      },
                      {
                        "field": "Microsoft.Compute/imageOffer",
                        "like": "cis-windows-server-201*"
                      }
                    ]
                  },
                  {
                    "allOf": [
                      {
                        "field": "Microsoft.Compute/imagePublisher",
                        "equals": "pivotal"
                      },
                      {
                        "field": "Microsoft.Compute/imageOffer",
                        "like": "bosh-windows-server*"
                      }
                    ]
                  },
                  {
                    "allOf": [
                      {
                        "field": "Microsoft.Compute/imagePublisher",
                        "equals": "cloud-infrastructure-services"
                      },
                      {
                        "field": "Microsoft.Compute/imageOffer",
                        "like": "ad*"
                      }
                    ]
                  },
                  {
                    "allOf": [
                      {
                        "anyOf": [
                          {
                            "field": "Microsoft.Compute/virtualMachines/osProfile.windowsConfiguration",
                            "exists": "true"
                          },
                          {
                            "field": "Microsoft.Compute/virtualMachines/storageProfile.osDisk.osType",
                            "like": "Windows*"
                          }
                        ]
                      },
                      {
                        "anyOf": [
                          {
                            "field": "Microsoft.Compute/imageSKU",
                            "exists": "false"
                          },
                          {
                            "allOf": [
                              {
                                "field": "Microsoft.Compute/imageSKU",
                                "notLike": "2008*"
                              },
                              {
                                "field": "Microsoft.Compute/imageOffer",
                                "notLike": "SQL2008*"
                              }
                            ]
                          }
                        ]
                      }
                    ]
                  }
                ]
              }
            ]
          },
          {
            "allOf": [
              {
                "value": "[parameters('IncludeArcMachines')]",
                "equals": "true"
              },
              {
                "anyOf": [
                  {
                    "allOf": [
                      {
                        "field": "type",
                        "equals": "Microsoft.HybridCompute/machines"
                      },
                      {
                        "field": "Microsoft.HybridCompute/imageOffer",
                        "like": "windows*"
                      }
                    ]
                  },
                  {
                    "allOf": [
                      {
                        "field": "type",
                        "equals": "Microsoft.ConnectedVMwarevSphere/virtualMachines"
                      },
                      {
                        "field": "Microsoft.ConnectedVMwarevSphere/virtualMachines/osProfile.osType",
                        "like": "windows*"
                      }
                    ]
                  }
                ]
              }
            ]
          }
        ]
      },
      "then": {
        "effect": "auditIfNotExists",
        "details": {
          "type": "Microsoft.GuestConfiguration/guestConfigurationAssignments",
          "name": "WindowsDomainMembership",
          "existenceCondition": {
            "allOf": [
              {
                "field": "Microsoft.GuestConfiguration/guestConfigurationAssignments/complianceStatus",
                "equals": "Compliant"
              },
              {
                "field": "Microsoft.GuestConfiguration/guestConfigurationAssignments/parameterHash",
                "equals": "[base64(concat('[DomainMembership]WindowsDomainMembership;DomainName', '=', parameters('DomainName')))]"
              }
            ]
          }
        }
      }
    }
POLICY_RULE

}


# Policy Assignment

data "azurerm_subscription" "current" {}

resource "azurerm_subscription_policy_assignment" "assign_policy" {
  name                 = "windows-policy-assignment"
  policy_definition_id = azurerm_policy_definition.policy.id
  subscription_id      = data.azurerm_subscription.current.id
}
