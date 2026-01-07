#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = 'src/AudioSwitchPro.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find files with incorrect paths
files_to_fix = {
  'LicenseManager.swift' => 'LicenseManager.swift',
  'ActivationView.swift' => 'ActivationView.swift',
  'TrialBannerView.swift' => 'TrialBannerView.swift',
  'LicenseStatusView.swift' => 'LicenseStatusView.swift'
}

files_to_fix.each do |filename, transform_path|
  # Helper to recursively find file
  file_ref = project.files.find { |f| f.path&.include?(filename) }
  
  if file_ref
    puts "Refixing path for #{filename}: #{file_ref.path} -> #{transform_path}"
    file_ref.path = transform_path
    
    # Also ensure source_tree is <group> so it uses parent's path
    file_ref.source_tree = '<group>'
  else
    puts "File reference for #{filename} not found!"
  end
end

# Save the project
project.save
puts "Project paths re-fixed correctly!"
