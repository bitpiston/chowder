# Working from your own project repository

Your sites, modules and libraries built on Oyster and including Chowder.


## Working with Branches

### One repo for multiple groups of sites sharing the same code base

####config.pl and server.pl for development

Since we have merged defender and bling svn repositories there will now be one config.pl to rule them all in your local file system for development. The easiest way to to deal with the different SQL credentials and database settings is to use environments:

```
# Specify a default site id and environment
my $default_site_id     = 'sitename';
my $default_environment = 'devel-groupname';
...
$config{'shared'}{'devel-groupname'} = {
  ...
    # Database
    'database'  => {
      ...
    },
  ...
}
$config{'shared'}{'devel-groupname'} = {
  ...
    # Database
    'database'  => {
      ...
    },
  ...
}
```

This will default to using the devel-groupname environment settings (including database settings) and the site instance sitename. To launch the development server with different environments and sites the syntax is:
```perl script/server.pl -environment devel-othergroup -site othersite```

### Branches and deployment

Ideally we have four branches in total:
* development
* staging
* production
* master

These are all pretty self explanitory other than master. Commit your development work to development, anything ready for testing on the staging server you commit to staging, same goes for production and once code is proven to work on production we commit it to master where we always have a good working base.

When you are ready to switch from one branch to another you will need to pull the target branch and merge your current branch into it.

Sparse checkouts are used on staging and production environments to only checkout the relevant site and shared directories.

#### Creating a branch

If you need to work on experimental features or something that might break the development branch you can always create a branch from your current HEAD with: ```git checkout -b my-branch origin/my-branch```

If you only want this branch to be local and never intend to push it to the server you can just do ```git checkout -b my-branch```

#### Deploying from a branch

To deploy from a specific branch without checking out every branch and only checking out the required directories:

```
mkdir $BRANCH
cd $BRANCH
git init
git remote add -t $BRANCH -f origin ssh://git@github.com/BitPiston/chowder.git
git config core.sparsecheckout true
echo /.gitignore >> .git/info/sparse-checkout
echo shared/ >> .git/info/sparse-checkout
echo chowder/ >> .git/info/sparse-checkout
echo yourproject/ >> .git/info/sparse-checkout
echo $YOUR_SITE/ >> .git/info/sparse-checkout
git checkout $BRANCH
```

You will need to add a ssh key to deploy keys on github for your project repository for the user you are deploying from. For example when deploying bitpiston.com I ```su bitpiston``` which has a ssh key added to deploy keys. For more see github.com's [generating ssh keys](https://help.github.com/articles/generating-ssh-keys) and [managing deploy keys](https://help.github.com/articles/managing-deploy-keys).

For existing deployments we have a shell script in the root directory to pull in the latest changes, recompile the stylesheets for all sites in the instance, repair permissions, etc. You can execute it via ```sh deploy.sh``` from the instance directory on the server.

If you modify your sparse checkout settings later you will then need to ```git read-tree -mu HEAD``` to update your repository.

#### Merging between branches

This should be as simple as: 
```
git checkout <branch we are merging into>
git merge <branch we are merging from>
```
And write your commit message. ```R``` to replace text, ```i``` to insert on a line, ```d``` to delete a line and ```:wq``` to save from vi. ```:q!``` to abort without saving.

You can undo changes before commiting them with ```git reset HEAD <path/file>``` or remove all changes from the entire branch with ```git checkout -- .```.

If you encounter a conflict you will have to manually resolve it by editing the affected files. Search for >>>, <<< and === to find all the diffs and correct as required. If you just want to overwrite one version, or its a binary file where diffs are useless, you can overwrite one with:

Overwrite current branch with version from branch you are merging in: 
```git checkout --theirs -- path/to/file```

Keep our current branch's version and discard the one we are merging in: 
```git checkout --ours -- path/to/file```

