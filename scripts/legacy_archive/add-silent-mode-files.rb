#!/usr/bin/env ruby

# Script to add Silent Mode files to Xcode project
# Requires: gem install xcodeproj

begin
  require 'xcodeproj'
rescue LoadError
  puts "Installing xcodeproj gem..."
  system("gem install xcodeproj")
  require 'xcodeproj'
end

project_path = "src/AudioSwitchPro.xcodeproj"
project = Xcodeproj::Project.open(project_path)

# Find main target
target = project.targets.find { |t| t.name == "AudioSwitchPro" }

# Find groups
models_group = project.main_group.find_subpath("AudioSwitchPro/Models")
services_group = project.main_group.find_subpath("AudioSwitchPro/Services")  
views_group = project.main_group.find_subpath("AudioSwitchPro/Views")

# Add files
files_to_add = [
  { path: "src/AudioSwitchPro/Models/SilentModeApp.swift", group: models_group },
  { path: "src/AudioSwitchPro/Services/SilentModeManager.swift", group: services_group },
  { path: "src/AudioSwitchPro/Views/SilentModeView.swift", group: views_group }
]

files_to_add.each do |file_info|
  file_path = file_info[:path]
  group = file_info[:group]
  
  # Check if file already exists in project
  file_ref = group.files.find { |f| f.path.include?(File.basename(file_path)) }
  
  if file_ref.nil?
    # Add file reference
    file_ref = group.new_file(file_path)
    
    # Add to build phase
    target.source_build_phase.add_file_reference(file_ref)
    
    puts "✅ Added #{File.basename(file_path)}"
  else
    puts "⚠️  #{File.basename(file_path)} already in project"
  end
end

# Save project
project.save
puts "\n✨ Project updated successfully!"