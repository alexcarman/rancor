# Configure the VMware vSphere Provider, leave this alone.
provider "vsphere" {
   user           = "${var.vsphere_user}"
   password       = "${var.vsphere_password}"
   vsphere_server = "${var.vsphere_endpoint}"
   allow_unverified_ssl = true
}

data "vsphere_datacenter" "dc" {
  name = "${var.vsphere_datacenter}"
}

data "vsphere_datastore" "datastore" {
  name          = "${var.vsphere_datastore}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_resource_pool" "pool" {
  name          = "${var.vsphere_resource_pool}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "network" {
  name          = "${var.vsphere_network}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_virtual_machine" "template" {
  name          = "${var.vsphere_virtual_template}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

# Create a virtual machine within the defined resource pool.
resource "vsphere_virtual_machine" "masters" {
   count = 3
   name = "${var.vsphere_vm_name_prefix}${substr(var.char_array, count.index, 1)}l"
   resource_pool_id = "${data.vsphere_resource_pool.pool.id}"
   datastore_id     = "${data.vsphere_datastore.datastore.id}"
   num_cpus = "${var.vsphere_vm_num_cpus}" #defines the number of cpus
   memory = "${var.vsphere_vm_num_mem}" #defines the ammount of ram in megabytes
   memory_hot_add_enabled = "true"
   guest_id = "other3xLinux64Guest"
   scsi_type = "pvscsi"
   #This section defines which pre-existing template to use for the VM.
   disk {
       size = 20
       thin_provisioned = "true"
       label = "test_rancor"
   }
  #This section sets up the network interface and applies an IP address for you.
   network_interface {
     network_id = "${data.vsphere_network.network.id}" #We'll need to figure out port groups.
   }

   clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"
   }

   provisioner "remote-exec" {
     connection {
       type     = "ssh"
       user     = "${var.ssh_provisioner_user}"
       password = "${var.ssh_provisioner_password}"
     }

    inline = [
      "sudo ros engine switch docker-17.03.2-ce",
      "sudo ros config set rancher.network.interfaces.eth0.address ${var.vsphere_vm_subnet}.${count.index + ${var.vsphere_vm_subnet_offset}}/24",
      "sudo ros config set rancher.network.interfaces.eth0.gateway ${var.vsphere_vm_gateway}",
      "sudo ros config set hostname ${var.vsphere_vm_name_prefix}${substr(var.char_array, count.index, 1)}l",
      "sleep 30",
      "sudo ros service restart network",
    ]
  }
}
