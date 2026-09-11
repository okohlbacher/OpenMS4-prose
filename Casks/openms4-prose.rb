cask "openms4-prose" do
  arch arm: "arm64", intel: "x64"

  version "1.0.0-ci.1,429b3a642aa2"
  sha256 arm:   "2c8aef1435dcbabba3137c73c6cdfb35f79369905f698b40ca7f050c7090d721",
         intel: "5b20b20ab0f9cab59591960cddc5929ed80f1c9abad8623fbcdf15f134f36dd3"

  url "https://github.com/okohlbacher/OpenMS4-prose/releases/download/" \
      "prose-v#{version.csv.first}/OpenMS4-prose-macos-#{arch}-Homebrew-#{version.csv.second}.tar.gz"
  name "OpenMS 4 prose tools"
  desc "Command-line mass-spectrometry tools built against the OpenMS Core SDK"
  homepage "https://github.com/okohlbacher/OpenMS4-prose"

  depends_on formula: "okohlbacher/openms4-core/openms4-core"
  depends_on macos: :sequoia

  payload = "OpenMS4-prose-macos-#{arch}-Homebrew-#{version.csv.second}"
  binary "#{payload}/bin/ProSE"

  postflight_steps do
    run "/usr/bin/xattr",
        args:           ["-dr", "com.apple.quarantine", "."],
        chdir:          ".",
        writable_paths: ["."]
  end
end
