output "crawler_name" { value = aws_glue_crawler.processed.name }
output "database_name" { value = aws_glue_catalog_database.pipeline.name }
