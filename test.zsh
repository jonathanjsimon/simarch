#!/usr/bin/zsh

test=( ("foo"), ("bar"), ("baz", "arg1") )

for ((i = 1; i <= $#test; i++));
do
    item=$test[i]
    print -r $item[0]
done