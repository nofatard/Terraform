provider "aws" {
  region  = "us-east-1"
   access_key = "??"
  secret_key = "??"
}

resource "aws_instance" "my-web" {
  ami           = "ami-0947d2ba12ee1ff75"
  instance_type = "t2.micro"

  tags = {
    Name = "webserver"
  }

  resource "aws_vpc" "my-vpc" {
  cidr_block = "10.0.0.0/16"
    tags = {
    Name = "terra-vpc"
  }

  resource "aws_subnet" "sub-1" {
  vpc_id     = aws_vpc.my-vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "sub-pub"
  }

}
}



# resource "<provider>_<resource_type>" "name"
#    config option....
#    key = "value"
#    key2 = "another value"
# }    
