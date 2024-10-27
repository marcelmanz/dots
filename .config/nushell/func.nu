# notes
def th [] {
    cd $"($env.HOME)/notes"
    nvim .
}

def zkn [note_title] {
    cd $"($env.HOME)/notes"
    zk new --title $note_title
}

def zko [] {
    cd $"($env.HOME)/notes"
    nvim -c 'ZkNotes'
}

def zkwo [] {
    cd $"($env.HOME)/notes"
    nvim ix07-work-to-do-s.md
}

def rgfind [file] { rg --files | rg $file }

# tmux
# def tpe [] { nu $"($env.HOME)/scripts/tmux/create-session.nu" own }
# def two [] { nu $"($env.HOME)/scripts/tmux/create-session.nu" work }

# This is not possible yet :(
# ls ~/.config/nushell/*.nu | each { |f| source $f.name }

def so [] { exec nu }

def colored_string [value, color: string] {
    $"(ansi ($color))($value)(ansi reset)"
}

# prompt related
def override_clones_dir_path [path] {
  let work_path = "/clones/work/"
  let pers_path = "/clones/pers/"
  let own_path  = "/clones/own/"

  if ($work_path in $path) {
    ($path | str replace $work_path "/work/")
  } else if ($pers_path in $path) {
    ($path | str replace $pers_path "/pers/")
  } else if ($own_path in $path) {
    ($path | str replace $own_path  "/own/")
  } else {
    $path
  }
}

def node_version [] {
  let node_version = (node -v)

  if ($node_version == "system" or ($node_version | is-empty)) {
    ""
  } else {
    colored_string $" 󰎙 ($node_version)" 'yellow_bold'
  }
}

def node_path [path: string] {
  if not (ls -a | rg 'package.json' | is-empty) {
    $path + (node_version)
  } else {
    $path
  }
}

def ruby_version [] {
  let ruby_version = (^rbenv version | str trim | str replace "ruby " "" | split row ' ' | get 0)
  $"(ansi red)  ($ruby_version)(ansi reset)"
}

def ruby_path [path: string] {
  if not (ls -a | rg 'Gemfile' | is-empty) {
    $path + (ruby_version)
  } else {
    $path
  }
}

def gb [] {
  let branch = (^git branch | fzy | xargs)

  if ($branch | is-empty) {
    print "No branch selected"
    return
  }

  ^git checkout $branch
}

def gbde [] {
  let branch = (^git branch | fzy | xargs)

  if ($branch | is-empty) {
    print "No branch selected"
    return
  }

  ^git branch -D $branch
}

def git-changes [] {
    ^git diff --exit-code
    if $env.LAST_EXIT_CODE == 1 {
        true
    } else {
        false
    }
}

def git-staged-changes [] {
    ^git diff --staged --exit-code
    if $env.LAST_EXIT_CODE == 1 {
        true
    } else {
        false
    }
}

def git_main_remote_branch [] {
    ^git remote show origin
    | lines
    | str trim
    | find --regex 'HEAD .*?[：: ].+'
    | first
    | str replace --regex 'HEAD .*?[：: ](.+)' '$1'
}

def get_clean_path [] {
    let home = $env.HOME
    let path_segment = $env.PWD
    let node_version = (node_version)
    let no_clones_path = override_clones_dir_path $path_segment
    let clean_path = $no_clones_path | str replace $home "~"
    $clean_path
}

def pos_git_path [path: string] {
  # TODO: use this
  # let git_status = get_git_status_table
  let branch = (do { ^git rev-parse --abbrev-ref HEAD } | complete | get stdout | str trim)

  if ($branch | is-empty) {
    $path
  } else {
    let current_branch = colored_string  (" 🌱 " + $branch) 'purple_bold'

    # if (git-changes) {
    #   $path + $current_branch + (colored_string " [!?] " 'red_bold')
    # } else {
      $path + $current_branch
    # }
  }
}

def get_dev_env_path [path:string] {
    let pos_ruby_path = ruby_path $path
    let pos_node_path = node_path $pos_ruby_path
    let post_git_path = pos_git_path $pos_node_path
    let git_status = ^starship module git_status

    $post_git_path + " " + $git_status
}

def last_command_duration [] {
  let duration = $env.CMD_DURATION_MS | into int

  let parsed_duration = $"($duration / 1000 | math round --precision 2)s"
  let minute_duration = $"($duration / 60000 | math round --precision 2)m"

  if ($duration > 60000) {
    $minute_duration
  } else {
    $parsed_duration
  }
  # } else if ($duration > 3600000) {
  #   let parsed_duration = $"($duration / 3600000 | math round --precision 2)h"
  # }
}

def colored_error_prompt [
  prompt: string,
  color=green_bold:string
] {
  if ($env.LAST_EXIT_CODE == 0) {
    colored_string $prompt $color
  } else {
    colored_string $prompt 'red_bold'
  }
}

def get_git_status_table [] {
  let git_status = (^git status --porcelain | lines)
  mut staged = []
  mut non_staged = []
  mut new_files = []
  mut deleted_files = []

  for status in $git_status {
    let $file = $status | split row ' ' | last

    if ($status | str starts-with 'M ') {
      $staged ++= $file
    } else if ($status | str starts-with ' M') {
      $non_staged ++= $file
    } else if ($status | str starts-with ' D') {
      $deleted_files ++= $file
    } else if ($status | str starts-with '??') {
      $new_files ++= $file
    }
  }

  {
    deleted_files: $deleted_files,
    new_files:     $new_files,
    non_staged:    $non_staged,
    staged:        $staged,
  }
}

# git add all and commit
def gac [message?: string] {
  let error = do { git add --all } | complete | get stderr | str trim

  if ($error | str contains "fatal: not a git repository") {
    print "Not a git repository"
    return
  }

  if ($message | is-empty) {
    ^git commit
  } else {
    ^git commit -m $message
  }
}

def git_log [number=5:int] {
    let log = git log --pretty=%h»¦«%s»¦«%aN»¦«%aE»¦«%aD -n $number
       | lines
       | split column "»¦«" commit subject name email date
       | upsert date {|d| $d.date | into datetime}

    $log
}

def git_log_by_date [number=25:int] {
  let log = git log --pretty=%h»¦«%s»¦«%aN»¦«%aE»¦«%aD -n $number
      | lines
      | split column "»¦«" commit subject name email date
      | upsert date {|d| $d.date
      | into datetime
      | format date '%Y-%m-%d'}
      | group-by date
      | transpose date count

  $log
}

def minivim [] {
  let config = (^ls ~/.config/nvim/minimal-configs/ | fzy)

  if $config == "" {
      echo "No minimal config selected"
      exit
  }

  ^nvim -u $config
}

def git_status_count [] {
  let statuses = (git status -s | lines)
  let counts = [
      { name: "M", count: ($statuses | str starts-with " M" | where $it == true | length) },
      { name: "A", count: ($statuses | str starts-with " A" | where $it == true | length) },
      { name: "D", count: ($statuses | str starts-with " D" | where $it == true | length) },
      { name: "R", count: ($statuses | str starts-with " R" | where $it == true | length) },
      { name: "C", count: ($statuses | str starts-with " C" | where $it == true | length) },
      { name: "U", count: ($statuses | str starts-with " U" | where $it == true | length) },
      { name: "??", count: ($statuses | str starts-with "??" | where $it == true | length) },
      { name: "!!", count: ($statuses | str starts-with "!!" | where $it == true | length) },
  ]
  let result = ($counts | each { |x| if $x.count == 0 { "" } else { $"($x.count) ($x.name)" }}) | where $it != "" |  str join " - "
  echo $result
}
