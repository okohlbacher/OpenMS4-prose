cask "openms4-prose" do
  arch arm: "arm64", intel: "x64"

  version "1.0.0-ci.2,828d72595677"
  sha256 arm:   "3fe08fd24ab2ff5389365c19395ddf0f4c3f824365f1f11ffdef653447705a7d",
         intel: "f9d072f30e3536499db5abe225f682d42d1b0defe4e00cea383fb1077ede2331"

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
