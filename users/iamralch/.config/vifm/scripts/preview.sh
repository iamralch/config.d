#!/bin/bash

# Previews a file by detecting its MIME type and using an appropriate tool.
#
# For videos, it generates a thumbnail with ffmpegthumbnailer and displays it with chafa.
# For PDFs, it extracts the first 200 lines of text with pdftotext.
# For text files, it shows the first 300 lines with bat.
# For images, it displays them in the terminal with chafa.
# For other file types, it falls back to using the 'file' command.
#
# @param {string} $1 - The path to the file to be previewed.
_preview_file() {
  local file_path="$1"

  local file_type
  file_type=$(file --mime-type -Lb "$file_path" || echo "application/octet-stream")

  case "$file_type" in
  video/*)
    ffmpegthumbnailer -i "$file_path" -o - -s 0 | chafa
    ;;
  application/pdf)
    pdftotext "$file_path" - | sed -n '1,200p'
    ;;
  text/*)
    bat --paging=never --color=always --style=numbers --line-range=:300 "$file_path"
    ;;
  image/*)
    chafa "$file_path"
    ;;
  *)
    file "$file_path"
    ;;
  esac
}

# Previews a directory using the 'tree' command.
#
# It shows a colorized, 2-level deep directory listing.
#
# @param {string} $1 - The path to the directory to be previewed.
_preview_dir() {
  local dir_path="$1"
  tree -C -L 2 "$dir_path"
}

# Main function for the script.
#
# It checks if the provided path is a directory or a file and then calls the
# appropriate preview function.
#
# @param {string} $1 - The path of the file or directory to preview.
main() {
  local path="$1"

  if [[ -d "$path" ]]; then
    _preview_dir "$path"
  elif [[ -f "$path" ]]; then
    _preview_file "$path"
  fi

}

main "$@"
