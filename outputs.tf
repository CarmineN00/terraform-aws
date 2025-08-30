
output "instances_hostname_vpc1" {
  description = "Private DNS name of VPC1's EC2 instances."
  value       = {for id, instance in aws_instance.vpc1_istances : "istance-${id+1}" => instance.private_dns}
}
output "instances_hostname_vpc2" {
  description = "Private DNS name of VPC2's EC2 instances."
  value       = {for id, instance in aws_instance.vpc2_istances : "istance-${id+1}" => instance.private_dns}
}
