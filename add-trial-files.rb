#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = 'src/AudioSwitchPro.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first

# Find the groups
main_group = project.main_group['AudioSwitchPro']
services_group = main_group['Services']
views_group = main_group['Views']

# Files to add
files_to_add = [
  { path: 'Services/LicenseManager.swift', group: services_group },
  { path: 'Views/ActivationView.swift', group: views_group },
  { path: 'Views/TrialBannerView.swift', group: views_group },
  { path: 'Views/LicenseStatusView.swift', group: views_group }
]

# Add each file
files_to_add.each do |file_info|
  file_path = "AudioSwitchPro/#{file_info[:path]}"
  
  # Check if file already exists in project
  existing_ref = project.files.find { |f| f.path == file_path }
  
  if existing_ref.nil?
    # Add file reference
    file_ref = file_info[:group].new_file(file_path)
    
    # Add to build phase
    target.source_build_phase.add_file_reference(file_ref)
    
    puts "Added #{file_path} to project"
  else
    puts "#{file_path} already exists in project"
  end
end

# Save the project
project.save
puts "\nProject updated successfully!"
puts "\nIMPORTANT: Please open Xcode and verify the files are correctly added."