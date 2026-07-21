#!/usr/bin/env bash
set -euo pipefail

lR='\033[31m'
lG='\033[32m'
lY='\033[33m'
lB='\033[34m'
lW='\033[0m'

xc() {
    printf "%b\n" "$*"
}

die() {
    xc "${lR}Error: $*${lW}" >&2
    exit 1
}

tap_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ensure_gh() {
    if command -v gh >/dev/null 2>&1; then
        return
    fi

    xc "${lY}GitHub CLI is not installed. Installing with Homebrew...${lW}"
    brew install gh
}

version_readme() {
    xc "${lY}Select a version release to increment. Options are:

  ${lW}['1' or 'major']:   ${lB}Major version release. (Ex. 3.0.0 => 4.0.0)
  ${lW}['2' or 'minor']:   ${lB}Minor point release. (Ex. 4.0.0 => 4.1.0)
  ${lW}['3' or 'patch']:   ${lB}Patch version release. (Ex. 4.1.0 => 4.1.1)${lW}"
}

package_kind() {
    case "$1" in
    Cask/* | Casks/*)
        printf "cask"
        ;;
    Formula/*)
        printf "formula"
        ;;
    *)
        die "Cannot determine package type for $1"
        ;;
    esac
}

package_token() {
    basename "$1" .rb
}

read_package_version() {
    local package_file="$1"
    local explicit_version
    local scanned_version

    explicit_version="$(sed -nE 's/^[[:space:]]*version[[:space:]]+["'\'']([^"'\'']+)["'\''].*/\1/p' "${package_file}" | head -n 1)"
    if [[ -n "${explicit_version}" ]]; then
        printf "%s" "${explicit_version}"
        return
    fi

    scanned_version="$(
        sed -nE '/^[[:space:]]*url[[:space:]]+/p' "${package_file}" |
            grep -Eo '[0-9]+([.][0-9]+){1,2}' |
            tail -n 1 || true
    )"
    printf "%s" "${scanned_version}"
}

github_repo_from_package() {
    local package_file="$1"

    sed -nE 's|^[[:space:]]*homepage[[:space:]]+["'\'']https://github.com/([^"'\'']+)["'\''].*|\1|p' "${package_file}" | head -n 1
}

repo_path_for_package() {
    local package_file="$1"
    local token="$2"
    local github_repo
    local github_name

    if [[ -d "${tap_root}/${token}/.git" || -f "${tap_root}/${token}/.git" ]]; then
        printf "%s/%s" "${tap_root}" "${token}"
        return
    fi

    github_repo="$(github_repo_from_package "${package_file}")"
    github_name="${github_repo##*/}"

    if [[ -n "${github_name}" && ( -d "${tap_root}/${github_name}/.git" || -f "${tap_root}/${github_name}/.git" ) ]]; then
        printf "%s/%s" "${tap_root}" "${github_name}"
        return
    fi

    die "Could not find the source repo for ${package_file}. Expected ${tap_root}/${token} or a GitHub homepage submodule."
}

current_version_for_package() {
    local package_file="$1"
    local repo_path="$2"
    local tag_version
    local file_version

    tag_version="$(git -C "${repo_path}" describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || true)"
    file_version="$(read_package_version "${package_file}")"

    if [[ -n "${tag_version}" ]]; then
        printf "%s" "${tag_version}"
        return
    fi

    [[ -n "${file_version}" ]] || die "Could not read version from ${package_file}"
    printf "%s" "${file_version}"
}

bump_version() {
    local cur_version="$1"
    local version_choice="$2"
    local major
    local minor
    local patch

    IFS='.' read -r major minor patch <<<"${cur_version}"
    patch="${patch:-0}"
    [[ "${major}" =~ ^[0-9]+$ && "${minor}" =~ ^[0-9]+$ && "${patch}" =~ ^[0-9]+$ ]] || die "Version must be x.y or x.y.z, got ${cur_version}"

    case "${version_choice}" in
    major | 1)
        version_level="major"
        major=$((major + 1))
        printf "%s.0.0" "${major}"
        ;;
    minor | 2)
        version_level="minor"
        minor=$((minor + 1))
        printf "%s.%s.0" "${major}" "${minor}"
        ;;
    patch | 3)
        version_level="patch"
        patch=$((patch + 1))
        printf "%s.%s.%s" "${major}" "${minor}" "${patch}"
        ;;
    *)
        version_readme
        die "Invalid version release choice: ${version_choice}"
        ;;
    esac
}

