source /usr/share/cachyos-fish-config/cachyos-config.fish

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end
fish_add_path ~/.npm-global/bin

# GitHub MCP plugin auth — pulls token from gh keyring
if status is-interactive; and type -q gh
    set -gx GITHUB_PERSONAL_ACCESS_TOKEN (gh auth token 2>/dev/null)
end

# Start an interactive OpenCode session with concise model and effort flags.
function opencode
    set -l model
    set -l effort
    set -l passthrough

    while test (count $argv) -gt 0
        switch $argv[1]
            case --m
                if test (count $argv) -lt 2
                    echo 'opencode: --m requires luna, sol, terra, or deepseek' >&2
                    return 2
                end
                set model $argv[2]
                set argv $argv[3..-1]
            case --e
                if test (count $argv) -lt 2
                    echo 'opencode: --e requires low, medium, high, xhigh, or max' >&2
                    return 2
                end
                set effort $argv[2]
                set argv $argv[3..-1]
            case '*'
                set -a passthrough $argv[1]
                set argv $argv[2..-1]
        end
    end

    if test -z "$model"; and test -z "$effort"
        command opencode $passthrough
        return
    end

    switch $model
        case luna sol terra
            set model openai/gpt-5.6-$model
        case deepseek
            set model opencode/deepseek-v4-flash-free
        case ''
            set model openai/gpt-5.6-terra
        case '*'
            echo 'opencode: --m requires luna, sol, terra, or deepseek' >&2
            return 2
    end

    if test "$model" = opencode/deepseek-v4-flash-free
        switch $effort
            case high max
            case ''
                set effort high
            case '*'
                echo 'opencode: DeepSeek --e requires high or max' >&2
                return 2
        end
        command opencode run --interactive --model $model --variant $effort $passthrough
        return
    end

    switch $effort
        case low medium high xhigh max
        case ''
            set effort high
        case '*'
            echo 'opencode: --e requires low, medium, high, xhigh, or max' >&2
            return 2
    end

    command opencode run --interactive --model $model --variant $effort $passthrough
end

# opencode
fish_add_path /home/nethum/.opencode/bin

# druk
fish_add_path /home/nethum/.druk/bin
