data "aws_caller_identity" "default" {}

data "aws_region" "default" {}

# Define composite variables for resources
module "label" {
  source     = "git::https://github.com/cloudposse/terraform-terraform-label.git?ref=tags/0.1.0"
  namespace  = "${var.namespace}"
  name       = "${var.name}"
  stage      = "${var.stage}"
  delimiter  = "${var.delimiter}"
  attributes = "${var.attributes}"
  tags       = "${var.tags}"
}

resource "aws_iam_role" "default" {
  count              = "${var.enabled == "true" ? 1 : 0}"
  name               = "${module.label.id}"
  assume_role_policy = "${data.aws_iam_policy_document.role.json}"
}

data "aws_iam_policy_document" "role" {
  statement {
    sid = ""

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    effect = "Allow"
  }
}

resource "aws_iam_policy" "default" {
  count  = "${var.enabled == "true" ? 1 : 0}"
  name   = "${module.label.id}"
  path   = "/service-role/"
  policy = "${data.aws_iam_policy_document.permissions.json}"
}

data "aws_iam_policy_document" "permissions" {
  statement {
    sid = ""

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:GetAuthorizationToken",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:ListImages",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
      #"ecs:RunTask",
      "iam:PassRole",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "ssm:GetParameters",
    ]

    effect = "Allow"

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role_policy_attachment" "default" {
  count      = "${var.enabled == "true" ? 1 : 0}"
  policy_arn = "${aws_iam_policy.default.arn}"
  role       = "${aws_iam_role.default.id}"
}

resource "aws_codebuild_project" "default" {
  count         = "${var.enabled == "true" ? 1 : 0}"
  name          = "${module.label.id}"
  service_role  = "${aws_iam_role.default.arn}"
  badge_enabled = "${var.badge_enabled}"
  build_timeout = "${var.build_timeout}"

  artifacts {
    type = "${var.artifact_type}"
  }

  environment {
    compute_type    = "${var.build_compute_type}"
    image           = "${var.build_image}"
    type            = "LINUX_CONTAINER"
    privileged_mode = "${var.privileged_mode}"

    environment_variable = [{
      "name"  = "AWS_REGION"
      "value" = "${signum(length(var.aws_region)) == 1 ? var.aws_region : data.aws_region.default.name}"
    },
      {
        "name"  = "AWS_ACCOUNT_ID"
        "value" = "${signum(length(var.aws_account_id)) == 1 ? var.aws_account_id : data.aws_caller_identity.default.account_id}"
      },
      {
        "name"  = "IMAGE_REPO_NAME"
        "value" = "${signum(length(var.image_repo_name)) == 1 ? var.image_repo_name : "UNSET"}"
      },
      {
        "name"  = "IMAGE_TAG"
        "value" = "${signum(length(var.image_tag)) == 1 ? var.image_tag : "latest"}"
      },
      {
        "name"  = "STAGE"
        "value" = "${signum(length(var.stage)) == 1 ? var.stage : "UNSET"}"
      },
      {
        "name"  = "GITHUB_TOKEN"
        "value" = "${signum(length(var.github_token)) == 1 ? var.github_token : "UNSET"}"
      },
      "${var.environment_variables}",
    ]
  }

  source {
    buildspec = "${var.buildspec}"
    type      = "${var.source_type}"
    location  = "${var.source_location}"
  }

  tags = "${module.label.tags}"
}

resource "aws_codebuild_webhook" "webhook" {
  project_name = "${aws_codebuild_project.default.name}"
  branch_filter = "${var.webhook_branch_filter}"
}
