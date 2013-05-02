#!/usr/local/bin/bash

# variables to define for deploy
server=servername
user=username
environment=production
sites=( sitename1 sitename2 sitename3 ... )

for i in "${sites[@]}"
do
  sites_list="$sites_list $i"
done

echo "Deploying chowder for $user to $environment on $server..."
echo ""

echo "Pulling the latest changes from origin/$environment..."
su -l $user -c 'cd ~/oyster/;git pull'
echo ""

echo "Setting permissions for: $sites_list..."
for i in "${sites[@]}"
do
        su -l $user -c "cd ~/oyster/shared/;perl script/perm.pl -site $i"
done
echo ""

echo "Recompiling XSL for: $sites_list..."
for i in "${sites[@]}"
do
	su -l $user -c "cd ~/oyster/shared/;perl script/xslcompiler.pl -site $i"
done
echo ""

echo "Restarting fastcgi processes for: $sites_list..."
( for i in "${sites[@]}"
  do
	echo "restart $i:*"
  done
  echo "exit"
) | supervisorctl
echo ""

echo "Done."

exit 0
