#!/bin/bash

# This file is typically supposed to be invoked using bash builtin 'source',

# It can also be invoked as
# ./this_script some_command_or_function space_delimited_parameters
#
# For example:
# setupDevEnv.sh pgconfigure --with-bonjour
#
# where pgconfigure is a function defined in this script. The above command will
# invike pgconfigure() function with parameter --with-bonjour.
#
# This is helpful in situations where an IDE (eg. NetBeans) allows you to
# execute scripts with parameters to do some custome action.

# This is where all the source code repositories are created
vxzDEV_DIR=~/dev

# Setup $CDPATH so that we can easily switch to directories under the
# development directory.
CDPATH=${CDPATH}:${vxzDEV_DIR}

# Set environment variables needed by the pg* functions below
vxzSetVariables()
{
	# This is where all the build output will be generated
	vxzBLD=${vxzDEV_DIR}/builds/

	vxzSetBuildDirectory
	vxzSetPrefix

	vxzSaved_PGDATA=$PGDATA
	vxzSetPGDATA

	vxzSetPGFlavor
	vxzSetPSQL
	vxzSetPGSUNAME

	vxzSaved_CSCOPE_DB=$CSCOPE_DB
	# cscope_map.vim, a Vim plugin, uses this environment variable
	export CSCOPE_DB=$vxzBLD/$vxzBRANCH/cscope.out

	vxzSaved_PATH=$PATH
	export PATH=$vxzPREFIX/lib:$vxzPREFIX/bin:/mingw/lib:$PATH

	# This will do its job in VPATH builds, and nothing in non-VPATH builds
	mkdir -p $B

	# This will do its job in non-VPATH builds, and nothing in VPATH builds
	mkdir -p $vxzPREFIX
}

vxzInvalidateVariables()
{
	unset vxzBLD

	unset B
	unset vxzPREFIX
	unset vxzFLAVOR
	unset vxzPSQL
	unset vxzPGSUNAME

	if [ "x$vxzSaved_PATH" != "x" ] ; then
		export PATH=$vxzSaved_PATH
	fi
	unset vxzSaved_PATH

	if [ "x$vxzSaved_PGDATA" != "x" ] ; then
		PGDATA=$vxzSaved_PGDATA
	else
		unset PGDATA
	fi
	unset vxzSaved_PGDATA

	if [ "x$vxzSaved_CSCOPE_DB" != "x" ] ; then
		export CSCOPE_DB=$vxzSaved_CSCOPE_DB
	else
		unset CSCOPE_DB
	fi
	unset vxzSaved_CSCOPE_DB

	unset vxzBRANCH
}

#If return code is 0, $vxzBRANCH will contain branch name.
vxzSetGitBranchName()
{
	vxzBRANCH=`git branch | grep \* | grep -v "\(no branch\)" | cut -d ' ' -f 2`

	if [ "x$vxzBRANCH" = "x" ] ; then
		echo WARNING: Could not get a branch name
		return 1
	fi

	return 0
}

vxzDetectBranchChange()
{
	vxzSetPGFlavor >/dev/null 2>&1

	if [ $? -ne 0 ] ; then
		echo Not in Postgres sources 1>&2
		vxzInvalidateVariables
		return 1
	fi

	local vxzSAVED_BRANCH_NAME=$vxzBRANCH

	vxzSetGitBranchName

	if [ $? -ne 0 ] ; then
		return 1
	fi

	if [ "x$vxzSAVED_BRANCH_NAME" != "x$vxzBRANCH" ] ; then
		vxzInvalidateVariables
		vxzSetVariables
	fi

	return 0
}

# set $B to the location where builds should happen
vxzSetBuildDirectory()
{
	if [ "x$vxzBRANCH" = "x" ] ; then
		vxzSetGitBranchName
	fi

	if [ $? -ne 0 ] ; then
		return 1
	fi

	# If the optional parameter is not provided
	if [ "x$1" = "x" ] ; then
		# $vxzBLD is set at the beginning of this file
		export B=`cd $vxzBLD/$vxzBRANCH; pwd`
	else
		export B=`cd $1; pwd`
	fi

	return 0
}

# Set Postgres' installation prefix directory
vxzSetPrefix()
{
	if [ "x$vxzBRANCH" = "x" ] ; then
		vxzSetGitBranchName
	fi

	if [ $? -ne 0 ] ; then
		return 1
	fi

	# We're not using $B/db here, since in non-VPATH builds $B is the same as
	# source directory, and we don't want to it to be there.
	vxzPREFIX=$vxzBLD/$vxzBRANCH/db

	return 0
}

