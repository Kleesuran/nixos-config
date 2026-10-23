fish_add_path ~/.local/bin

# Commands to run in interactive sessions can go here
if status is-interactive
    # No greeting
    set fish_greeting

    # Use starship
    function starship_transient_prompt_func
        starship module character
    end
    if test "$TERM" != "linux"
        # 仅在处于 Hyprland 桌面且非虚拟控制台(TTY/kmscon)、非远程或IDE环境时，使用 Hyprland 定制胶囊样式
        if test "$TERM" != "kmscon"; \
           and string match -qi "*Hyprland*" "$XDG_CURRENT_DESKTOP"; \
           and not set -q SSH_CONNECTION; \
           and not string match -qi "*vscode*" "$TERM_PROGRAM"; \
           and not string match -qi "*cursor*" "$TERM_PROGRAM"; \
           and not string match -qi "*windsurf*" "$TERM_PROGRAM"; \
           and not string match -qi "*zed*" "$TERM_PROGRAM"; \
           and not set -q ZED_TERM; \
           and not set -q VSCODE_INJECTION; \
           and not string match -qi "*JetBrains*" "$TERMINAL_EMULATOR"
            set -gx STARSHIP_CONFIG "$HOME/.config/starship_hyprland.toml"
        else
            set -gx STARSHIP_CONFIG "$HOME/.config/starship.toml"
        end
        starship init fish | source
        enable_transience
    end
    
    # Colors (only apply quickshell sequence override on native Hyprland starship theme)
    if test "$STARSHIP_CONFIG" = "$HOME/.config/starship_hyprland.toml" -a -f ~/.local/state/quickshell/user/generated/terminal/sequences.txt
        cat ~/.local/state/quickshell/user/generated/terminal/sequences.txt
    end

    # Aliases
    # kitty doesn't clear properly so we need to do this weird printing
    alias clear "printf '\033[2J\033[3J\033[1;1H'"
    alias celar "printf '\033[2J\033[3J\033[1;1H'"
    alias claer "printf '\033[2J\033[3J\033[1;1H'"
    alias pamcan pacman
    alias q 'qs -c ii'
    if test "$TERM" != "linux"
        alias ls 'eza --icons=auto'
    end
    if test "$TERM" = "xterm-kitty"
        alias ssh 'kitten ssh'
    end
end
set -gx BUN_INSTALL "$HOME/.bun"
set -gx PATH "$BUN_INSTALL/bin" $PATH
