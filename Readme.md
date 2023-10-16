# Azure DevOps Backup

## Description

This repository will, using CI/CD, backup all Azure DevOps projects to a storage account located in Azure.

All the resources are deployed as code using Bicep.

## Prerequisites

- Azure DevOps organization
- Azure subscription
- Service Connection with contributor permission

## Getting Started

1. Fork this repository
2. Create a new Azure DevOps project
3. Create a new Service Connection in Azure DevOps
4. By running the Pester tests you will verify which configuration files you have to modify to get this working.