#Set $PGDATA
vxzSetPGDATA()
{
	if [ "x$vxzPREFIX" = "x" ] ; then
		vxzSetPrefix
	fi

	if [ $? = "0" ] ; then
		# If the optional parameter is not provided
		if [ "x$1" = "x" ] ; then
			PGDATA=$vxzPREFIX/data
		else # .. use the data directory provided by the user
			PGDATA=`cd $1; pwd`
		fi

		return 0
	fi

	return 1
}

# Check if $PGDATA directory exists
vxzCheckDATADirectoryExists()
{
  if [ ! -d $PGDATA ] ; then
    return 1;
  fi;

  return 0;
}

vxzSetSTARTShell()
{
	# It is a known bug that on MinGW's rxvt, psql's prompt doesn't show up; psql
	# works fine, it's just that the prompt is always missing, hence we have to
	# start a new console and assign it to psql
	if [ X$MSYSTEM = "XMINGW32" ] ; then
		vxzSTART='start '
	else
		vxzSTART=' '
	fi

	return 0
}

vxzSetPGFlavor()
{
	local src_dir

	local git_dir=$(git rev-parse --git-dir 2>/dev/null) || return 1

	src_dir=`cd $git_dir/../; pwd`

	if [ ! -f $src_dir/configure.in ] ; then
		echo "WARNING: Are you sure that $src_dir is a Postgres source directory?" 1>&2
		return 1
	fi

	# If the configure.in file contains the word EnterpriseDB, then we're
	# we're working with EnterpriseDB sources.
	grep -m 1 EnterpriseDB $src_dir/configure.in 2>&1 > /dev/null
	if [ $? -eq 0 ] ; then
		vxzFLAVOR="edb"
		return 0
	fi

	# If the configure.in file contains the word PostgreSQL, then we're
	# we're working with Postgres sources.
	grep -m 1 PostgreSQL $src_dir/configure.in 2>&1 > /dev/null
	if [ $? -eq 0 ] ; then
		vxzFLAVOR="postgres"
		return 0
	fi

	return 1
}

vxzSetPSQL()
{
	if [ "x$vxzFLAVOR" = "x" ] ; then
		vxzSetPGFlavor
	fi

	if [ "x$vxzFLAVOR" = "xpostgres" ] ; then
		vxzPSQL=psql
	elif [ "x$vxzFLAVOR" = "xedb" ] ; then
		vxzPSQL=edb-psql
	fi
}

vxzSetPGSUNAME()
{
	if [ "x$vxzFLAVOR" = "x" ] ; then
		vxzSetPGFlavor
	fi

	if [ "x$vxzFLAVOR" = "xpostgres" ] ; then
		vxzPGSUNAME=postgres
	elif [ "x$vxzFLAVOR" = "xedb" ] ; then
		vxzPGSUNAME=edb
	fi
}

##########
# The real commands supposed to be used by the user
#########

pgsql()
{
	vxzDetectBranchChange || return $?

	# This check is not part of vxzDetectBranchChange() because a change in
	# branch does not affect this variable
	if [ "x$vxzSTART" = "x" ] ; then
		vxzSetSTARTShell
	fi

	# By default connect as superuser. This will be overridden if the user calls
	# calls this function as `pgsql -U someothername`
	$vxzSTART$vxzPREFIX/bin/$vxzPSQL -U $vxzPGSUNAME "$@"

	local ret_code=$?

	# ~/.psqlrc changes the terminal title, so change it back to something
	# sensible.
	# Disabling this for now, since it doesn't always work, and in fact this
	# echo emits unnecessary output in log files, or in `less` scrolling.
	#echo -en '\033]2;Terminal\007'

	return $ret_code
}

pginitdb()
{
	vxzDetectBranchChange || return $?

	$vxzPREFIX/bin/initdb -D $PGDATA -U $vxzPGSUNAME
}

pgstart()
{
	vxzDetectBranchChange || return $?

	vxzCheckDATADirectoryExists

	if [ $? -ne 0 ] ; then
	    echo ERROR: \$PGDATA does not exist\; $PGDATA, no such directory
		return 1
	fi

	{
	# Set $PGUSER to DB superuser's name so that `pg_ctl -w` can connect to
	# instance, to be able to check its status

	local PGUSER=$vxzPGSUNAME
	export PGUSER

	# use pgstatus() to check if the server is already running
	pgstatus || $vxzPREFIX/bin/pg_ctl -D $PGDATA -l $PGDATA/server.log -w start "$@"
	}

	# Record pg_ctl's return code, so that it can be returned as return value
	# of this function.
	local ret_value=$?

	$vxzPREFIX/bin/pg_controldata $PGDATA | grep 'Database cluster state'

	return $ret_value
}

pgstatus()
{
	vxzDetectBranchChange || return $?

	vxzCheckDATADirectoryExists

	if [ $? -ne 0 ] ; then
	    echo ERROR: \$PGDATA not set\; $PGDATA, no such directory
		return 1
	fi

	$vxzPREFIX/bin/pg_ctl -D $PGDATA status

	return $?
}

