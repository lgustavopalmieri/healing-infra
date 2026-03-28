###############################################################################
# DNS Records — Route53 alias records pointing to the ALB
#
# The ALB is created by the AWS Load Balancer Controller inside the cluster.
# Since the ALB is dynamic (created by the controller, not by Terraform),
# we use a data source to look it up after the controller is deployed.
###############################################################################

data "aws_lb" "ingress" {
  count = var.zone_id != "" ? 1 : 0

  tags = {
    "elbv2.k8s.aws/cluster" = var.cluster_name
  }

  depends_on = [helm_release.aws_load_balancer_controller]
}

resource "aws_route53_record" "app" {
  for_each = var.zone_id != "" ? toset(var.dns_records) : toset([])

  zone_id = var.zone_id
  name    = each.value
  type    = "A"

  alias {
    name                   = data.aws_lb.ingress[0].dns_name
    zone_id                = data.aws_lb.ingress[0].zone_id
    evaluate_target_health = true
  }
}
