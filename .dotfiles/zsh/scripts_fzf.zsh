#Function to search for .sln files and open the selected one
fzf_open_sln() {
  result=$(rg --type-add 'solution:*.{sln,slnx}' --files -tsolution $SOURCE | fzf)

  [ -n "$result" ] && start "$result"
}

