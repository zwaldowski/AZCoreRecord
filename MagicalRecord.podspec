Pod::Spec.new do |s|
  s.name     = 'MagicalRecord'
  s.version   = '2.1az'
  s.license  = 'MIT'
  s.summary  = 'Effortless fetching, saving, and importing for Core Data.'
  s.homepage = 'http://github.com/magicalpanda/MagicalRecord'
  s.author   = { 'Saul Mora' => 'saul@magicalpanda.com',
		 'Zachary Waldowski' => 'zwaldowski@gmail.com',
		 'Alexsander Akers' => 'a2@pandamonia.us' }
  s.source   = { :git => 'https://github.com/zwaldowski/MagicalRecord.git', :commit => 'origin/master' }
  s.source_files = 'Source/'
  s.framework    = 'CoreData'
  s.requires_arc = true
end
