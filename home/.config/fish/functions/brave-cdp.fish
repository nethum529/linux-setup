function brave-cdp --description 'Point chrome-devtools-axi at the running Flatpak Brave via local debugging'
    set -l port_file ~/.var/app/com.brave.Browser/config/BraveSoftware/Brave-Browser/DevToolsActivePort

    if not test -f $port_file
        echo "brave-cdp: no DevToolsActivePort at $port_file" >&2
        echo "brave-cdp: open brave://inspect/#remote-debugging and enable local debugging" >&2
        return 1
    end

    set -l port (head -1 $port_file)
    set -l path (tail -1 $port_file)

    if test -z "$port"; or test -z "$path"
        echo "brave-cdp: DevToolsActivePort is malformed" >&2
        return 1
    end

    set -gx CHROME_DEVTOOLS_AXI_BROWSER_URL "ws://127.0.0.1:$port$path"

    # the bridge caches the endpoint it started with, so recycle it
    chrome-devtools-axi stop >/dev/null 2>&1

    echo "brave-cdp: $CHROME_DEVTOOLS_AXI_BROWSER_URL"
end
