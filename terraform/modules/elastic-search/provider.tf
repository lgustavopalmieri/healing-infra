provider "ec" {
  apikey = var.ec_api_key
}

provider "elasticstack" {
  elasticsearch {
    endpoints = [ec_deployment.this.elasticsearch.https_endpoint]
    username  = ec_deployment.this.elasticsearch_username
    password  = ec_deployment.this.elasticsearch_password
  }
}
