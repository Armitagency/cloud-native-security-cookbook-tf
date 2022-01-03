module "encrypted_instance" {
  source        = "./instance"
  instance_name = var.instance_name
  subnet_id     = var.subnet_id
}
