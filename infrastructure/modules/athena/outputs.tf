output "workgroup_name" { value = aws_athena_workgroup.pipeline.name }
output "results_bucket_name" { value = aws_s3_bucket.athena_results.bucket }
