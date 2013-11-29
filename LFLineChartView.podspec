Pod::Spec.new do |s|
  s.name         = "LFLineChartView"
  s.version      = "0.1.0"
  s.summary      = "A view to show line charts on iOS."
  s.homepage     = "https://github.com/leonardfactory/LFLineChartView"
  s.license      = 'MIT'
  s.author       = { "leonardfactory" => "me@leonardfactory.com" }
  s.source       = { :git => "https://github.com/leonardfactory/LFLineChartView.git", :tag => s.version.to_s }

  s.platform     = :ios, '6.0'
  # s.ios.deployment_target = '5.0'
  s.requires_arc = true

  s.source_files = 'LFLineChartView'
  s.ios.frameworks = 'QuartzCore', 'CoreText'
end