data "aws_instances" "eks_prod_nodes" {
  filter {
    name   = "tag:kubernetes.io/cluster/${var.cluster_name}"
    values = ["owned"]
  }
}

locals {
  instance_ids = data.aws_instances.eks_prod_nodes.ids
}

resource "aws_cloudwatch_dashboard" "prod_eks_node_instances" {
  dashboard_name = "prod-eks-node-instances"
  dashboard_body = jsonencode({
    start          = "-PT1H"
    periodOverride = "inherit"

    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "CPU Utilization (EKS Node Instances)"
          view   = "timeSeries"
          region = var.region
          stat   = "Average"
          period = 300
          yAxis  = { left = { min = 0, max = 100, label = "%" } }
          metrics = [
            for id in local.instance_ids : [
              "AWS/EC2",
              "CPUUtilization",
              "InstanceId",
              id
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "Status Check Failures (EKS Node Instances)"
          view   = "timeSeries"
          region = var.region
          stat   = "Average"
          period = 300
          metrics = [
            for id in local.instance_ids : [
              "AWS/EC2",
              "StatusCheckFailed_Instance",
              "InstanceId",
              id
            ]
          ]
        }
      }
    ]
  })
}

resource "aws_sns_topic" "eks_alerts" {
  name = "eks-node-alerts-prod"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.eks_alerts.arn
  protocol  = "email"
  endpoint  = "sanyzkypedro@gmail.com"
}

# Alarma CPU alta  threshold = 80%
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  for_each = toset(local.instance_ids)

  alarm_name          = "eks-node-${each.key}-high-cpu"
  alarm_description   = "EKS node ${each.key} CPU > 80% por 10 min"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  statistic           = "Average"
  period              = 300
  threshold           = 80 # ← umbral fijo

  dimensions = {
    InstanceId = each.key
  }

  alarm_actions = [aws_sns_topic.eks_alerts.arn]
  ok_actions    = [aws_sns_topic.eks_alerts.arn]
}

# Alarma Status Check Failed
resource "aws_cloudwatch_metric_alarm" "status_check_failed" {
  for_each = toset(local.instance_ids)

  alarm_name          = "eks-node-${each.key}-status-check-failed"
  alarm_description   = "EKS node ${each.key} falla status check"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "StatusCheckFailed_Instance"
  namespace           = "AWS/EC2"
  statistic           = "Maximum"
  period              = 300
  threshold           = 1

  dimensions = {
    InstanceId = each.key
  }

  alarm_actions = [aws_sns_topic.eks_alerts.arn]
  ok_actions    = [aws_sns_topic.eks_alerts.arn]
}