ensure_clean_repo() {
    local repo_path="$1"

    if [[ -n "$(git -C "${repo_path}" status --porcelain)" ]]; then
        die "${repo_path} has uncommitted changes. Commit or stash them before cutting a release."
    fi
}

update_rb_version_and_sha() {
    local package_file="$1"
    local cur_version="$2"
    local new_version="$3"
    local sha256="$4"
    local escaped_cur_version

    escaped_cur_version="$(printf "%s" "${cur_version}" | sed -E 's/[][(){}.^$*+?|\\/]/\\&/g')"

    sed -i '' "s/${escaped_cur_version}/${new_version}/g" "${package_file}"
    sed -i '' -E "/sha256/s/^([[:space:]]*sha256[[:space:]]+).*/\1\"${sha256}\"/" "${package_file}"
}

release_formula() {
    local package_file="$1"
    local token="$2"
    local repo_path="$3"
    local cur_version="$4"
    local new_version="$5"
    local tar_file
    local tar_path
    local archive_sha

    ensure_clean_repo "${repo_path}"

    xc "${lB}Tagging ${token} source repository...${lW}"
    git -C "${repo_path}" tag -a "v${new_version}" -m "${version_level} revision : v${new_version}"

    mkdir -p "${repo_path}/archive"
    tar_file="v${new_version}.tar.gz"
    tar_path="${repo_path}/archive/${tar_file}"

    xc "${lB}Creating source archive ${tar_path}...${lW}"
    git -C "${repo_path}" archive --format=tar.gz --prefix="${token}-${new_version}/" -o "${tar_path}" "v${new_version}"
    archive_sha="$(shasum -a 256 "${tar_path}" | awk '{print $1}')"

    xc "${lG}SHA256 Sum of ${tar_file}: ${archive_sha}${lW}"
    xc "${lB}Pushing ${token} repository and publishing GitHub release...${lW}"
    git -C "${repo_path}" push --all
    git -C "${repo_path}" push --tags
    (cd "${repo_path}" && gh release create "v${new_version}" --generate-notes "${tar_path}")

    xc "${lB}Updating ${package_file} to v${new_version}...${lW}"
    update_rb_version_and_sha "${package_file}" "${cur_version}" "${new_version}" "${archive_sha}"
}

