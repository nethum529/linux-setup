function kbinds --description 'Print a kitty terminal keybind cheatsheet'
    set -l hdr (set_color -o cyan)
    set -l key (set_color -o yellow)
    set -l txt (set_color normal)
    set -l dim (set_color brblack)

    echo "$hdr Tabs$txt"
    echo "  $key ctrl+shift+t       $txt new tab"
    echo "  $key ctrl+shift+q       $txt close tab (and all its splits)"
    echo "  $key F2                 $txt rename current tab"
    echo "  $key ctrl+shift+→ / ←   $txt next / previous tab"
    echo ""
    echo "$hdr Splits (windows)$txt"
    echo "  $key ctrl+shift+enter   $txt new split"
    echo "  $key ctrl+shift+w       $txt close current split"
    echo "  $key ctrl+shift+] / [   $txt focus next / previous split"
    echo "  $key ctrl+shift+r       $txt resize mode"
    echo ""
    echo "$hdr Layouts$txt"
    echo "  $key ctrl+shift+l       $txt cycle layout $dim(splits, stack, tall, fat, grid…)$txt"
end
