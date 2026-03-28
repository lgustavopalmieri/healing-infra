variable "ec_api_key" {
  description = "API Key da Elastic Cloud (gere em https://cloud.elastic.co/account/keys)"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "Região do deployment na Elastic Cloud (ex: us-east-1, sa-east-1, eu-west-1)"
  type        = string
  default     = "us-east-1"
}

variable "deployment_name" {
  description = "Nome do deployment"
  type        = string
  default     = "my-elasticsearch"
}

variable "deployment_template_id" {
  description = "Template ID do deployment (varia por região e provider)"
  type        = string
  default     = "aws-general-purpose"
}

variable "elasticsearch_version_regex" {
  description = "Regex para selecionar a versão do Elasticsearch (ex: \"9\\..*\" para sempre a última 9.x)"
  type        = string
  default     = "9\\..*"
}

variable "elasticsearch_size" {
  description = "Tamanho da memória do hot tier (ex: 1g, 2g, 4g, 8g)"
  type        = string
  default     = "4g"

  validation {
    condition     = contains(["1g", "2g", "4g", "8g", "16g", "32g", "64g"], var.elasticsearch_size)
    error_message = "Tamanho inválido. Use: 1g, 2g, 4g, 8g, 16g, 32g ou 64g."
  }
}

variable "elasticsearch_zone_count" {
  description = "Número de zonas de disponibilidade (1, 2 ou 3)"
  type        = number
  default     = 1

  validation {
    condition     = contains([1, 2, 3], var.elasticsearch_zone_count)
    error_message = "Zone count deve ser 1, 2 ou 3."
  }
}

variable "kibana_size" {
  description = "Tamanho da memória do Kibana (ex: 1g, 2g)"
  type        = string
  default     = "1g"

  validation {
    condition     = contains(["1g", "2g", "4g", "8g"], var.kibana_size)
    error_message = "Tamanho inválido para Kibana. Use: 1g, 2g, 4g ou 8g."
  }
}

variable "app_user_name" {
  description = "Nome do usuário de aplicação no Elasticsearch"
  type        = string
  default     = "app_user"
}

variable "app_user_password" {
  description = "Senha do usuário de aplicação (mínimo 6 caracteres)"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.app_user_password) >= 6
    error_message = "A senha deve ter pelo menos 6 caracteres."
  }
}

variable "app_user_password_version" {
  description = "Incremente para forçar a troca de senha do app_user sem recriar o recurso"
  type        = number
  default     = 1
}

variable "app_indices" {
  description = "Padrões de índices que o app_user pode acessar (ex: [\"app-*\", \"logs-*\"]). Use [\"*\"] para todos."
  type        = list(string)
  default     = ["*"]
}
