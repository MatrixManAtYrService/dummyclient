{ stdenv, fetchgit, clang, boost, pkg-config, cmake, openssl, zlib, ninja }:

stdenv.mkDerivation rec {
  pname = "cpprestsdk";
  version = "2.10.19";

  src = fetchgit {
    url = "https://github.com/microsoft/cpprestsdk";
    rev = "v${version}";
    sha256 = "sha256-nnLkA3eH0hzeemWP+CYi3pNI0rMYPIC4qjMZimylGRM=";
  };

  nativeBuildInputs = [
    clang
    boost.dev
    pkg-config
    cmake
    openssl
    zlib
    ninja
  ];

  propagatedBuildInputs = [
    boost.dev
    openssl
    zlib
  ];

  cmakeFlags = [
    "-DWERROR=OFF"
    "-DBUILD_SAMPLES=OFF"
    "-DBUILD_TESTS=OFF"
  ];
}