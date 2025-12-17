#Function to search for .sln files and open the selected one
fzf_open_sln() {
  result=$(rg --type-add 'solution:*.{sln,slnx}' --files -tsolution $SOURCE | fzf)

  [ -n "$result" ] && start "$result"
}

rgfzf() {
  local search_term="${1:-}"
  if [[ -z "$search_term" ]]; then
    echo "Usage: rgfzf <search_term>"
    return 1
  fi

  local selected_file
  selected_file=$(rg -l "$search_term" | fzf --preview "rg --color=always -C 3 $search_term {}")
  if [[ -n "$selected_file" ]]; then
    vim "$selected_file"
  fi
}
