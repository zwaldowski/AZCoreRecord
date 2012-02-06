Pod::Spec.new do |s|
  s.name     = 'MagicalRecord'
  s.license  = 'MIT'
  s.summary  = 'Effortless fetching, saving, and importing for Core Data.'
  s.homepage = 'http://github.com/magicalpanda/MagicalRecord'
  s.author   = { 'Saul Mora' => 'saul@magicalpanda.com',
		 'Zachary Waldowski' => 'zwaldowski@gmail.com',
		 'Alexsander Akers' => 'a2@pandamonia.us' }
  s.source   = { :git => 'http://github.com/zwaldowski/MagicalRecord.git' }
  s.source_files = 'Source/'
  s.clean_paths  = 'iOS App Unit Tests/', 'Mac App Unit Tests/', 'Magical Record.xcodeproj/', 'Unit Tests/', '.gitignore'
  s.framework    = 'CoreData'
  s.requires_arc = true

  def s.post_install(target)
    prefix_header = config.project_pods_root + target.prefix_header_filename
    prefix_header.open('a') do |file|
      file.puts(%{#ifdef __OBJC__\n#import "MagicalRecord.h"\n#endif})
    end
  end
end
