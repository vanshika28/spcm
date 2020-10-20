provider "aws"{
region="ap-south-1"
profile="Garg"
}

resource "aws_security_group" "security1tera" {
  name        = "security1tera"
  description = "Security for instance"
  vpc_id      = "vpc-68f0ed00"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web" {
  ami           = "ami-0ca845a6eb3903743"
  instance_type = "t2.micro"

key_name ="os1"


security_groups=["${aws_security_group.security1tera.name}"]



connection{
type="ssh"
user ="ec2-user"
private_key=file("C:/eautomation/key/os1.pem")
host=aws_instance.web.public_ip
}

  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd php -y",
          "sudo yum install git -y ",
        "sudo systemctl restart httpd",
       "sudo systemctl enable httpd"
      
    ]
  }
  tags = {
    Name = "Vgwebos1"
  }
}

resource "aws_ebs_volume" "e1" {
  availability_zone = aws_instance.web.availability_zone
  size              = 1

  tags = {
    Name = "H1"
  }

}

resource "aws_volume_attachment" "attach1" {
  device_name = "/dev/sdh"
  volume_id   = "${aws_ebs_volume.e1.id}"
  instance_id = "${aws_instance.web.id}"
 force_detach= true
}
output "myos_ip" {
  value = aws_instance.web.public_ip
}

resource "null_resource" "nullremote3"  {

depends_on = [
    aws_volume_attachment.attach1,
  ]

connection{
type="ssh"
user ="ec2-user"
private_key=file("C:/eautomation/key/os1.pem")
host=aws_instance.web.public_ip
}

  provisioner "remote-exec" {
    inline = [
       "sudo mkfs.ext4  /dev/xvdh",
      "sudo mount  /dev/xvdh  /var/www/html",
      "sudo rm -rf  /var/www/html/*",
      "sudo git clone  https://github.com/vanshika28/Html3.git /var/www/html/"

    ]
  }
}

resource "null_resource" "nulllocal2"  {
	provisioner "local-exec" {
	    command = "echo  ${aws_instance.web.public_ip} > publicip.txt"
  	}
}

resource "aws_s3_bucket" "nonu1" {
depends_on=[
	null_resource.nullremote3,
]
bucket="nonu1"
acl ="public-read"

provisioner "local-exec" {
    command = "git clone https://github.com/vanshika28/Web-Image.git  Desktop/Image/I35"
  }


}

resource "aws_s3_bucket_object" "vg-object" {
   bucket = aws_s3_bucket.nonu1.bucket
 key    = "vanshika1.png"
acl="public-read"
  source = "Desktop/Image/I35/vanshika1.png"

}


resource "aws_cloudfront_distribution" "s3cloudfront" {


  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${aws_s3_bucket.nonu1.bucket}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
viewer_protocol_policy = "allow-all"
        min_ttl = 0
        default_ttl = 3600
        max_ttl = 86400
    

  }



  is_ipv6_enabled     = true
  origin {
  
    domain_name = "${aws_s3_bucket.nonu1.bucket_regional_domain_name}"
    origin_id   = "${aws_s3_bucket.nonu1.bucket}"

custom_origin_config {
            http_port = 80
            https_port = 80
            origin_protocol_policy = "match-viewer"
            origin_ssl_protocols = ["TLSv1", "TLSv1.1", "TLSv1.2"]
        }

  }
 default_root_object = "index.html"
    enabled = true

  custom_error_response {
        error_caching_min_ttl = 3000
        error_code = 404
        response_code = 200
        response_page_path = "/index.html"
    }


  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Environment = "production"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
connection {
   type="ssh"
user ="ec2-user"
port=22
private_key=file("C:/eautomation/key/os1.pem")
host=aws_instance.web.public_ip
  }

provisioner "remote-exec" {
    inline = [
      "sudo -i << EOF",
                           "echo \"<img src='http://${self.domain_name}/${aws_s3_bucket_object.vg-object.key}' width='500' height='500'>\" >> /var/www/html/index.html",
"EOF",
    ]
  }
}
output "cloudfront_ip_addr" {
  value = aws_cloudfront_distribution.s3cloudfront.domain_name
}
