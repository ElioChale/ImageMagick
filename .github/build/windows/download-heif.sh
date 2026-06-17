#!/bin/bash
set -e

download_heif()
{
  local arch=$1
  local build_type=$2

  echo "Downloading HEIF dependencies for ${arch}-${build_type}"

  local version="heif-deps-v1.23.0"
  local zip=""

  case "$build_type" in
    dynamic) zip="libheif-windows-${arch}-dynamic.zip" ;;
    static)  zip="libheif-windows-${arch}-static.zip" ;;
    *) echo "Unknown build type: $build_type"; exit 1 ;;
  esac

  mkdir -p "../Artifacts"

  local url="https://github.com/ImageMagick/ImageMagick/releases/download/${version}/${zip}"
  echo "Downloading ${zip} from ${version}"

  curl -sS -L --fail "${url}" -o "${zip}" || {
    echo "HEIF dependencies not available at ${url}"
    echo "Build will continue without HEIC support"
    exit 0
  }

  unzip -o "${zip}" -d "../Artifacts" || {
    exit_code=$?
    if [[ $exit_code -ne 0 && $exit_code -ne 1 ]]; then
      echo "Unzip failed with exit code $exit_code"
      exit $exit_code
    fi
  }

  rm "${zip}"
  echo "HEIF dependencies installed to Artifacts/"
}

arch="${1:-x64}"
build_type="${2:-dynamic}"

download_heif "$arch" "$build_type"
