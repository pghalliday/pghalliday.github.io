Vagrant.configure("2") do |config|
  config.berkshelf.enabled = true
  config.omnibus.chef_version = :latest

  config.vm.box = "precise-server-cloudimg-amd64"
  config.vm.box_url = "http://cloud-images.ubuntu.com/vagrant/precise/current/precise-server-cloudimg-amd64-vagrant-disk1.box"
  config.vm.hostname = "pghalliday.github.io"

  config.vm.network "forwarded_port", guest: 4000, host: 4000

  config.vm.provider :virtualbox do |vb|
    vb.customize [
      "modifyvm", :id,
      "--memory", "1024",
      "--cpus", "2",
    ]
  end

  config.vm.provision :chef_solo do |chef|
    chef.run_list = [
      "recipe[ruby-with-bundler]"
    ]
  end
end
