# This file is separated out from enterView.sh to make it usable in ~/.bashrc
# All `export` commands are in enterView.sh and this file is mainly for setting
# aliases.

# Function declarations

# Check if $PGDATA directory exists
_checkDATADir()
{
  if [ ! -d $PGDATA ] ; then
    echo ERROR: $PGDATA, no such directory 
    return 1;
  fi;

  return 0;
}

# It is a known bug that on MinGW's rxvt, psql's prompt doesn't show up; psql
# works fine, its just that the prompt is always missing, hence we have to
# start a new console and assign it to psql

  if [ X$MSYSTEM == "XMINGW32" ] ; then
    START=start
  else
    START=
  fi

  if [ ! -f $V/configure.in ] ; then
    echo "WARNING: Are you sure that $V is a source directory?"
  else
    grep -m 1 EnterpriseDB $V/configure.in 2>&1 > /dev/null
    if [[ $? == "0" ]]; then
      flavour="edb"
    else
      flavour=
    fi;
  fi;

  if [ X$flavour == "Xedb" ] ; then
	PGSUNAME=edb
    alias pgsql="$START edb-psql"
  else
	PGSUNAME=postgres
    alias pgsql="$START psql"
  fi

  alias pginitdb="                 $B/db/bin/initdb -D $PGDATA -U $PGSUNAME"
  alias pgstart=" _checkDATADir && $B/db/bin/pg_ctl -D $PGDATA -l $PGDATA/server.log -w start && pg_controldata $PGDATA | grep 'Database cluster state'"
  alias pgstatus="_checkDATADir && $B/db/bin/pg_ctl -D $PGDATA status"
  alias pgreload="_checkDATADir && $B/db/bin/pg_ctl -D $PGDATA reload"

  alias pgstop="pgstatus && $B/db/bin/pg_ctl -D $PGDATA stop"

  alias pgconfigure=" ( cd $B; $V/configure --prefix=$B/db --enable-debug --enable-cassert CFLAGS=-O0 --enable-depend ) "

  alias pgcscope=" ( cd $V; find -L ./src/ ./contrib/ -name *.[chyl] | xargs cscope -Rb ) "