#### Contributing and updating from upstream 
The upstream is: [BitPiston/Oyster](https://github.com/BitPiston/Oyster) -> [BitPiston/Chowder](https://github.com/BitPiston/Chowder)

Your immediate upstream being Chowder and Chowder's upstream being Oyster. 

##### Pulling from upstream

##### Maintaining commit history

It is probably nicer to add chowder as a remote named chowder rather than using the upstream remote which is a little less clear.

If the shared directory upstream was a new addition to your repository you can do:
```
git fetch upstream/master
git merge -s ours --no-commit --squash upstream/master
git read-tree --prefix=shared/ -u upstream/master:shared
```
```--squash``` will merge all the history into one change. Without it you would pull in all the individual history for the commits which might be a bit much to dig through in logs. You can commit and push after this.

More details are available from [stackoverflow: how do I merge a subdirectory in git?](http://stackoverflow.com/questions/1214906/how-do-i-merge-a-sub-directory-in-git) and [github: working with subtree merge](https://help.github.com/articles/working-with-subtree-merge).

After that its much easier to pull changes for that directory:

```
git pull -s subtree upstream master:shared
```
###### Ignoring history

This will grab the changes to the files and ignore any commit history. You probably want to do this because its much easier but please make a relevant commit message based on the history you are ignoring if possible.

```
git checkout <source_branch> <paths>...
```

Full example of how nice this works:
```
$ git checkout upstream/master shared
$ git status
# On branch master
# Changes to be committed:
#   (use "git reset HEAD <file>..." to unstage)
#
#  modified:   shared/modules/user.pm
#  modified:   shared/oyster.fcgi
#	modified:   shared/oyster.pl
#
```
At this point you could commit the changes from upstream/master's shared subtree you just pulled into origin/master (or whatever branch you are currently on).

NOTE: I haven't tested this but it should be able to merge if it doesn't already by default. One would hope its not just overwritting. ;)

##### Pushing to upstream

It is the reverse of what you did above to pull from upstream. If you want to just pull a specific commit use the following:
```
git checkout -b upstream upstream/master
git cherry-pick sha1
git push upstream HEAD:master
```
You can use this to push changes between branches as well but I do not recommend it. Each merge of a branch with cherry picks will end up with piles of the same commit in history getting progressively worse from staging -> production -> master. merge makes for much friendly history.

## Code guidelines, repository management and issue tracking

### Style guide

Tabs are four spaces. 

Use perl best practices and your best judgement – existing core code is a great example.

### Deleting code

When commenting out code temporarily while working on bug fixes or experimental replacements comment why its commented out. Once your new code is proven to be good delete your commented out code to avoid cluttering the source with old confusing junk.

### Git jargon
 * [Git documentation](http://git-scm.com/docs)
 * [Git book](http://git-scm.com/book)
 * [github help](https://help.github.com/)

#### upstream
The repository we forked or based some of our repository on. It is just like any other remote repistory we add to git.

#### subtree
A subdirectory of a repository.

#### git pull
Essentially your equivelant to svn's update. It will retrieve the latest updates and attempt to automatically merge them. Also a shortcut to ```git fetch``` and then ```git merge```.

#### git push
Sends your commits to the remote. Default is to the remote origin and the currently checked out branch.

#### git commit
Almost exactly like svn except you have to first ```git add <file/dir>``` to construct your commit. You can use ```git commit -am "commit message"``` to automatically add all changed/new files. You will then need to use ```git push``` to send it to the server.

#### git merge
* ```-s ours``` will auto resolve conflicts with your working directory's source.
*  ```-s theirs``` will auto resolve conflicts with the target branch's source.
* ```--no-commit``` will not automatically commit the result of the merge. Useful for picking out only some parts of a merge and discarding the rest.
* ```--squash``` will collapse all the history into one commit message instead of maintaing the individual commits.

#### git stash
Unlike subversion git will not let you switch to another branch with uncommited changes or untracked files. You will probably encounter times where you need to switch to another branch and your current working directory might not be ready for a commit – enter git stash. To store your changes: ```git stash``` -- you can then switch to another branch and once back to your branch to reapply changes: ```git stash apply```. 

### Recommended reading for git

http://codeinthehole.com/writing/pull-requests-and-other-good-practices-for-teams-using-github/
