cask "stick" do
  version "0.1.0"
  sha256 "REPLACE_WITH_SHA256_FROM_RELEASE_ZIP"

  url "https://github.com/jvalaj/stick/releases/download/v#{version}/Stick.zip"
  name "Stick"
  desc "Native macOS sticky notes app"
  homepage "https://github.com/jvalaj/stick"

  depends_on macos: ">= :tahoe"

  app "Stick.app"

  zap trash: [
    "~/Library/Application Support/StickyNotes",
    "~/Library/Preferences/com.jvalaj.stick.plist",
  ]
end
