include_recipe "rbenv::default"
include_recipe "rbenv::ruby_build"

rbenv_ruby node[:jekyll][:ruby_version] do
  global true
end

rbenv_gem "bundler" do
  ruby_version node[:jekyll][:ruby_version]
end
