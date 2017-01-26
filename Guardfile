# generate the vendor directory
guard 'rake', task: 'default' do
  watch(%r{^bower_components/.+})
end

# generate the _site directory
guard 'jekyll-plus', serve: true, drafts: true do
  watch(%r{^_config.yml})
  watch(%r{^index.html})
  watch(%r{^CNAME})
  watch(%r{^_drafts/.+})
  watch(%r{^_layouts/.+})
  watch(%r{^_posts/.+})
  watch(%r{^css/.+})
  watch(%r{^vendor/.+})
end

# reload browsers
guard 'livereload', grace_period: 1.0 do
  watch(%r{^_site/.+})
end
