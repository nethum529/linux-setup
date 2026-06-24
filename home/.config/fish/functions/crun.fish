function crun
    set -l name $argv[1]
    mkdir -p bin
    g++ -std=c++23 -Wall -Wextra -O2 -pthread $name.cpp -o bin/$name && ./bin/$name
end
