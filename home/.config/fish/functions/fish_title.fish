function fish_title
    if set -q KITTY_TAB_TITLE
        echo $KITTY_TAB_TITLE
    else
        echo (prompt_pwd) - fish
    end
end
