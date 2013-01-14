# TODO :
1) Convert this file to markdown format (consider using http://oscargodson.github.com/EpicEditor/)
2) Improve and test the instructions.

Postgres Development Environment setup on Linux
===============================================

.) On CentOS, add testing repos to get latest version of git and gitk.

Download and place the following files in /etc/yum.repos.d/ , and then set the
enabled parameter to on for the testing repositories.

http://centos.karan.org/kbsingh-CentOS-Extras.repo
http://centos.karan.org/kbsingh-CentOS-Misc.repo


.) Install prerequisites

CentOS and siblings:
yum install screen git gitk gcc gdb make flex bison readline-devel libz-dev libssl-dev

Debian and siblings
apt-get install screen git gitk gcc gdb make flex bison libreadline-dev libz-dev libssl-dev

.) Install packages required to build EnterpriseDB

CentOS and siblings:
yum install libxml2-devel libxslt-devel

Debian and siblings
apt-get install libxml2-dev libxslt-dev

.) For CentOS 5, follow Greg's instructions to upgrade flex version

http://notemagnet.blogspot.com/2009/07/upgrading-flex-from-source-rpm-to.html

.) Apply dev configuration

git clone git://github.com/gurjeet/pg_dev_env.git

ls -A pg_dev_env | xargs -I ccc mv pg_dev_env/ccc ~/

.) Clone Postgres Git repo

mkdir -p ~/dev/
cd ~/dev/

git clone git://git.postgresql.org/git/postgresql.git postgres

.) Compile sources

cd ~/dev/postgres/

./configure --prefix=`pwd`/db --enable-debug --enable-cassert CFLAGS=-O0 --enable-depend \
&& make \
&& make install

This installs postgres in ~/dev/postgres/db/ . So when you start playing with different branches of source code this might not be idea, and you might want to change --prefix above.

