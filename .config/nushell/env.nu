$env.PATH = (
    $env.PATH
    | split row (char esep)
    | prepend '.local/bin'
    | prepend $"($env.HOME)/scripts"
)

$env.EDITOR = 'nvim'
$env.OPENAI_API_KEY = (pass show openai/api-key)
$env.HOMEBREW_NO_AUTO_UPDATE = 1
$env.RANDOM = (random int ..32767)
$env.MANPAGER = 'nvim +Man!'
$env.PAGER = 'less -FRX'

# $env.GITHUB_TOKEN = (pass show github/token)


# fnm support on cd
# if not (which fnm | is-empty) {
#   ^fnm env --json | from json | load-env
#   # Checking `Path` for Windows
#   let path = if 'Path' in $env { $env.Path } else { $env.PATH }
#   let node_path = if (sys).host.name == 'Windows' {
#     $"($env.FNM_MULTISHELL_PATH)"
#   } else {
#     $"($env.FNM_MULTISHELL_PATH)/bin"
#   }
#   $env.PATH = ($path | prepend [ $node_path ])
# }

# --------------------------------END OF FILE--------------------------------- #

# External sources

# zoxide init nushell | str replace "def-env" "def --env" --all | save -f ~/.zoxide.nu
zoxide init nushell | save -f ~/.zoxide.nu
nuit ~/.bash_aliases -o $"($nu.default-config-dir)/bash-alises.nu" | ignore
