require "formula"

class SwiProlog < Formula
  homepage "http://www.swi-prolog.org/"
  url "http://www.swi-prolog.org/download/stable/src/pl-6.6.6.tar.gz"
  sha1 "38cc6772a48fd412f50fc06e24e6e4673eb71d3b"
  revision 1

  bottle do
    root_url "https://downloads.sf.net/project/machomebrew/Bottles/x11"
    revision 1
    sha1 "77484655836158b8a98d0c643ca016c9d5a32f33" => :yosemite
    sha1 "ac3ff712449af7fbe1a391d801caa71d0849ccc3" => :mavericks
    sha1 "18e03b72f6d4ac40a4820ea69c102c03d8c3cdbc" => :mountain_lion
  end

  devel do
    url "http://www.swi-prolog.org/download/devel/src/pl-7.1.30.tar.gz"
    sha1 "3a67dee3e5d52bb458335346a3d8a947d99b13f5"
  end

  head do
    url "https://github.com/SWI-Prolog/swipl-devel.git"

    depends_on "autoconf" => :build
  end

  option "lite", "Disable all packages"
  option "with-jpl", "Enable JPL (Java Prolog Bridge)"
  option "with-xpce", "Enable XPCE (Prolog Native GUI Library)"

  depends_on "pkg-config" => :build
  depends_on "readline"
  depends_on "gmp"
  depends_on "openssl"
  depends_on "libarchive" => :optional

  if build.with? "xpce"
    depends_on :x11
    depends_on "jpeg"
  end

  # 10.5 versions of these are too old
  if MacOS.version <= :leopard
    depends_on "fontconfig"
    depends_on "expat"
  end

  fails_with :llvm do
    build 2335
    cause "Exported procedure chr_translate:chr_translate_line_info/3 is not defined"
  end

  def install
    # The archive package hard-codes a check for MacPort libarchive
    # Replace this with a check for Homebrew's libarchive, or nowhere
    if build.with? "libarchive"
      inreplace "packages/archive/configure.in", "/opt/local",
                                                 Formula["libarchive"].opt_prefix
    else
      ENV.append "DISABLE_PKGS", "archive"
    end

    args = ["--prefix=#{libexec}", "--mandir=#{man}"]
    ENV.append "DISABLE_PKGS", "jpl" if build.without? "jpl"
    ENV.append "DISABLE_PKGS", "xpce" if build.without? "xpce"

    # SWI-Prolog's Makefiles don't add CPPFLAGS to the compile command, but do
    # include CIFLAGS. Setting it here. Also, they clobber CFLAGS, so including
    # the Homebrew-generated CFLAGS into COFLAGS here.
    ENV["CIFLAGS"] = ENV.cppflags
    ENV["COFLAGS"] = ENV.cflags

    # Build the packages unless --lite option specified
    args << "--with-world" unless build.include? "lite"

    # './prepare' prompts the user to build documentation
    # (which requires other modules). '3' is the option
    # to ignore documentation.
    system "echo '3' | ./prepare" if build.head?
    system "./configure", *args
    system "make"
    system "make install"

    bin.write_exec_script Dir["#{libexec}/bin/*"]
  end

  test do
    system "#{bin}/swipl", "--version"
  end
end