pgreload()
{
	vxzDetectBranchChange || return $?

	vxzCheckDATADirectoryExists

	if [ $? -ne 0 ] ; then
	    echo ERROR: \$PGDATA not set\; $PGDATA, no such directory
		return 1
	fi

	$vxzPREFIX/bin/pg_ctl -D $PGDATA reload

	return $?
}

pgstop()
{
	vxzDetectBranchChange || return $?

	# Call pgstatus() to check if the server is running.
	pgstatus && $vxzPREFIX/bin/pg_ctl -D $PGDATA stop "$@"
}

pgconfigure()
{
	vxzDetectBranchChange || return $?

	local src_dir

	if [ "x$GIT_DIR" != "x" ] ; then
		src_dir=$GIT_DIR/../
	else
		src_dir=`pwd`
	fi

	( cd $B; $src_dir/configure --prefix=$vxzPREFIX --enable-debug --enable-cassert CFLAGS=-O0 --enable-depend --enable-thread-safety --with-openssl "$@" )

	return $?
}

pgmake()
{
	vxzDetectBranchChange || return $?

	# Append "$@" to the command so that we can do `pgmake -C src/backend/`, or
	# anything similar. `make` allows multiple -C options, and does the right thing
	make --no-print-directory -C "$B" "$@"

	return $?
}

pgcscope()
{
	vxzDetectBranchChange || return $?

	local src_dir

	if [ "x$GIT_DIR" != "x" ] ; then
		src_dir=$GIT_DIR/../
	else
		src_dir=`pwd`
	fi

	local vpath_src_dir

	#  If working in VPATH build
	if [ $B = `cd $vxzBLD/$vxzBRANCH; pwd` ] ; then
		vpath_src_dir=$B/src/

		# If the src/ directory under build directory doesn't exist yet (this
		# may happen in VPATH builds when pgconfigure hasn't been run yet), then
		# don't use this variable.
		if [ ! -d $vpath_src_dir ] ; then
			vpath_src_dir=
		fi
	else
		vpath_src_dir=
	fi

	# Emit a list of all source files, and make cscope consume that list from stdin
	( cd $src_dir; find ./src/ ./contrib/ $vpath_src_dir -type f -iname "*.[chyl]" -or -iname "*.[ch]pp" | cscope -Rb -f $CSCOPE_DB -i - )
}

# unset $GIT_DIR
pgUnsetGitDir()
{
	unset GIT_DIR
}

# Set $GIT_DIR. If provided with a parameter, set the variable to that directory
# else set the variable to `pwd`
pgSetGitDir()
{
	if [ "x$1" != "x" ] ; then
		GIT_DIR=`cd "$1"; pwd`/.git/
	else
		GIT_DIR=`pwd`/.git/
	fi

	export GIT_DIR
}

# All the functions defined in this file are available to interactive shells,
# but not available to non-interactive (n-i) shells since n-i shells do not
# process .bashrc or .bash_profile files.
#
# But n-i shells 'source' the file named in $BASH_ENV. So for n-i shells we
# setup $BASH_ENV. Do note that we do this only if $BASH_ENV is not already set,
# because otherwise we may be stomping on someone else's feet.
if [ "x$BASH_SOURCE" != "x" ] ; then
	if [ "x$BASH_ENV" = "x" ] ; then

		# Resolve file name to absolute path
		vxztmpf=$(basename $BASH_SOURCE)
		vxztmpd=$(dirname $BASH_SOURCE)
		vxztmpp=$(cd $vxztmpd; pwd)

		export BASH_ENV=$vxztmpp/$vxztmpf

		unset vxztmpf vxztmpd vxztmpp
	#else
		#echo Not setting \$BASH_ENV since it is already set \(maybe by someone else\) 2>&1
	fi
fi

# Show a list of running Postgres processes.
function pgshowprocesses()
{
	# Exclude the 'grep' processes from the list
	ps faux | grep -vw grep | grep -w postgres
}

# append branch detection code to $PROMPT_COMMAND so that we can detect Git
# branch change ASAP.
if [ "x$PROMPT_COMMAND" != "x" ] ; then
	# Append a semicolon only if the variable is already populated, otherwise
	# a semicolon at the beginning of $PROMPT_COMMAND causes an error.
	PROMPT_COMMAND=${PROMPT_COMMAND}\;
fi
PROMPT_COMMAND=${PROMPT_COMMAND}'vxzDetectBranchChange >/dev/null 2>&1'

if [ "x$1" != "x" ] ; then
	command="$1"
	shift
	eval "$command" "$@"
	unset command
fi
