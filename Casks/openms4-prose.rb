cask "openms4-prose" do
  arch arm: "arm64", intel: "x64"

  version "1.0.0-ci.3,b056c8639269"
  sha256 arm:   "14996c27f9fac17ee5dc20f3b8f724e287fc25922347f970c48ea2cfb0c80f6d",
         intel: "b8fe9da0f26eed6ff5cd11284eaf79da1d25e80824fd1257dfe9a1eaf47a6a5b"

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
    next if core == "ac41cc177023e24a8fbc711a6ce9010187c54c44"

    raise Cask::CaskError, "openms4-prose #{version.csv.first} was built against openms4-core ac41cc177023, " \
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
