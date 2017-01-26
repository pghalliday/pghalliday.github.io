module BowerComponentTasks
  def bower_component_tasks(components)
    components.each do |component, glob|
      dest_dir = File.join 'vendor', component
      source_dir = File.join 'bower_components', component, 'dist'
      files = []
      Dir.chdir source_dir do
        Dir.glob glob do |f|
          dest = File.join dest_dir, f
          source = File.join source_dir, f
          files.push dest
          dir = File.dirname dest
          directory dir
          file dest => [dir, source] do |task|
            cp task.prerequisites[1], task.name
          end
        end
      end
      multitask component => files
    end
    components.keys
  end
end
