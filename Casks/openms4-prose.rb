cask "openms4-prose" do
  arch arm: "arm64", intel: "x64"

  version "1.0.0-ci.8,ad6ee9cde2bb"
  sha256 arm:   "badc2bd1d684b779af8456021ccf42c45983f9b639159551191de7083d621d7d",
         intel: "b7e6acb6120fe55813be076c48554aa388ed4bdb39155dac93417710a616d22a"

  url "https://github.com/okohlbacher/OpenMS4-prose/releases/download/" \
      "prose-v#{version.csv.first}/OpenMS4-prose-macos-#{arch}-Homebrew-#{version.csv.second}.tar.gz"
  name "OpenMS 4 prose tools"
  desc "Command-line mass-spectrometry tools built against the OpenMS Core SDK"
  homepage "https://github.com/okohlbacher/OpenMS4-prose"

  depends_on formula: "okohlbacher/openms4-core/openms4-core"
  depends_on macos: :sequoia

  payload = "OpenMS4-prose-macos-#{arch}-Homebrew-#{version.csv.second}"
  binary "#{payload}/bin/ProSE"

  # libOpenMS has no versioned name, so a payload only runs with the Core it was built against.
  preflight do
    config = "#{HOMEBREW_PREFIX}/opt/openms4-core/lib/cmake/OpenMS/OpenMSConfig.cmake"
    core = File.exist?(config) ? File.read(config)[/set\(OpenMS_SOURCE_REVISION "([0-9a-f]{40})"\)/, 1] : nil
    next if core == "0529ec8bfe0785d546dab56f58456525ef0fef02"

    raise Cask::CaskError, "openms4-prose #{version.csv.first} was built against openms4-core 0529ec8bfe07, " \
                           "but the installed openms4-core is #{core&.slice(0, 12) || "unknown"}. " \
                           "Install the openms4-prose release built for the installed Core."
  end

  postflight_steps do
    run "/usr/bin/xattr",
        args:           ["-dr", "com.apple.quarantine", "."],
        chdir:          ".",
        writable_paths: ["."]
  end
end
