terraform {
  backend "s3" {
    bucket = "your-tf-state-bucket"
    key    = "url-shortener/terraform.tfstate"
    region = "us-west-2"
  }
}