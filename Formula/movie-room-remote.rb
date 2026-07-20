cask "movie-room-remote" do
  version "1.0.0"
  sha256 "REPLACE_WITH_DMG_SHA256"

  url "https://github.com/ajanis/MovieRoomRemote/releases/download/v#{version}/MovieRoomRemote-#{version}.dmg"

  name "Movie Room Remote"
  desc "Menu bar remote and Apple TV keyboard for the movie room"
  homepage "https://github.com/ajanis/MovieRoomRemote"

  app "MovieRoomRemote.app"

  zap trash: [
    "~/Library/Preferences/com.prettybaked.MovieRoomRemote.plist",
    "~/Library/Saved Application State/com.prettybaked.MovieRoomRemote.savedState",
  ]
end