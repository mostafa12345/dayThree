variable "bucket_name" {}
variable "region" {}
variable "Environment" {}


terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = var.region
}

resource "aws_s3_bucket" "s3_bucket" {

   bucket = var.bucket_name
   force_destroy = true
   tags = {
    Name        = "bucket"
    Environment = "var.Environment"
  }

}

resource "aws_s3_object" "s3_directory_logs" {
  bucket = aws_s3_bucket.s3_bucket.bucket
  key    = "logs/"
  content_type = "application/x-directory"
}

resource "aws_s3_object" "s3_directory_incoming" {
  bucket = aws_s3_bucket.s3_bucket.bucket
  key    = "incoming/"
  content_type = "application/x-directory"
}

resource "aws_s3_object" "s3_directory_outgoing" {
  bucket = aws_s3_bucket.s3_bucket.bucket
  key    = "outgoing/"
  content_type = "application/x-directory"
}


resource "aws_s3_bucket_lifecycle_configuration" "logs-bucket-config" {
  bucket = aws_s3_bucket.s3_bucket.id

  rule {
    id = "log"

    filter {
        prefix = "logs/"
      }

   status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    transition {
      days          = 180
      storage_class = "DEEP_ARCHIVE"
    }
    expiration {
      days = 365
    }

  }

  rule {
    id = "incoming"

    filter {
        prefix = "incoming/"

        and {
        object_size_greater_than = 1048576     # 1 MB in bytes
        object_size_less_than    = 1073741824  # 1 GB in bytes
      }
    } 

   status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }


  }

  rule {
    id = "outgoing"

    filter {
        and {
        prefix = "outgoing/"
     
        tags = {
          notDeepArchive = "true" 
        }
     }
   }
   status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }


  }
}
