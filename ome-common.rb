class OmeCommon < Formula
  desc "Open Microscopy Environment (OME) common functionality"
  homepage "https://www.openmicroscopy.org/site/products/ome-files-cpp/"
  url "https://downloads.openmicroscopy.org/ome-common-cpp/5.5.0/source/ome-common-cpp-5.5.0.tar.xz"
  sha256 "96ae1824fffcc405de53666133b009d32ee304b6aa1b086c1738d7a05d98853d"
  head "https://github.com/ome/ome-common-cpp.git", :branch => "develop", :shallow => false

  bottle do
    sha256 "b8c159d5ab68163e59a37a050cf2a26c63a43d3503cbb8946a3c152a699e64dc" => :high_sierra
    sha256 "3a5190975548cffa254d8ec927c2288d91f02f6e18fe7eaab4333e14be9f6610" => :sierra
    sha256 "0db890ec186c4a4d43ab396fd81d3a7f081c1ebfa55a5cb9ec2b62fabd13653d" => :el_capitan
    sha256 "a29a562a1bc6f597ee7b5b4691bb065d922876c52cccd39134ceec1d66e06e1c" => :x86_64_linux
  end

  option "with-api-docs", "Build API reference"
  option "without-test", "Skip build time tests (not recommended)"

  depends_on "boost"
  depends_on "cmake" => :build
  depends_on "xalan-c"
  depends_on "xerces-c"
  depends_on "doxygen" => :build if build.with? "api-docs"
  depends_on "graphviz" => :build if build.with? "api-docs"

  # Needs clang/libc++ toolchain; mountain lion is too broken
  depends_on MinimumMacOSRequirement => :mavericks

  # Required for testing
  resource "gtest" do
    url "https://github.com/google/googletest/archive/release-1.8.0.tar.gz"
    sha256 "58a6f4277ca2bc8565222b3bbd58a177609e9c488e8a72649359ba51450db7d8"
  end

  def install
    if build.with? "test"
      (buildpath/"gtest-source").install resource("gtest")

      gtest_args = *std_cmake_args + [
        "-DCMAKE_INSTALL_PREFIX=#{buildpath}/gtest",
      ]

      cd "gtest-source" do
        system "cmake", ".", *gtest_args
        system "make", "install"
      end
    end

    args = *std_cmake_args + [
      "-DGTEST_ROOT=#{buildpath}/gtest",
      "-Wno-dev",
    ]

    args << ("-Ddoxygen:BOOL=" + (build.with?("api-docs") ? "ON" : "OFF"))

    mkdir "build" do
      system "cmake", "..", *args
      system "make"
      system "ctest", "-V"
      system "make", "install"
    end
  end

  test do
    (testpath/"test.cpp").write <<-EOS.undent
      #include <ome/common/xml/Platform.h>
      #include <ome/common/xsl/Platform.h>

      int main()
      {
        ome::common::xml::Platform xmlplat;
        ome::common::xsl::Platform xslplat;
        return 0;
      }
    EOS
    system ENV.cxx, "test.cpp",
      "-std=c++11",
      "-I#{opt_include}",
      "-L#{opt_lib}",
      "-L#{Formula["boost"].opt_lib}",
      "-L#{Formula["xerces-c"].opt_lib}",
      "-L#{Formula["xalan-c"].opt_lib}",
      "-pthread", "-lome-common",
      "-lxerces-c", "-lxalan-c",
      "-lboost_filesystem-mt", "-lboost_system-mt",
      "-o", "test"
    system "./test"
  end
end
