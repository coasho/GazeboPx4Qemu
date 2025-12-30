set __LA_BINDIR=/usr/lib/lapack

set __LA_PATH=($path:q $__LA_BINDIR:q)
foreach __LA_F ($path:q)
    if ( "$__LA_F" == "$__LA_BINDIR" ) then
        set __LA_PATH=($path:q)
        break
    endif
end
set path=($__LA_PATH:q)
unset __LA_BINDIR
unset __LA_PATH
