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
  selected_file=$(rg -l "$search_term" | fzf --preview "rg --color=always -C 10 $search_term {}")
  if [[ -n "$selected_file" ]]; then
    vim "$selected_file"
  fi
}

# Function to browse solution folders and cd or open in Rider
fzf_solution_dirs() {
  local selection key dir

  selection=$(rg --type-add 'solution:*.{sln,slnx}' --files -tsolution $SOURCE | sed 's|\\|/|g; s|/[^/]*$||' | sort -u | fzf --height=80% --border=sharp \
    --prompt='Solutions > ' \
    --bind='ctrl-a:select-all' \
    --bind='ctrl-x:deselect-all' \
    --header '
ENTER to cd | CTRL-O to open in Rider
CTRL-A to select all | CTRL-X to deselect all
' \
    --expect=ctrl-o
  )

  key=$(head -1 <<< "$selection")
  dir=$(tail -n +2 <<< "$selection")

  [[ -z "$dir" ]] && return

  if [[ "$key" == "ctrl-o" ]]; then
    local sln=$(find "$dir" -maxdepth 1 -type f \( -name "*.sln" -o -name "*.slnx" \) | head -1)
    [[ -n "$sln" ]] && start "$sln" && cd $dir
  else
    cd "$dir"
  fi
}

# ZLE widget wrapper for fzf_solution_dirs
fzf_solution_dirs_widget() {
  zle -I  # Invalidate current display
  fzf_solution_dirs
  zle reset-prompt
}

function fgf() {
	local -r prompt_add="Add > "
	local -r prompt_reset="Reset > "

	local -r git_root_dir=$(git rev-parse --show-toplevel)
	local -r git_unstaged_files="git ls-files --modified --deleted --other --exclude-standard --deduplicate $git_root_dir"

	local git_staged_files='git diff --cached --name-only'

	local -r git_reset="git reset -- {+}"
	local -r enter_cmd="($git_unstaged_files | grep -Fx {} && git add {+}) || $git_reset"

	local -r preview_status_label="[ Status ]"
	local -r preview_status="git status --short"

	local -r header=$(cat <<-EOF
		> CTRL-S to switch between Add Mode and Reset mode
		> CTRL-T for status preview | CTRL-F for diff preview | CTRL-B for blame preview
		> ALT-E to open files in your editor
		> ALT-C to commit | ALT-A to append to the last commit
		EOF
	)

	local -r add_header=$(cat <<-EOF
		$header
		> ENTER to add files
		> ALT-P to add patch
	EOF
	)

	local -r reset_header=$(cat <<-EOF
		$header
		> ENTER to reset files
		> ALT-D to reset and checkout files
	EOF
	)

	local -r mode_reset="change-prompt($prompt_reset)+reload($git_staged_files)+change-header($reset_header)+unbind(alt-p)+rebind(alt-d)"
	local -r mode_add="change-prompt($prompt_add)+reload($git_unstaged_files)+change-header($add_header)+rebind(alt-p)+unbind(alt-d)"

	eval "$git_unstaged_files" | fzf \
	--multi \
	--reverse \
	--no-sort \
	--with-shell 'zsh -c' \
	--prompt="Add > " \
	--preview-label="$preview_status_label" \
	--preview="$preview_status" \
	--header "$add_header" \
	--header-first \
	--bind='start:unbind(alt-d)' \
	--bind="ctrl-t:change-preview-label($preview_status_label)" \
	--bind="ctrl-t:+change-preview($preview_status)" \
	--bind='ctrl-f:change-preview-label([ Diff ])' \
	--bind='ctrl-f:+change-preview(git diff --color=always {} | sed "1,4d")' \
	--bind='ctrl-b:change-preview-label([ Blame ])' \
	--bind='ctrl-b:+change-preview(git blame --color-by-age {})' \
	--bind="ctrl-s:transform:[[ \$FZF_PROMPT =~ '$prompt_add' ]] && echo '$mode_reset' || echo '$mode_add'" \
	--bind="enter:execute($enter_cmd)" \
	--bind="enter:+transform:[[ \$FZF_PROMPT =~ '$prompt_add' ]] && echo 'reload($git_unstaged_files)' || echo 'reload($git_staged_files)'" \
	--bind="enter:+refresh-preview" \
	--bind='alt-p:execute(git add --patch {+})' \
	--bind="alt-p:+reload($git_unstaged_files)" \
	--bind="alt-d:execute($git_reset && git checkout {+})" \
	--bind="alt-d:+reload($git_staged_files)" \
	--bind='alt-c:execute(git commit)+abort' \
	--bind='alt-a:execute(git commit --amend)+abort' \
	--bind='alt-e:execute(${EDITOR:-vim} {+})' \
	--bind='f1:toggle-header' \
	--bind='f2:toggle-preview' \
	--bind='ctrl-y:preview-up' \
	--bind='ctrl-e:preview-down' \
	--bind='ctrl-u:preview-half-page-up' \
	--bind='ctrl-d:preview-half-page-down'
}
