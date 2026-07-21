
# Personal [Homebrew](https://brew.sh) Tap

## Formulas

### SSHPass

A tool for non-interactive SSH login where a password is required.

**WARNING: This utility is for edge case laziness and (unless handled appropriately) can leave a clear-text password in your terminal and shell history file.  You should use SSH Keys whenever possible and otherwise, use interactive password login!!**

- [Homepage](http://sourceforge.net/projects/sshpass)

- [Releases](http://sourceforge.net/projects/sshpass/files/sshpass)

### sPOCtunnel

- [Homepage](https://github.com/ajanis/spoc-sshuttle-helper)

- [Releases](https://github.com/ajanis/spoc-sshuttle-helper/releases/download)

- Dependencies:

  - sshuttle

  - ajanis/custombrew/sshpass

## Casks

### Movie Room Remote

A macOS menu bar Apple TV remote powered by a Home Assistant dashboard panel.

- [Homepage](https://github.com/ajanis/MovieRoomRemote)

- Install:

  ```sh
  brew install --cask ajanis/custombrew/movie-room-remote
  ```

## Using custom Taps and Formulae from Github

### Syntax/Usage

[Installing homebrew formulas from 3rd party repositories](https://docs.brew.sh/Taps)

- To install your tap without installing any formula at the same time, users can add it with the brew tap command.

  - If it’s on GitHub, they can use ```brew tap user/repo```, where `user` is your *GitHub username* and `homebrew-repo` is *your repository*.

  - If it’s hosted outside of GitHub, they have to use `brew tap user/repo <URL>`, where `user` and `repo` will be used to refer to *your tap* and `<URL>` is your **Git clone URL**.

- Users can then install your formulae either with ```brew install foo``` if there’s no core formula with the same name, or with ```brew install user/repo/foo``` to avoid conflicts. require 'formula'

  - If it’s on GitHub, users can install any of your formulae with ```brew install user/repo/formula```. *(Homebrew will automatically add your ```github.com/<user>/homebrew-<repo>``` tap before installing the formula.)*

### Example: Installing sshpass from this repository

[ajanis/custombrew/sshpass](https://github.com/ajanis/homebrew-custombrew/sshpass/formula.rb)

Installing the formula: ```ajanis/custombrew/sshpass``` points to the repository and file at ```https://github.com/ajanis/homebrew-custombrew/sshpass/formula.rb```.
