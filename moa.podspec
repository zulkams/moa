Pod::Spec.new do |s|
  s.name        = "moa"
  s.version     = "12.0.0"
  s.license     = { :type => "MIT" }
  s.homepage    = "https://github.com/evgenyneu/moa"
  s.summary     = "An image download extension for image view written in Swift."
  s.description  = <<-DESC
                   Moa is an image download library written in Swift for iOS, tvOS and macOS.
                   It allows to download and show an image in an image view by setting its moa.url property.

                   * Images are downloaded asynchronously.
                   * Uses NSURLSession for networking and caching.
                   * Allows to configure cache size and policy.
                   * Can be used without an image view.
                   * Provides closure properties for image manipulation and error handling.
                   * Includes unit testing mode for faking network responses.
                   DESC
  s.authors     = { "Evgenii Neumerzhitckii" => "sausageskin@gmail.com" }
  s.source      = { :git => "https://github.com/evgenyneu/moa.git", :tag => s.version }
  s.screenshots  = "https://raw.githubusercontent.com/evgenyneu/moa/master/Graphics/Hunting_Moa.jpg"
  s.source_files = "Moa/**/*.swift"
  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.9"
  s.tvos.deployment_target = "9.0"
  s.swift_versions = ['4.2', '5.0']
end