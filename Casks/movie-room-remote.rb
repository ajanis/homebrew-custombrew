cask "movie-room-remote" do
  version "1.0.0"
  sha256 "dafa06b6bee1811b45faee87b2c35ab2bbf3f6b42358a62559ff53812800b38a"

  url "https://github.com/ajanis/MovieRoomRemote/releases/download/v#{version}/MovieRoomRemote-#{version}.dmg"
  name "Movie Room Remote"
  desc "Menu bar remote and Apple TV keyboard for the movie room"
  homepage "https://github.com/ajanis/MovieRoomRemote"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: :sequoia

  app "MovieRoomRemote.app"

  uninstall quit: "ConstructorFleet.MovieRoomRemote"

  zap trash: [
    "~/Library/Preferences/com.prettybaked.MovieRoomRemote.plist",
    "~/Library/Preferences/ConstructorFleet.MovieRoomRemote.plist",
    "~/Library/Saved Application State/com.prettybaked.MovieRoomRemote.savedState",
    "~/Library/Saved Application State/ConstructorFleet.MovieRoomRemote.savedState",
  ]
end
