#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = 'src/AudioSwitchPro.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find files with incorrect paths
files_to_fix = {
  'LicenseManager.swift' => 'AudioSwitchPro/Services/LicenseManager.swift',
  'ActivationView.swift' => 'AudioSwitchPro/Views/ActivationView.swift',
  'TrialBannerView.swift' => 'AudioSwitchPro/Views/TrialBannerView.swift',
  'LicenseStatusView.swift' => 'AudioSwitchPro/Views/LicenseStatusView.swift'
}

files_to_fix.each do |filename, correct_path|
  file_ref = project.files.find { |f| f.path&.include?(filename) }
  if file_ref
    puts "Fixing path for #{filename}: #{file_ref.path} -> #{correct_path}"
    file_ref.path = correct_path
  end
end

# Save the project
project.save
puts "Project paths fixed!"