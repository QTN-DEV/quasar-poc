module "cloudtrail" {
  source      = "../../modules/cloudtrail"
  bucket_name = "wazuh-production-cloudtrail"
}

module "vpcflow" {
  source      = "../../modules/vpcflow"
  bucket_name = "wazuh-production-vpcflow"
}