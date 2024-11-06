source alias.nu
source bash-alises.nu
source func.nu
source colors.nu

use ~/clones/external/nupm/nupm/

# source external/get-weather.nu
# use ~/clones/forks/nu_scripts/custom-completions/mod.nu *
# use ~/clones/forks/nu_scripts/modules/rbenv/rbenv.nu


# let carapace_completer = {|spans|
#     carapace $spans.0 nushell ...$spans | from json
# }

let carapace_completer = {|spans: list<string>|
    carapace $spans.0 nushell ...$spans
    | from json
    | if ($in | default [] | where value =~ '^-.*ERR$' | is-empty) { $in } else { null }
}

let fish_completer = {|spans|
    fish --command $'complete "--do-complete=($spans | str join " ")"'
    | $"value(char tab)description(char newline)" + $in
    | from tsv --flexible --no-infer
}

let zoxide_completer = {|spans|
    $spans | skip 1 | zoxide query -l ...$in | lines | each {|line| $line | str replace $env.HOME '~' } | where {|x| $x != $env.PWD}
}

# This completer will use carapace by default
let external_completer = {|spans|
    let expanded_alias = scope aliases
    | where name == $spans.0
    | get -i 0.expansion

    let spans = if $expanded_alias != null {
        $spans
        | skip 1
        | prepend ($expanded_alias | split row ' ' | take 1)
    } else {
        $spans
    }

    match $spans.0 {
      # carapace completions are incorrect for nu
      # nu => $fish_completer
      # fish completes commits and branch names in a nicer way
      git => (if $spans.1 == "branch" { $fish_completer } else { $carapace_completer })
      # use zoxide completions for zoxide commands
      z | zi => $zoxide_completer
      __zoxide_z | __zoxide_zi => $zoxide_completer
      _ => $carapace_completer
    } | do $in $spans
}

$env.config = {
  color_config: $base16_theme

  edit_mode: vi
  show_banner: false
  table: {
    padding: { left: 0 right: 0 }
    # rounded basic compact compact_double light thin with_love reinforced heavy none other
    mode: none
   
  }
  filesize: {
    metric: true
  }
  cursor_shape: {
    vi_insert: underscore
    vi_normal: block
  }
  completions: {
      case_sensitive: false # set to true to enable case-sensitive completions
      quick: true           # set this to false to prevent auto-selecting completions when only one remains
      partial: true         # set this to false to prevent partial filling of the prompt
      algorithm: "prefix"   # prefix or fuzzy
      external: {
          max_results: 20
          enable: true
          completer: $external_completer
      }
  }
  menus: [
  {
    name: zoxide_menu
    only_buffer_difference: true
    marker: "| "
    type: {
        layout: columnar
        page_size: 20
    }
    style: {
        text: green
        selected_text: green_reverse
        description_text: yellow
    }
    source: { |buffer, position|
        zoxide query -ls $buffer
        | parse -r '(?p<description>[0-9]+) (?p<value>.+)'
    }
  }
   {
    name: completion_menu
    only_buffer_difference: false
    marker: ">> "
    type: {
      layout: columnar
      columns: 4
      col_width: 20   # Optional value. If missing all the screen width is used to calculate column width
      col_padding: 2
    }
    style: {
      text: { fg: "#ffffff" }
      selected_text: { fg: "#0c0c0c" bg: "#ffe500" attr: b}
      description_text: yellow
    }
  }
  ]
  keybindings: [
  {
    name: zoxide_menu
    modifier: control
    keycode: char_o
    mode: [emacs, vi_normal, vi_insert]
    event: [
      { send: menu name: zoxide_menu }
    ]
  }
  {
    name: completion_previous
    modifier: shift
    keycode: backtab
    mode: [vi_normal vi_insert emacs]
    event: { send: menuprevious }
  }
  # {
  #   name: reload
  #   modifier: control
  #   keycode: char_r
  #   mode: [emacs, vi_insert, vi_normal]
  #   event: {
  #       send: executehostcommand,
  #       cmd: "exec nu"
  #   }
  # }
 ]
 hooks: {
    pre_prompt: [{ ||
      let direnv = (direnv export json | from json)
      let direnv = if not ($direnv | is-empty) { $direnv } else { {} }
      $direnv | load-env
    }]
    env_change: {
      PWD: [{ |before, after|
        let is_node_dir = [.nvmrc .node-version] | path exists | any { |it| $it }
        if ('FNM_DIR' in $env) and $is_node_dir {
          fnm --log-level=quiet use
        }
      }]
    }
  }
}

def create_left_prompt [] {
    let clean_path = get_clean_path
    let dev_env_path = get_dev_env_path $clean_path

    $dev_env_path
}

def get_weather [location="Barcelona"] {
   curl -s $"wttr.in/$location?format=%t"
}

def create_right_prompt [] {
  let lc_duration = last_command_duration
  let time = date now | format date "%H:%M"
  let $duration_and_time = $"($lc_duration) - ($time)"
  # let weather = get_weather

  (colored_string $duration_and_time 'xterm_grey50')
  # + ' '  + (colored_string $weather 'xterm_blue')
}

$env.PROMPT_COMMAND = { create_left_prompt }
$env.PROMPT_COMMAND_RIGHT = { create_right_prompt }
$env.PROMPT_INDICATOR = {colored_error_prompt "\n> "}
$env.PROMPT_INDICATOR_VI_INSERT = {colored_error_prompt "\n[i]: "}
$env.PROMPT_INDICATOR_VI_NORMAL = {colored_error_prompt "\n[n]: " "blue_bold"}
$env.PROMPT_MULTILINE_INDICATOR = {colored_error_prompt ':> '}

# --------------------------------END OF FILE--------------------------------- #
# External sources

# use ~/.cache/starship/init.nu
# use external/fnm.nu
# source ~/.local/share/atuin/init.nu

source ~/.zoxide.nu