release_cask() {
    local package_file="$1"
    local token="$2"
    local repo_path="$3"
    local cur_version="$4"
    local new_version="$5"
    local package_script
    local latest_path
    local release_metadata
    local metadata_type
    local metadata_value
    local asset_path
    local dmg_sha=""
    local release_asset_paths=()
    local add_paths=()

    ensure_clean_repo "${repo_path}"

    package_script="${repo_path}/scripts/package-release.sh"
    [[ -x "${package_script}" ]] || die "Missing executable cask package script: ${package_script}"

    xc "${lB}Building ${token} installer v${new_version}...${lW}"
    "${package_script}" "${new_version}"

    latest_path="${repo_path}/website/downloads/latest.json"
    [[ -f "${latest_path}" ]] || die "Expected release metadata was not created: ${latest_path}"

    release_metadata="$(mktemp)"
    python3 - "${latest_path}" "${repo_path}/website" >"${release_metadata}" <<'PY'
import json
import pathlib
import sys

latest_path = pathlib.Path(sys.argv[1])
website_dir = pathlib.Path(sys.argv[2])
data = json.loads(latest_path.read_text())

sha256 = data.get("sha256", "")
download = data.get("download", "")
assets = data.get("release_assets") or []

if not assets and download:
    assets = [download, f"{download}.sha256"]

print(f"SHA\t{sha256}")
for asset in assets:
    asset_path = pathlib.Path(asset)
    if not asset_path.is_absolute():
        asset_path = website_dir / asset_path
    print(f"ASSET\t{asset_path}")
PY

    while IFS=$'\t' read -r metadata_type metadata_value; do
        case "${metadata_type}" in
        SHA)
            dmg_sha="${metadata_value}"
            ;;
        ASSET)
            release_asset_paths+=("${metadata_value}")
            ;;
        esac
    done <"${release_metadata}"
    rm -f "${release_metadata}"

    [[ -n "${dmg_sha}" ]] || die "Could not read SHA256 from ${latest_path}"
    [[ ${#release_asset_paths[@]} -gt 0 ]] || die "No release assets were listed in ${latest_path}"

    for asset_path in "${release_asset_paths[@]}"; do
        [[ -f "${asset_path}" ]] || die "Expected release asset was not created: ${asset_path}"
    done

    xc "${lB}Committing and tagging ${token} source release...${lW}"
    for asset_path in scripts xcode website; do
        if [[ -e "${repo_path}/${asset_path}" ]]; then
            add_paths+=("${asset_path}")
        fi
    done
    git -C "${repo_path}" add "${add_paths[@]}"
    git -C "${repo_path}" commit -m "Release ${token} v${new_version}"
    git -C "${repo_path}" tag -a "v${new_version}" -m "${version_level} revision : v${new_version}"

    xc "${lB}Pushing ${token} repository and publishing GitHub release...${lW}"
    git -C "${repo_path}" push --all
    git -C "${repo_path}" push --tags
    (cd "${repo_path}" && gh release create "v${new_version}" --generate-notes "${release_asset_paths[@]}")

    xc "${lB}Updating ${package_file} to v${new_version}...${lW}"
    update_rb_version_and_sha "${package_file}" "${cur_version}" "${new_version}" "${dmg_sha}"
}

commit_tap_update() {
    local package_file="$1"
    local repo_path="$2"
    local token="$3"
    local new_version="$4"
    local repo_rel

    xc "${lB}Committing and pushing tap update...${lW}"
    repo_rel="${repo_path#${tap_root}/}"
    git -C "${tap_root}" add "${package_file}" "${repo_rel}"
    git -C "${tap_root}" commit -m "Updating ${token} to version v${new_version}"
    git -C "${tap_root}" push --all -q
}

main() {
    local package_files=()
    local item=1
    local choice
    local package_file
    local token
    local kind
    local repo_path
    local cur_version
    local version_choice
    local new_version
    local version_level

    ensure_gh

    while IFS= read -r package_file; do
        package_files[item]="${package_file}"
        item=$((item + 1))
    done < <(find Formula Casks -maxdepth 1 -type f -name '*.rb' 2>/dev/null | sort)

    [[ ${#package_files[@]} -gt 0 ]] || die "No Homebrew Formula or Cask files were found."

    xc "${lY}Select Homebrew package ID (Ex. '1')...${lW}"
    for choice in "${!package_files[@]}"; do
        xc "  ${lW}[${choice}] : ${lB}${package_files[${choice}]}${lW}"
    done

    xc "${lY}"
    read -rp "Selection : " choice
    package_file="${package_files[${choice}]:-}"
    [[ -n "${package_file}" ]] || die "Invalid package selection: ${choice}"

    token="$(package_token "${package_file}")"
    kind="$(package_kind "${package_file}")"
    repo_path="$(repo_path_for_package "${package_file}" "${token}")"
    cur_version="$(current_version_for_package "${package_file}" "${repo_path}")"

    xc "${lB}
Package Type: ${kind}
Package Name: ${token}
Package File: ${package_file}
Source Repo:  ${repo_path}
${lW}"

    version_readme
    xc "${lY}"
    read -rp "Version Release Choice : " version_choice

    case "${version_choice}" in
    major | 1)
        version_level="major"
        ;;
    minor | 2)
        version_level="minor"
        ;;
    patch | 3)
        version_level="patch"
        ;;
    esac

    new_version="$(bump_version "${cur_version}" "${version_choice}")"

    xc "${lG}
Previous Version: ${cur_version}
New Version: ${new_version}
${lW}"

    case "${kind}" in
    formula)
        release_formula "${package_file}" "${token}" "${repo_path}" "${cur_version}" "${new_version}"
        ;;
    cask)
        release_cask "${package_file}" "${token}" "${repo_path}" "${cur_version}" "${new_version}"
        ;;
    esac

    commit_tap_update "${package_file}" "${repo_path}" "${token}" "${new_version}"

    xc "${lG}Done${lW}"
}

main "$@"
