# Function to search for .sln files and open the selected one
CACHE_FILE="$DOTFILES/zsh/.sln_cache"

update_cache() {
  find "$SOURCE" -type f -name "*.sln" -print > "$CACHE_FILE"
}

#Function to search for .sln files and open the selected one
fzf_open_sln() {
  # Check if cache file exists and is not empty
  if [[ ! -s "$CACHE_FILE" ]]; then
    update_cache
  fi

  # Use cached results in fzf
  result=$(cat "$CACHE_FILE" | fzf)

  # Open the selected file
  [ -n "$result" ] && start "$result"}

# Optionally, add a command to manually update the cache
fzf_update_cache() {
  update_cache
  echo "Cache updated."
}
