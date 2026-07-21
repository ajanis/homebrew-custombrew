class Spoctunnel < Formula
  desc "Helper scripts for managing spoc sshuttle tunnels"
  homepage "https://github.com/ajanis/spoctunnel"
  url "https://github.com/ajanis/spoctunnel/releases/download/v13.3.0/v13.3.0.tar.gz"
  sha256 "8bda72c4ab34ef4cef43559046204bce6e06e8c68cbfbcd485e3130d850435e2"

  depends_on "ajanis/custombrew/sshpass"
  depends_on "sshuttle"

  # shasum -a 256 v1.1.tar.gz

  def install
    # Replace /libexec/ with HOMEBREW_PREFIX in scripts
    inreplace "bin/spoctunnel.sh", "SPOCTUNNEL_VERSION", version
    inreplace "etc/newsyslog/spoctunnel.conf", "HOMEBREW_VARLOG", var/"log/spoctunnel"
    inreplace "etc/newsyslog/spoctunnel.conf", "HOMEBREW_LOCALUSER", ENV["USER"]

    # Install allow/deny files"
    (etc/"spoctunnel").install Dir["etc/spoctunnel/*.conf"]
    Dir[etc/"spoctunnel/*"].each do |config_file|
      chmod 0644, config_file
    end

    # Create newsyslog.d directory and log rotation rule in the homebrew prefix
    # (etc/"newsyslog.d").mkpath
    (etc/"newsyslog.d").install "etc/newsyslog/spoctunnel.conf"

    # Create the custom resolver directory and config file in the homebrew prefix
    # (etc/"resolver").mkpath
    (etc/"resolver").install "etc/resolver/spoc.charterlab.com"

    # Install script and bin alias
    bin.install "bin/spoctunnel.sh" => "spoctunnel"
  end

  def post_install
    # Create the log directory in the homebrew prefix
    (var/"log/spoctunnel").mkpath
    (var/"log/spoctunnel").chmod 0744
    # Create the pidfile directory in the homebrew prefix
    (var/"run/spoctunnel").mkpath
    (var/"run/spoctunnel").chmod 0744
    # Create newsyslog directory in homebrew prefix
    (etc/"newsyslog.d/spoctunnel.conf").chmod 0744
    # Create resolver directory in homebrew prefix
    (etc/"resolver/spoc.charterlab.com").chmod 0744
    system "#{bin}/spoctunnel", "postinstall"
  end

  test do
    # Example test to verify your tool's installation
    system "#{bin}/spoctunnel", "version"
  end
end
