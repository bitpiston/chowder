# ----------------------------------------------------------------------------
# Oyster source update script
# Updates Chowder's Oyster to the latest source checkout specified.
#
# You should probably set the default oyster and chowder path before using this.
# ----------------------------------------------------------------------------

use strict;
use warnings;

use File::Copy;

my ($oyster_path, $chowder_path) = @ARGV;

# Oyster source path (absolute with trailing slash)
$oyster_path = '/Users/jpingel/Development/projects/oyster/trunk/' unless defined $oyster_path;
print
# Chowder source path 
$chowder_path = '/Users/jpingel/Development/projects/chowder/trunk/' unless defined $chowder_path;

# Clean up generated XSL before copying
print "\nCleaning\'s Oyster source...\n";
chdir $oyster_path . 'shared/';
print `perl script/xslclean.pl`;
chdir $chowder_path;

# Update Chowder's Oyster
print "\nUpdating Chowder\'s Oyster source...\n";
copy_source($oyster_path, $chowder_path);

# Recursively reads a directory tree and updates files
sub copy_source {
    my ($oyster_dir, $chowder_dir, $depth) = @_;
    
    # default values
    $depth = 0 unless defined $depth;
    my $indent = "\t" x $depth;
    
    # Ignored files 
    my @ignored_files = ('.', '..', '.svn', 'config.pl', 'documentation', 'README.txt', 'tmp', 'files', 'logs', 'desktop.ini', 'thumbs.db', '.DS_Store');
    
    # add trailing slash to the directory if it doesn't have one
    $oyster_dir .= '/' unless $oyster_dir =~ m!/$!; 
    $chowder_dir .= '/' unless $chowder_dir =~ m!/$!; 

    # if the destination directory does not exist, create it    
    #unless (-d $chowder_dir) { mkdir $chowder_dir or error(); }
    
    opendir(my $dirhandle, $oyster_dir) or error();

    loop: while ( my $file = readdir($dirhandle) ) {
      
        # Make sure its not an ignored file/dir
        foreach (@ignored_files) { next loop if $file eq $_; }
        
        my $oyster_location = $oyster_dir . $file;
        my $chowder_location = $chowder_dir . $file;
        
        # if the file is a directory
        if (-d $oyster_location) { 
            
            # if the destination directory does not exist, create it    
            unless (-d $chowder_location) { mkdir($chowder_location) or error(); }
            
            # recurse down the directory
            print $indent . $file . "/ ...\n";
            copy_source($oyster_location, $chowder_location, $depth + 1);
            print $indent . "Done.\n";
        }

        # if the file is a file
        elsif (-f $oyster_location) {
            
            # remove an existing file if present
            if (-f $chowder_location) { unlink($chowder_location) or error(); }
            
            # copy the file
            print $indent . "Copying '$file' ... ";
            copy($oyster_location, $chowder_location) or error();
            print "Done.\n";
        }
    }
}

# used to indicate failure
sub error {
    print "$!\n";
    exit;
}

# Copyright BitPiston 2008