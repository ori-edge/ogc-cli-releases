#!/bin/sh
VERSION=$(curl --silent "https://api.github.com/repos/ori-edge/ogc-cli-releases/releases/latest" |  jq -r .tag_name)

ARCH=""
case $(uname -m) in
    "x86_64") ARCH="amd64";;
    "arm64") ARCH="arm64";;
    "aarch64") ARCH="arm64";;
    *)
        printf "Unsupported platform"
        exit 1
        ;;
esac

OS=""
EXT=""
case $(uname) in
    "Linux") OS="linux";EXT="tar.gz";;
    "Windows") OS="windows";EXT="zip";;
    "Darwin") OS="darwin";EXT="tar.gz";;
    *)
        printf "Unsupported OS"
        exit 1
        ;;
esac

if [ "${VERSION}" = "latest" ]; then
  DOWNLOAD_URL="https://github.com/ori-edge/ogc-cli-releases/releases/${VERSION}/download/ogc-${OS}-${ARCH}.${EXT}"
else
  DOWNLOAD_URL="https://github.com/ori-edge/ogc-cli-releases/releases/download/${VERSION}/ogc-${OS}-${ARCH}.${EXT}"
fi
TARBALL_DEST="ogc-${OS}-${ARCH}.${EXT}"

printf "Downloading ogc version: %s\\n" "${VERSION}"

if curl -s -L -o "${TARBALL_DEST}" "${DOWNLOAD_URL}"; then
    printf "Extracting to %s\\n" "$HOME/.ogc/bin"

    # If `~/.ogc/bin exists, delete it
    if [ -e "${HOME}/.ogc/bin" ]; then
        rm -rf "${HOME}/.ogc/bin"
    fi

    mkdir -p "${HOME}/.ogc"

    EXTRACT_DIR=$(mktemp -d ogc.XXXXXXXXXX)
    tar zxf "${TARBALL_DEST}" -C "${EXTRACT_DIR}"

    cp -r "${EXTRACT_DIR}/." "${HOME}/.ogc/bin/"

    rm -f "${TARBALL_DEST}"
    rm -rf "${EXTRACT_DIR}"
    printf "Installation complete. You can now use ~/.ogc/bin/ogc to run ogc.\\n"
else
    >&2  printf "error: failed to download %s\\n" "${DOWNLOAD_URL}"
    exit 1
fi

# Add $HOME/.ogc/bin to the PATH
if ! command -v ogc >/dev/null; then
    SHELL_NAME=$(basename "${SHELL}")
    PROFILE_FILE=""

    if [ "${SHELL_NAME}" = "zsh" ]; then
      PROFILE_FILE="${ZDOTDIR:-$HOME}/.zshrc"
    else
      if [ "$(uname)" != "Darwin" ]; then
          if [ -e "${HOME}/.bashrc" ]; then
              PROFILE_FILE="${HOME}/.bashrc"
          elif [ -e "${HOME}/.bash_profile" ]; then
              PROFILE_FILE="${HOME}/.bash_profile"
          fi
      else
          if [ -e "${HOME}/.bash_profile" ]; then
              PROFILE_FILE="${HOME}/.bash_profile"
          elif [ -e "${HOME}/.bashrc" ]; then
              PROFILE_FILE="${HOME}/.bashrc"
          fi
      fi
    fi

    if [ -n "${PROFILE_FILE}" ]; then
        LINE_TO_ADD="export PATH=\$PATH:\$HOME/.ogc/bin"
        if ! grep -q "# add ogc to PATH" "${PROFILE_FILE}"; then
            printf "Adding \$HOME/.ogc/bin to \$PATH in %s\\n" "${PROFILE_FILE}"
            printf "\\n# add ogc to PATH\\n%s\\n" "${LINE_TO_ADD}" >> "${PROFILE_FILE}"
        fi
        printf "Please restart your shell or add %s to your \$PATH\\n" "$HOME/.ogc/bin"
    else
        printf "Please add %s to your \$PATH\\n" "$HOME/.ogc/bin"
    fi
fi