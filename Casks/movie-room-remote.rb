cask "movie-room-remote" do
  version "1.0.0"
  sha256 "e9b4b9d282b9a70696562d4f74a023c229d62f8cce08ae5f39dd7d6ebb6437e4"

  url "https://github.com/ajanis/MovieRoomRemote/releases/download/v#{version}/MovieRoomRemote-#{version}.dmg"
  name "Movie Room Remote"
  desc "Menu bar remote and Apple TV keyboard for the movie room"
  homepage "https://github.com/ajanis/MovieRoomRemote"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on :macos

  app "MovieRoomRemote.app"

  uninstall quit: "ConstructorFleet.MovieRoomRemote"

  zap trash: [
    "~/Library/Preferences/com.prettybaked.MovieRoomRemote.plist",
    "~/Library/Preferences/ConstructorFleet.MovieRoomRemote.plist",
    "~/Library/Saved Application State/com.prettybaked.MovieRoomRemote.savedState",
    "~/Library/Saved Application State/ConstructorFleet.MovieRoomRemote.savedState",
  ]
end
