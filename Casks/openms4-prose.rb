cask "openms4-prose" do
  arch arm: "arm64", intel: "x64"

  version "1.0.0-ci.5,11bc89966a2a"
  sha256 arm:   "c35090665040670dc26fac7fab55c6932db43b120e5cf3562f28e363065d9130",
         intel: "501efa166afa2f29f66c719a8c6b98a6b2bb139c386f6fbd7704c4af0a6c66b8"

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
    next if core == "eb58e981d7e0864634b59230874a56a1512369f7"

    raise Cask::CaskError, "openms4-prose #{version.csv.first} was built against openms4-core eb58e981d7e0, " \
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
