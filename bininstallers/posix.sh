#!/usr/bin/env bash

# Available environment variables to alter the behavior of the script:
# CYNTHIAWEB_MINI_INSTALL_DIR: Directory to install cynthiaweb-mini. Default is ~/.local/bin/mini.
# CYNTHIAWEB_MINI_RELEASE: Release version to install. Default is the latest release.

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PINK='\033[1;35m'
CYAN='\033[1;36m'
NC='\033[0m' # No Color

# Determine OS type
if [[ -f /proc/version ]]; then
  if grep -qi microsoft /proc/version; then
    det_os="windows-wsl"
  else
    det_os="linux"
  fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
  det_os="macos"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
  det_os="windows"
else
  echo -e "${RED}Unsupported operating system${NC}"
  exit 1
fi
# Set visualization OS variable
vis_os="${det_os}"
if [[ "$det_os" == "windows-wsl" ]]; then
  vis_os="windows"
fi

# OS architecture
if [[ "$(uname -m)" == "x86_64" ]]; then
  det_arch="x64"
elif [[ "$(uname -m)" == "aarch64" ]]; then
  det_arch="arm64"
else
  echo -e "${RED}Your architecture, $(uname -m), is not supported for the binary install. \nYou will have to use the bun install option.${NC}"
  exit 1
fi

# Tell the user what OS we detected
echo -e "${BLUE}Detected OS:${NC} $vis_os ($det_arch)"

if [[ "$det_os" == "windows-wsl" ]]; then
  echo -e "${YELLOW}Running in WSL. Be aware that there is also a Windows installer available!${NC}"
fi

# Check if the user has curl installed
if ! command -v curl &>/dev/null; then
  echo -e "${RED}curl could not be found. Please install curl to use this script.${NC}"
  exit 1
fi

# Check if the user has grep installed
if ! command -v grep &>/dev/null; then
  echo -e "${RED}grep could not be found. Please install grep to use this script.${NC}"
  exit 1
fi

if [[ -n "$CYNTHIAWEB_MINI_RELEASE" ]]; then
  release="$CYNTHIAWEB_MINI_RELEASE"
else
  # Fetch the latest release version from GitHub
  release=$(curl -s https://api.github.com/repos/CynthiaWebsiteEngine/Mini/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
fi
if [[ -z "$release" ]]; then
  echo -e "${RED}Failed to fetch release information from GitHub${NC}"
  exit 1
fi

url="https://github.com/CynthiaWebsiteEngine/Mini/releases/download/v${release#v}/cynthiaweb-mini-${vis_os}-${det_arch}"

if [[ -n "$CYNTHIAWEB_MINI_INSTALL_DIR" ]]; then
  bin_dir="$CYNTHIAWEB_MINI_INSTALL_DIR"
else
  # Default installation directory
  bin_dir="$HOME/.local/bin/mini"
fi

temp_file=$(mktemp -d)/cynthiaweb-mini

echo -e "${BLUE}Downloading ${NC}${PINK}cynthiaweb-mini${NC}${BLUE} from ${CYAN}${url}${NC}"

# Start the download
curl -L -o "${temp_file}" "${url}"

# Check if the directory exists
if [[ ! -d $bin_dir ]]; then
  mkdir -p "$bin_dir" ||
    echo -e "${RED}Failed to create install directory \"$bin_dir\"${NC}"
fi

mv "${temp_file}" "$bin_dir" ||
  echo -e "${RED}Failed to move ${NC}${PINK}cynthiaweb-mini${NC} to \"${CYAN}$bin_dir${NC}\""

chmod +x "$bin_dir/cynthiaweb-mini" ||
  echo -e "${RED}Failed to make cynthiaweb-mini executable${NC}"
echo -e "${PINK}cynthiaweb-mini${NC}${GREEN} installed to ${NC}${CYAN}$bin_dir${NC}"

# Check if the user has added the bin directory to their PATH
if [[ ":$PATH:" != *":$bin_dir:"* ]]; then
  echo -e "${YELLOW}Adding ${CYAN}$bin_dir${NC}${YELLOW} to your PATH...${NC}"
  # Export for current session
  export PATH="$PATH:$bin_dir"

  # Determine which shell config file to use
  shell_config=""
  if [[ -f "$HOME/.bashrc" ]]; then
    shell_config="$HOME/.bashrc"
  elif [[ -f "$HOME/.zshrc" ]]; then
    shell_config="$HOME/.zshrc"
  elif [[ -f "$HOME/.profile" ]]; then
    shell_config="$HOME/.profile"
  fi

  if [[ -n "$shell_config" ]]; then
    # Check if it's already in the config file
    if ! grep -q "export PATH=\"\$PATH:$bin_dir\"" "$shell_config"; then
      echo -e "\n# Added by cynthiaweb-mini installer\nexport PATH=\"\$PATH:$bin_dir\"" >>"$shell_config"
      echo -e "${GREEN}Added to ${CYAN}$shell_config${NC}${GREEN}.${NC}"
      echo -e "${GREEN}The PATH is updated for current session. For new sessions, either restart your terminal or run:${NC}"
      echo -e "${BLUE}source $shell_config${NC}"
    else
      echo -e "${GREEN}PATH entry already exists in ${CYAN}$shell_config${NC}${GREEN}.${NC}"
    fi
  else
    echo -e "${YELLOW}Could not determine shell config file. PATH is updated for current session only.${NC}"
    echo -e "${YELLOW}To make it permanent, add the following line to your shell config file:${NC}"
    echo -e "${BLUE}export PATH=\"\$PATH:$bin_dir\"${NC}"
  fi

  echo "\n"
  echo -e "${YELLOW}Please add ${CYAN}$bin_dir${NC}${YELLOW} to your PATH to use cynthiaweb-mini.${NC}"
  echo -e "${YELLOW}You can do this by adding the following line to your ${RED}~/.bashrc${NC} ${YELLOW}or${NC} ${RED}~/.zshrc${NC}${YELLOW}:${NC}"
  echo -e "${BLUE}export PATH=\"\$PATH:$bin_dir\"${NC}"
  echo "\n"
else
  echo -e "${PINK}cynthiaweb-mini${NC}${GREEN} is ready to use!${NC}"
fi
