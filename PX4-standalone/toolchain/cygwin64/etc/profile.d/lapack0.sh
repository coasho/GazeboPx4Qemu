__LA_BINDIR=/usr/lib/lapack

# Check if the PATH variable is empty or not


if test -n "${PATH}"; then
  # PATH is not empty

  # Check if path is already in PATH
  if ! /bin/echo ${PATH} | /bin/grep -q "${__LA_BINDIR}" ; then
    # Path is not already in PATH, append it to PATH
    export PATH="${PATH}:${__LA_BINDIR}"
  fi
else
  # PATH is empty
  export PATH="${__LA_BINDIR}"
fi

unset __LA_BINDIR
