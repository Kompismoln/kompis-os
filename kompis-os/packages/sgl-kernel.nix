{
  buildPythonPackage,
  scikit-build-core,
  torch,
  lib,
  fetchFromGitHub,
  fetchzip,
  cmake,
  ninja,
  cudaPackages,
  numactl,
  rdma-core,
  writeTextDir,
}:

let
  pname = "sgl-kernel";
  version = "0.5.8";

  torchCudaStub = writeTextDir "c10/cuda/impl/cuda_cmake_macros.h" ''
    #pragma once
    /* Stub generated for Nix packaging — torch dev output is missing this
       CMake-generated header. The macro controls symbol visibility for shared
       builds; defining it is correct since nixpkgs torch is a shared library. */
    #define C10_CUDA_BUILD_SHARED_LIBS
  '';
  cutlass-src = fetchFromGitHub {
    owner = "NVIDIA";
    repo = "cutlass";
    rev = "57e3cfb47a2d9e0d46eb6335c3dc411498efa198";
    hash = "sha256-9CrPhjVNnexyw92Iov9Ky9TMfV770w8RkiUPDLjUm3s=";
  };
  deepgemm-src = fetchFromGitHub {
    owner = "sgl-project";
    repo = "DeepGEMM";
    rev = "54f99a8af537b3c6eb4819b69907ccbe2b600792";
    hash = "sha256-MKIYP1CyQzpF3nCXacFg2Xfwm9LqY4xPoXvw2J6v9SI=";
  };
  fmt-src = fetchFromGitHub {
    owner = "fmtlib";
    repo = "fmt";
    rev = "553ec11ec06fbe0beebfbb45f9dc3c9eabd83d28";
    hash = "sha256-Ru9X3qYGI42Rv5DHsle6NrYmW2yIsairS9WAlL3cViI=";
  };
  triton-src = fetchFromGitHub {
    owner = "triton-lang";
    repo = "triton";
    rev = "v3.5.1";
    hash = "sha256-dyNRtS1qtU8C/iAf0Udt/1VgtKGSvng1+r2BtvT9RB4=";
  };
  flashinfer-src = fetchFromGitHub {
    owner = "flashinfer-ai";
    repo = "flashinfer";
    rev = "bc29697ba20b7e6bdb728ded98f04788e16ee021";
    hash = "sha256-3C9ykrXvAnbHu0DeUkK9kOXatNRKLhhZukxPbilPNw8=";
  };
  flash-attention-src = fetchFromGitHub {
    owner = "sgl-project";
    repo = "sgl-attn";
    rev = "f866ec34002250e74c8bbcbcffa0e1ae71300b2d";
    hash = "sha256-0s1n4okME5LsYw7o3s0HQguZeMEIaCPhFegrbOPPmQQ=";
  };
  mscclpp-src = fetchFromGitHub {
    owner = "microsoft";
    repo = "mscclpp";
    rev = "51eca89d20f0cfb3764ccd764338d7b22cd486a6";
    hash = "sha256-k0C4W5EV5GMbF/rNebHyRar9y7JqCBZgL8ocNkwE6/E=";
  };
  json-src = fetchzip {
    url = "https://github.com/nlohmann/json/releases/download/v3.11.3/json.tar.xz";
    hash = "sha256-cnGfiVhXzqfj5Fay823wntWcTnbh8r2SefDLslb1Dh0=";
  };
  nanobind-src = fetchFromGitHub {
    owner = "wjakob";
    repo = "nanobind";
    rev = "v1.4.0";
    fetchSubmodules = true;
    hash = "sha256-LNL0vVBWPfq4XhfWfe1blfmkpkSEU8hlJ+S4aHo5v+M=";
  };
  dlpack-src = fetchFromGitHub {
    owner = "dmlc";
    repo = "dlpack";
    rev = "v1.1";
    hash = "sha256-RoJxvlrt1QcGvB8m/kycziTbO367diOpsnro49hDl24=";
  };
  flashmla-src = fetchFromGitHub {
    owner = "sgl-project";
    repo = "FlashMLA";
    rev = "sgl";
    hash = "sha256-Ifsg5jHlL0PxrPtf6bzdPV/MHk3xp+gkzk9wCmcnMHM=";
  };
  sglang-src = fetchFromGitHub {
    owner = "sgl-project";
    repo = "sglang";
    rev = "v${version}";
    hash = "sha256-R3h7UJtq3IySElQEG6q4j23LIYFKsIUwDNdBr2dJWSw=";
  };
in
buildPythonPackage {
  inherit pname version;
  pyproject = true;

  src = sglang-src;
  sourceRoot = "${sglang-src.name}/${pname}";

  build-system = [
    scikit-build-core
  ];

  nativeBuildInputs = [
    cmake
    ninja
    cudaPackages.cuda_nvcc
  ];

  buildInputs = [
    numactl
    rdma-core
    cudaPackages.cuda_cudart
    cudaPackages.libcublas.dev
    cudaPackages.libcusparse.dev
    cudaPackages.libcurand.dev
    cudaPackages.libcusolver.dev
    cudaPackages.cuda_cccl
    cudaPackages.cuda_nvrtc.dev
  ];

  dependencies = [
    torch
  ];

  # let scikit-build-core handle cmake
  dontUseCmakeConfigure = true;

  env = {
    SKBUILD_CMAKE_DEFINE = lib.concatStringsSep ";" [
      "CUDA_VERSION=${cudaPackages.cuda_nvcc.version}"
      "FETCHCONTENT_SOURCE_DIR_REPO-CUTLASS=${cutlass-src}"
      "FETCHCONTENT_SOURCE_DIR_REPO-DEEPGEMM=${deepgemm-src}"
      "FETCHCONTENT_SOURCE_DIR_REPO-FLASHINFER=${flashinfer-src}"
      "FETCHCONTENT_SOURCE_DIR_REPO-FLASH-ATTENTION=${flash-attention-src}"
      "FETCHCONTENT_SOURCE_DIR_REPO-FMT=${fmt-src}"
      "FETCHCONTENT_SOURCE_DIR_REPO-TRITON=${triton-src}"
      "FETCHCONTENT_SOURCE_DIR_REPO-MSCCLPP=${mscclpp-src}"
      "FETCHCONTENT_SOURCE_DIR_JSON=${json-src}"
      "FETCHCONTENT_SOURCE_DIR_NANOBIND=${nanobind-src}"
      "FETCHCONTENT_SOURCE_DIR_DLPACK=${dlpack-src}"
      "FETCHCONTENT_SOURCE_DIR_REPO-FLASHMLA=${flashmla-src}"
      "CMAKE_POLICY_VERSION_MINIMUM=3.5" # dlpack v1.1 uses old CMAKE
      "CMAKE_CXX_FLAGS=-I${torchCudaStub}"
      "CMAKE_CUDA_FLAGS=-I${torchCudaStub}"
    ];
  };

  pythonImportsCheck = [ "sgl_kernel" ];
}
