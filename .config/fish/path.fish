# set -xg PNPM_HOME "$HOME/Library/pnpm"
# switch "$PATH"
#     case ":$PNPM_HOME:"
#         # Do nothing
#     case '*'
#         fish_add_path $PNPM_HOME
# end

if test -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
    source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
end

fish_add_path /home/$USER/scripts/
fish_add_path /home/$USER/go/bin
fish_add_path /home/$USER/.local/share/bob/nvim-bin
