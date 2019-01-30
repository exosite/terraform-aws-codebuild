output "project_name" {
  description = "Project name"
  value       = "${join("", aws_codebuild_project.default.*.name)}"
}

output "project_id" {
  description = "Project ID"
  value       = "${join("", aws_codebuild_project.default.*.id)}"
}

output "role_arn" {
  description = "IAM Role ARN"
  value       = "${join("", aws_iam_role.default.*.id)}"
}

output "badge_url" {
  description = "The URL of the build badge when badge_enabled is enabled"
  value       = "${join("", aws_codebuild_project.default.*.badge_url)}"
}
