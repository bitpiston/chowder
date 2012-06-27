=xml
<document title="Forum Module">
    <synopsis>
        Forums. Bulletin board. Thing people post messages on.
    </synopsis>
    <warning>
        Work in progress.
    </warning>
    <todo>
        Unread/new threads/posts
    </todo>
    <todo>
        Hide/ignore threads
    </todo>
    <todo>
        Confirmation redirects
    </todo>
    <todo>
        Merge and split threads
    </todo>
    <todo>
        Manage forums: create, edit, delete, reorder...
    </todo>
    <todo>
        Do this last:
        Replace bbcode parsing of post body with a cache'd copy in the database?
        Parsing the bbcode for the posts is about 0.1 seconds of extra work!
    </todo>
    <todo>
        File attachements
    </todo>
=cut

package forums;

# import libraries
use oyster 'module';
use exceptions;

# import modules
use user;

our %forums;
my $new_reply_notify;

=xml
    <function name="hook_load">
        <synopsis>
            Loads forums and prepares queries to be used later.
        </synopsis>
        <note>
            This uses event::register_hook() to execute at the right times.
        </note>
    </function>
=cut

event::register_hook('load', 'hook_load');
sub hook_load {
    our $increment_totals = $DB->prepare("UPDATE ${DB_PREFIX}forums SET posts = posts + 1 WHERE id = ? LIMIT 1", $forum_id);
    
    our $exists_notify = $DB->prepare("SELECT * FROM ${module_db_prefix}notify WHERE user_id = ? and thread_id = ? LIMIT 1");
    our $insert_notify = $DB->prepare("INSERT INTO ${module_db_prefix}notify (user_id, thread_id) VALUES (?, ?)");
    our $delete_notify = $DB->prepare("DELETE FROM ${module_db_prefix}notify WHERE user_id = ? and thread_id = ? LIMIT 1");
    
    # load forums
    _cache_forums();
    
    # every 15 minutes clean up old activity
    ipc::do_periodic(900, 'forums', '_clean_activity');
}

=xml
    <function name="hook_module_admin_menu">
        <synopsis>
            Contextual admin menu. Called when this module's admin menu is printed.
        </synopsis>
        <note>
            This uses event::register_hook() to execute at the right times.
        </note>
    </function>
=cut

event::register_hook('module_admin_menu', 'hook_module_admin_menu');
sub hook_module_admin_menu {
    my $item = menu::add_item('menu' => 'admin', 'label' => 'Forums', 'url' => $module_admin_base_url, 'require_children' => 1);
    menu::add_item('parent' => $item, 'label' => 'Configuration', 'url' => $module_admin_base_url . 'config/') if $PERMISSIONS{'forums_admin_config'};
}

=xml
    <function name="hook_module_admin">
        <synopsis>
            Contextual admin menu. Called when the admin menu is printed (after the module admin menu).
        </synopsis>
        <note>
            This uses event::register_hook() to execute at the right times.
        </note>
    </function>
=cut

event::register_hook('admin_menu', 'hook_admin_menu');
sub hook_admin_menu {
    menu::add_item('parent' => $_[0], 'label' => 'Forums', 'url' => $module_admin_base_url)
        if ($REQUEST{'module'} ne 'forums' and $PERMISSIONS{'forums_admin_config'});
}

=xml
    <function name="hook_admin_center_modules_menu">
        <synopsis>
            Administration Center Menus.
        </synopsis>
        <note>
            This uses event::register_hook() to execute at the right times.
        </note>
    </function>
=cut

event::register_hook('admin_center_modules_menu', 'hook_admin_center_modules_menu');
sub hook_admin_center_modules_menu {
    menu::add_item('parent' => $_[0], 'label' => 'Forums', 'url' => $module_admin_base_url) if $PERMISSIONS{'forums_admin_config'};
}

=xml
    <function name="view_index">
        <synopsis>
            Displays the forum index/overview.
        </synopsis>
    </function>
=cut

sub view_index {
    user::require_permission('forums_view');
    style::include_template('view_index');    
    user::print_module_permissions('forums');
    
    # Print the forum node
    print qq~\t<forums action="view_index">\n~;
    
    # Print the forums and their subforums
    _print_forums();
    
    # Users activity
    _user_activity('overview');
    
    # Close the forum node
    print "\t</forums>\n";
}

=xml
    <function name="view_forum">
        <synopsis>
            Displays an individual forum.
        </synopsis>
    </function>
=cut

sub view_forum {
    my $forum_id = $_[0];
    
    user::require_permission('forums_view');
    user::print_module_permissions('forums');    

    # Get the forum by id if it exists or error
    throw 'request_404' if !exists $forums{ $forum_id };
    my ($forum_title, $forum_description, $forum_parent) = ($forums{ $forum_id }->{'name'}, $forums{ $forum_id }->{'description'}, $forums{ $forum_id }->{'parent_id'});
    
    # Goto actions
    goto &create_thread if $INPUT{'a'} eq "create";
    
    # Get the page number if it exists and is numeric
    my $page = $INPUT{'p'} if string::is_numeric($INPUT{'p'});
    
    style::include_template('view_forum');
    
    # Check how many pages of threads the forum has
    $pages = math::ceil($forums{ $forum_id }->{'threads'} / $config{'threads_per_page'});
    
    # Print the module node
    my $attributes = defined $page ? ' page="'. $page .'"' : ' page="1"';
    print qq~\t<forums action="view_forum" forum_id="$forum_id"$attributes>\n~;
    
    # Print the parent forum nodes and set the indent level
    my ($depth, $closing_nodes) = _print_parents($forum_id);
    my $indent = "\t" x $depth;
    print qq~\t$indent<forum id="$forum_id" name="$forum_title" parent_id="$forum_parent" description="$forum_description" pages="$pages">\n~;    
    
    # Print sub forums if any
    _print_forums($forum_id, $depth);
    
    # Set the thread starting count
    my $limit_from = defined $page ? ($page * $config{'threads_per_page'}) - $config{'threads_per_page'} : 0;
    
    # Retrieve the threads for this page and error if none
    my $query = $DB->query(
        "SELECT id, title, forum_id, author_id, author_name, date, lastpost_date, lastpost_id, lastpost_author, views, replies, sticky, locked, moved_from 
        FROM ${module_db_prefix}threads 
        WHERE forum_id = ? or moved_from = ? 
        ORDER BY sticky DESC, lastpost_date DESC 
        LIMIT $limit_from , $config{'threads_per_page'}", 
        $forum_id, $forum_id
    );
    throw 'request_404' if $query->rows() == 0;
    
    # Prepare to check for the user's posts in the threads
    my @threads;
    while ( my $thread = $query->fetchrow_arrayref() ) {
        
        # An array of arrays for the threads
        push @threads, [ @{$thread} ];
    }
    
    # Do thes threads contain posts by the user? Don't bother if the user is unregistered
    my %user_threads;
    if ($USER{'id'} != 0) {
        
        # Prepare a list of the thread ids
        my $threads = join ', ', map { $_->[0] } @threads;

        # Retrieve the thread ids 
        $query = $DB->query("SELECT thread_id FROM ${module_db_prefix}posts WHERE thread_id IN ($threads) AND author_id = ? GROUP BY thread_id", $USER{'id'});
        while ( my $post = $query->fetchrow_arrayref() ) {
            $user_threads{ $post->[0] } = 1;
        }
    }

    # Print the regular threads
    for my $thread (@threads) {
        my $attributes;        
        my $pages = math::ceil( ($thread->[10] + 1) / $config{'posts_per_page'} );  # Calculate how many pages the thread is
        my $lastpost_date = _pretty_dates($thread->[6]);                            # Calculate how long ago the last post was
        my $lastpost_ctime = datetime::from_unixtime($thread->[6]);                 # Last post date
        
        # Moved thread notice?
        $attributes .= ' moved="1" moved_from_id="'. $thread->[2] .'" moved_from_name="'. $forums { $thread->[2] }->{'name'} .'"' if $thread->[13] == $forum_id;
        
        # Is the thread author the user?
        $attributes .= ' mythread="1"' if $thread->[3] == $USER{'id'};
        
        # Thread contains posts by the user?
        $attributes .= ' myposts="1"' if defined $user_threads{ $thread->[0] };
        
        # Hot or not?
        $attributes .= ' hot="1"' if ( ($thread->[10] >= $config{'hot_posts_threshold'}) or ($thread->[9]) >= $config{'hot_views_threshold'} );
        
        print qq~\t\t$indent<thread id="$thread->[0]" title="$thread->[1]" parent_id="$thread->[2]" author_id="$thread->[3]" author_name="$thread->[4]" ctime="$thread->[5]" last_date="$lastpost_date" last_ctime="$lastpost_ctime" last_id="$thread->[7]" last_author="$thread->[8]" views="$thread->[9]" replies="$thread->[10]" sticky="$thread->[11]" locked="$thread->[12]" pages="$pages"$attributes />\n~;
    }
    
    # Close the thread, forum and parent nodes
    print "\t$indent</forum>\n" . $closing_nodes;
    
    # Users activity
    _user_activity('forum', --$depth, $forum_id, $forum_title);
    
    # Close the forums node
    print "\t</forums>\n";
}

=xml
    <function name="view_thread">
        <synopsis>
            Displays a thread.
        </synopsis>
        <todo>
            Retrieve author data for posts pending profiles
        </todo>
    </function>
=cut

sub view_thread {
    my $thread_id = $_[0];
    my $post_id = $_[1];
    
    user::require_permission('forums_view');
    user::print_module_permissions('forums');
    
    # Goto actions
    goto &create_post if $INPUT{'a'} eq "reply";
    goto &edit_thread if $INPUT{'a'} eq "edit";
    goto &delete_thread if $INPUT{'a'} eq "delete";
    
    # Get the thread by id if it exists or error
    my $query = $DB->query(
        "SELECT title, forum_id, author_id, author_name, lastpost_date, lastpost_id, lastpost_author, date, views, replies, sticky, locked 
        FROM ${module_db_prefix}threads 
        WHERE id = ? 
        LIMIT 1", 
        $thread_id
    );
    throw 'request_404' if $query->rows() == 0;
    my ($thread_title, $forum_id, $author_id, $author_name, $lastpost_date, $lastpost_id, $lastpost_author, $date, $views, $replies, $sticky, $locked) = @{$query->fetchrow_arrayref()};
        
    # Get the page number if it exists and is numeric
    my $page = $INPUT{'p'} if string::is_numeric($INPUT{'p'});

    style::include_template('view_thread');
    
    # Check how many pages of posts the thread has
    $pages = math::ceil(($replies + 1) / $config{'posts_per_page'});

    # Print the forum node
    my $attributes;
    $attributes .= defined $page ? ' page="'. $page .'"' : ' page="1"';
    $attributes .= ' post_id="'. $post_id .'"' if defined $post_id;
    print qq~\t<forums action="view_thread" thread_id="$thread_id" forum_id="$forum_id"$attributes>\n~;

    # Get the forum details by id
    my ($forum_title, $forum_description, $forum_parent) = ($forums{ $forum_id }->{'name'}, $forums{ $forum_id }->{'description'}, $forums{ $forum_id }->{'parent_id'});

    # Print the parent forum nodes and set the indent level
    my ($depth, $closing_nodes) = _print_parents($forum_id);
    my $indent = "\t" x $depth;
    print qq~\t$indent<forum id="$forum_id" name="$forum_title" parent_id="$forum_parent" description="$forum_description">\n~;
    
    # Print the thread node 
    print qq~\t\t$indent<thread id="$thread_id" title="$thread_title" author_id="$author_id" author_name="$author_name" last_date="$lastpost_date" last_id="$lastpost_id" last_author="$lastpost_author" ctime="$date" views="$views" replies="$replies" pages="$pages" sticky="$sticky" locked="$locked">\n~;

    # Retrieve the posts for this thread's page or error if none
    my $limit_from = ($page * $config{'posts_per_page'}) - $config{'posts_per_page'} if defined $page;
    my $limit = defined $limit_from ? $limit_from ." , ". $config{'posts_per_page'} : $config{'posts_per_page'};
    $query = $DB->query(
        "SELECT id, title, thread_id, author_id, author_name, body, date, edit_user, edit_reason, edit_date, edit_count, replyto, disable_signature, disable_smiles, disable_bbcode 
        FROM ${module_db_prefix}posts 
        WHERE thread_id = ? 
        ORDER BY date ASC 
        LIMIT $limit", 
        $thread_id
    );
    throw 'request_404' if $query->rows() == 0;
    
    # Prepare to retrieve the user data for the posts
    my (@posts, %authors);
    while ( my $post = $query->fetchrow_arrayref() ) {
        
        # An array of arrays for the posts
        push @posts, [ @{$post} ];
        
        # Add the author id avoiding duplicates
        $authors{ $post->[3] } = undef;
    }
    
    # Prepare a list of the users 
    my $authors = join ', ', keys %authors;

    # Retrieve the user groups and get the group name by user id
    $query = $DB->query("SELECT * FROM ${DB_PREFIX}user_permissions WHERE user_id IN ($authors) LIMIT ?", scalar keys %authors);
    while ( my $author = $query->fetchrow_arrayref() ) {
        $authors{ $author->[0] } = [ $user::groups{ $author->[1] }->{'name'} ];
    }
    
    # Retrieve the user data
    # Pending profiles! id, forum_posts, registered, location, avatar, signature
    $query = $DB->query("SELECT user_id, forum_posts, registered, location, avatar, signature FROM user_profiles WHERE user_id IN ($authors) LIMIT ?", scalar keys %authors);
    while ( my $author = $query->fetchrow_arrayref() ) {
        @author = @{$author};
        push @{ $authors{ shift @author } }, @author;
    }

    # Print the posts
    my $post_number = defined $page ? $limit_from : 0;
    for my $post (@posts) {
        my $body        = $post->[14] == 1 ? xml::bbcode($post->[5], 'disabled_tags' => \%xml::bbcode) : xml::bbcode($post->[5]); # Transform post body to xhtml
        $body           = xml::smiles($body) unless $post->[13] == 1;
        my $post_ctime  = datetime::from_unixtime($post->[6]);                                  # Post date
        my $edit_ctime  = datetime::from_unixtime($post->[9]) if defined $post->[9];            # Edit date
        my $signature   = xml::bbcode($authors{ $post->[3] }->[5]) unless $post->[12] == 1;     # Signature unless disabled
        my $mypost      = ' mypost="1"' if $post->[3] == $USER{'id'};                           # My post flag
                        
        print qq~\t\t\t$indent<post id="$post->[0]" number="~. ++$post_number .qq~" title="$post->[1]" author_id="$post->[3]" author_name="$post->[4]" author_title="$authors{ $post->[3] }->[0]" author_posts="$authors{ $post->[3] }->[1]" author_registered="$authors{ $post->[3] }->[2]" author_location="$authors{ $post->[3] }->[3]" author_avatar="$authors{ $post->[3] }->[4]" ctime="$post_ctime" edit_user="$post->[7]" edit_reason="$post->[8]" edit_ctime="$edit_ctime" edit_count="$post->[10]" replyto="$post->[11]" disable_signature="$post->[12]" disable_smiles="$post->[13]" disable_bbcode="$post->[14]"$mypost>\n~;
        print qq~\t\t\t\t$indent<body>$body</body>\n~;
        print qq~\t\t\t\t$indent<signature>$signature</signature>\n~ if defined $signature;
        print qq~\t\t\t$indent</post>\n~;
    }

    # Close the thread, forum and parent nodes
    print "\t\t$indent</thread>\n\t$indent</forum>\n". $closing_nodes;
    
    # Increment thread views and ignore users browsing the thread unless the forum is read-only
    if ($config{'read_only'} == 0) {
        my $time = datetime::gmtime() - 300; # 10 minutes
        $query = $DB->query(
            "SELECT user_name 
            FROM ${module_db_prefix}activity 
            WHERE type = 'thread' AND id = $thread_id AND date > $time AND user_id = $USER{id} 
            ORDER BY date DESC 
            LIMIT 1"
        );
        $DB->query("UPDATE ${module_db_prefix}threads SET views = views + 1 WHERE id = ? LIMIT 1", $thread_id) unless $query->rows();
    }

    # Users activity
    _user_activity('thread', --$depth, $thread_id, $thread_title);
    
    # Close the forums node
    print "\t</forums>\n";
}

=xml
    <function name="view_post">
        <synopsis>
            Displays a post from a thread.
        </synopsis>
    </function>
=cut

sub view_post {
    my $post_id = $_[0];
    
    user::require_permission('forums_view');
    user::print_module_permissions('forums');
    
    # Goto actions
    goto &edit_post if $INPUT{'a'} eq "edit";
    goto &delete_post if $INPUT{'a'} eq "delete";
    
    # Get the post by id if it exists or error
    my $query = $DB->query("SELECT thread_id FROM ${module_db_prefix}posts WHERE id = ? LIMIT 1", $post_id);
    throw 'request_404' if $query->rows() == 0;
    my $thread_id = $query->fetchrow_arrayref()->[0];
    
    # Get the post's page in the thread
    $query = $DB->query("SELECT COUNT(1) FROM ${module_db_prefix}posts WHERE thread_id = ? and id <= ?", $thread_id, $post_id);
    my $page = math::ceil($query->fetchrow_arrayref()->[0] / $config{'posts_per_page'}) unless $query->rows() == 0;
    
    # Set the page number
    $INPUT{'p'} = "$page" if defined $page;
    
    # Prepend the thread id
    unshift @_, $thread_id;
     
    # View the thread
    goto &view_thread;
}

=xml
        <function name="create_thread">
            <synopsis>
                Create a new thread
            </synopsis>
            <todo>
                Formating editor, smiles and character count js
            </todo>
            <todo>
                Increment user post count pending profiles
            </todo>
            <todo>
                Consider using the multitable format for the SQL UPDATE query
            </todo>
        </function>
=cut

sub create_thread {
    my $forum_id = shift;
    
    user::require_permission('forums_create_threads');
    user::require_permission('forums_create_posts');
    style::include_template('create_thread');
    
    # Check to make sure the forums are not read-only
    throw 'validation_error', 'The forums are currently locked and read-only for maintenance. Please try again later.' if $config{'read_only'} == 1;
    
    # Print the forum node
    print qq~\t<forums action="create_thread" forum_id="$forum_id" subject_length="$config{'max_subject_length'}" post_length="$config{'max_post_length'}">\n~;

    # Get the forum details by id
    my ($forum_title, $forum_description, $forum_parent) = ($forums{ $forum_id }->{'name'}, $forums{ $forum_id }->{'description'}, $forums{ $forum_id }->{'parent_id'});

    # Print the parent forum nodes and set the indent level
    my ($depth, $closing_nodes) = _print_parents($forum_id);
    my $indent = "\t" x $depth;
    print qq~\t$indent<forum id="$forum_id" name="$forum_title" parent_id="$forum_parent" description="$forum_description">\n~;
    
    # If the form has been submitted
    if ($ENV{'REQUEST_METHOD'} eq 'POST') {
        my $gmtime      = datetime::gmtime();
        my $ctime       = datetime::from_unixtime($gmtime);
        my $notify      = defined $INPUT{'enable_notification'} ? 1 : 0;
        my $sticky      = defined $INPUT{'sticky'} ? 1 : 0;
        my $locked      = defined $INPUT{'locked'} ? 1 : 0;
        my $signature   = defined $INPUT{'disable_signature'} ? 1 : 0;
        my $smiles      = defined $INPUT{'disable_smiles'} ? 1 : 0;
        my $bbcode      = defined $INPUT{'disable_bbcode'} ? 1: 0;
        my $subject     = xml::entities($INPUT{'subject'}, 'proper_english');
        my $body        = xml::entities($INPUT{'body'}, 'proper_english');
        my $body_xhtml;
        
        # Validate post
        my $success = try {
            my @errors;
            
            # Check permissions
            user::require_permission('forums_lock') if $locked == 1;
            user::require_permission('forums_sticky') if $sticky == 1;
            
            # Subject min-length
            push @errors, 'Subject is too short. Minimum of '. $config{'min_subject_length'} .' characters required.' if length $INPUT{'subject'} < $config{'min_subject_length'};
                        
            # Subject max-length
            push @errors, 'Subject is too long. Maximum of '. $config{'max_subject_length'} .' characters allowed.' if length $INPUT{'subject'} > $config{'max_subject_length'};
            
            # Post body min-length
            push @errors, 'Post body is too short. Minimum of '. $config{'min_post_length'} .' characters required.' if length $INPUT{'body'} < $config{'min_post_length'};
                        
            # Post body max-length
            push @errors, 'Post body is too long. Maximum of '. $config{'max_post_length'} .' characters allowed.' if length $INPUT{'body'} > $config{'max_post_length'};
                      
            # Post body bbcode
            try { $body_xhtml = $bbcode == 1 ? xml::bbcode($body, 'disabled_tags' => \%xml::bbcode) : xml::bbcode($body) } catch 'validation_error', with { push @errors, 'Message contains incorrect bbCode. '. shift; abort(1); }; 
            
            # Throw errors if any
            throw 'validation_error' => @errors if @errors > 0;
        };
        
        # If validation fails or previewing
        if (!$success or $INPUT{'preview'}) {
            my $signature_xhtml = xml::bbcode($USER{'signature'}) if $signature == 0;
                    
            print qq~\t\t$indent<post title="$subject" author_id="$USER{'id'}" author_name="$USER{'name'}" author_title="$PERMISSIONS{'name'}" author_posts="$USER{'posts'}" author_registered="$USER{'registered'}" author_avatar="$USER{'avatar'}" ctime="$ctime" notify="$notify" sticky="$sticky" locked="$locked" signature="$signature" smiles="$smiles" bbcode="$bbcode">\n~;
            print qq~\t\t\t$indent<body>\n~;
            print qq~\t\t\t\t$indent<raw>$body</raw>\n~;
            print qq~\t\t\t\t$indent<xhtml>$body_xhtml</xhtml>\n~ if $success;
            print qq~\t\t\t$indent</body>\n~;
            print qq~\t\t\t$indent<signature>$signature_xhtml</signature>\n~ if defined $signature_xhtml;
            print qq~\t\t$indent</post>\n~;
        }
        
        # If validation succeeded and saving
        elsif ($success and $INPUT{'save'}) {
            
            # Insert into the thread table
            $DB->query(
                "INSERT INTO ${module_db_prefix}threads (title, forum_id, author_id, author_name, date, lastpost_date, lastpost_author, views, replies, sticky, locked) 
                VALUES (?, ?, ?, ?, ?, ?, ? , '0', '0', ?, ?)", 
                $subject, $forum_id, $USER{'id'}, $USER{'name'}, $gmtime, $gmtime, $USER{'name'}, $sticky, $locked
            );
            $thread_id = $DB->insert_id();
            
            # Insert into the post table
            $DB->query(
                "INSERT INTO ${module_db_prefix}posts (title, thread_id, author_id, author_name, body, date, disable_signature, disable_smiles, disable_bbcode) 
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)", 
                $subject, $thread_id, $USER{'id'}, $USER{'name'}, $body, $gmtime, $signature, $smiles, $bbcode
            );
            $post_id = $DB->insert_id();
            
            # Update the lastpost id and opening post id for the thread
            $DB->query("UPDATE ${module_db_prefix}threads SET lastpost_id = ?, post_id = ? WHERE id = ? LIMIT 1", $post_id, $post_id, $thread_id);
                
            # Increment forum post and thread totals
            $increment_totals->execute($forum_id);

            # Increment user's post count
            # Todo pending profiles!
                                
            # Update cache and sync daemons
            ipc::do('forums', '_cache_forums');
            
            # Add user to notify table for this thread
            $insert_notify->execute($USER{'id'}, $thread_id) if $notify == 1;

            # Confirmation
            confirmation('Your thread has been created. You will be redirected to your new thread.');
            print qq~\t\t$indent<post title="$subject" id="$thread_id" />\n~; 
        }           
    }
    
    # Close the forum, parent nodes and forums node
    print "\t$indent</forum>\n" . $closing_nodes . "\t</forums>\n";
}

=xml
        <function name="edit_thread">
            <synopsis>
                Edits and/or moves a thread
            </synopsis>
            <todo>
              Consider using the multitable format for the SQL UPDATE query
            </todo>
        </function>
=cut

sub edit_thread {
    my $thread_id = shift;
    
    user::require_permission('forums_edit_threads');
    style::include_template('edit_thread');
    
    # Check to make sure the forums are not read-only
    throw 'validation_error', 'The forums are currently locked and read-only for maintenance. Please try again later.' if $config{'read_only'} == 1;
    
    # Get the thread by id if it exists or error
    my $query = $DB->query(
        "SELECT title, forum_id, post_id, author_id, author_name, replies, sticky, locked 
        FROM ${module_db_prefix}threads 
        WHERE id = ? 
        LIMIT 1", 
        $thread_id
    );
    throw 'request_404' if $query->rows() == 0;
    my ($thread_title, $forum_id, $post_id, $author_id, $author_name, $replies, $sticky, $locked) = @{$query->fetchrow_arrayref()};
    
    # Print the forum node
    print qq~\t<forums action="edit_thread" thread_id="$thread_id" forum_id="$forum_id" subject_length="$config{'max_subject_length'}" post_length="$config{'max_post_length'}">\n~;

    # Get the forum details by id
    my ($forum_title, $forum_description, $forum_parent) = ($forums{ $forum_id }->{'name'}, $forums{ $forum_id }->{'description'}, $forums{ $forum_id }->{'parent_id'});

    # Print the parent forum nodes and set the indent level
    my ($depth, $closing_nodes) = _print_parents($forum_id);
    my $indent = "\t" x $depth;
    print qq~\t$indent<forum id="$forum_id" name="$forum_title" parent_id="$forum_parent" description="$forum_description">\n~;
    
    # If the form has been submitted
    if ($ENV{'REQUEST_METHOD'} eq 'POST') {
        my $sticky      = defined $INPUT{'sticky'} ? 1 : 0;
        my $locked      = defined $INPUT{'locked'} ? 1 : 0;
        my $move_to     = $INPUT{'move_to'} if defined $INPUT{'move_to'} and $INPUT{'move_to'} != $forum_id;
        my $move_note   = defined $move_to and defined $INPUT{'move_note'} ? 1 : 0;
        $thread_title   = xml::entities($INPUT{'subject'}, 'proper_english');
        
        # Validate post
        my $success = try {
            my @errors;
            
            # Check permissions
            user::require_permission('forums_lock') if $locked == 1;
            user::require_permission('forums_sticky') if $sticky == 1;
            
            # Move to forum id
            if (defined $move_to) {
                user::require_permission('forums_move');
                
                # Check move to forum id
                push @errors, 'Parent forum does not exist.' if !exists $forums{ $move_to };
            }
            
            # Subject min-length
            push @errors, 'Subject is too short. Minimum of '. $config{'min_subject_length'} .' characters required.' if length $INPUT{'subject'} < $config{'min_subject_length'};
                        
            # Subject max-length
            push @errors, 'Subject is too long. Maximum of '. $config{'max_subject_length'} .' characters allowed.' if length $INPUT{'subject'} > $config{'max_subject_length'};
            
            # Throw errors if any
            throw 'validation_error' => @errors if @errors > 0;
        };
        
        # If validation succeeded
        if ($success) {
            
            # Update the thread
            $DB->query(
                "UPDATE ${module_db_prefix}threads SET title = ?, forum_id = ?, sticky = ?, locked = ? 
                WHERE id = ? 
                LIMIT 1", 
                $thread_title, defined $move_to ? $move_to : $forum_id, $sticky, $locked, $thread_id
            );
            
            # If moving the thread
            if (defined $move_to) {

                # Mark the thread as moved if a moving note was specified
                $DB->query("UPDATE ${module_db_prefix}threads SET moved_from = ? WHERE id = ? LIMIT 1", $forum_id, $thread_id) if $move_note == 1;

                # Adjust forum post/thread totals if moving the thread
                my $posts = $replies + 1;

                # Increment
                $DB->query("UPDATE ${DB_PREFIX}forums SET threads = threads + 1, posts = posts + $posts WHERE id = ? LIMIT 1", $move_to);
                
                # De-increment
                $DB->query("UPDATE ${DB_PREFIX}forums SET threads = threads - 1, posts = posts - $posts WHERE id = ? LIMIT 1", $forum_id);
            }
            
            # Update the opening post if it exists
            $query = $DB->query("SELECT COUNT(1) FROM ${module_db_prefix}posts WHERE id = ? LIMIT 1", $post_id);
            $DB->query("UPDATE ${module_db_prefix}posts SET title = ? WHERE id = ? LIMIT 1", $thread_title, $post_id) if $query->fetchrow_arrayref()->[0] != 0;
                     
            # Update cache and sync daemons
            ipc::do 'forums', '_cache_forums';

            # Confirmation
            confirmation('The thread has been edited. You will be redirected to the existing thread.');
        }           
    }
    
    # Print the thread details
    print qq~\t\t$indent<thread title="$thread_title" id="$thread_id" sticky="$sticky" locked="$locked">\n~;
    print qq~\t\t\t$indent<parents>\n~;
    _print_forums();
    print qq~\t\t\t$indent</parents>\n~;
    print qq~\t\t$indent</thread>\n~;
    
    # Close the forum, parent nodes and forums node
    print "\t$indent</forum>\n" . $closing_nodes . "\t</forums>\n";
}

=xml
        <function name="delete_thread">
            <synopsis>
                Deletes a thread
            </synopsis>
        </function>
=cut

sub delete_thread {
    my $thread_id = shift;
    
    user::require_permission('forums_delete_threads', 2);
    style::include_template('delete_thread');
    
    # Check to make sure the forums are not read-only
    throw 'validation_error', 'The forums are currently locked and read-only for maintenance. Please try again later.' if $config{'read_only'} == 1;
    
    # Get the thread by id if it exists or error
    my $query = $DB->query(
        "SELECT title, forum_id, post_id, author_id, author_name, replies, sticky, locked 
        FROM ${module_db_prefix}threads 
        WHERE id = ? 
        LIMIT 1", 
        $thread_id
    );
    throw 'request_404' if $query->rows() == 0;
    my ($thread_title, $forum_id, $post_id, $author_id, $author_name, $replies, $sticky, $locked) = @{$query->fetchrow_arrayref()};
    
    # Print the forum node
    print qq~\t<forums action="delete_thread" thread_id="$thread_id" forum_id="$forum_id">\n~;

    # Get the forum details by id
    my ($forum_title, $forum_description, $forum_parent) = ($forums{ $forum_id }->{'name'}, $forums{ $forum_id }->{'description'}, $forums{ $forum_id }->{'parent_id'});

    # Print the parent forum nodes and set the indent level
    my ($depth, $closing_nodes) = _print_parents($forum_id);
    my $indent = "\t" x $depth;
    print qq~\t$indent<forum id="$forum_id" name="$forum_title" parent_id="$forum_parent" description="$forum_description">\n~;
    
    # If the form has been submitted
    if ($ENV{'REQUEST_METHOD'} eq 'POST') {
            my $posts = $replies + 1;

            # Delete the thread
            $DB->query("DELETE FROM ${module_db_prefix}threads WHERE id = ? LIMIT 1", $thread_id);
            
            # Delete the posts
            $DB->query("DELETE FROM ${module_db_prefix}posts WHERE thread_id = ? LIMIT $posts", $thread_id);
         
            # Update forum post/thread totals
            $DB->query("UPDATE ${DB_PREFIX}forums SET threads = threads - 1, posts = posts - $posts WHERE id = ? LIMIT 1", $forum_id);
                        
            # Update cache and sync daemons
            ipc::do 'forums', '_cache_forums';

            # Confirmation
            confirmation('The thread and it\'s posts have been deleted. You will be redirected to the parent forum.');         
    }
    
    # Print the thread details
    print qq~\t\t$indent<thread title="$thread_title" id="$thread_id" />\n~ unless $ENV{'REQUEST_METHOD'} eq 'POST';
    
    # Close the forum, parent nodes and forums node
    print "\t$indent</forum>\n" . $closing_nodes . "\t</forums>\n";
}

=xml
        <function name="create_post">
            <synopsis>
                Creates a new post AKA reply
            </synopsis>
            <todo>
                Review recent posts
            </todo>
            <todo>
                Formating editor, smiles and character count js
            </todo>
            <todo>
                Increment user post count pending profiles
            </todo>
            <todo>
              Consider using the multitable format for the SQL UPDATE query
            </todo>
        </function>
=cut

sub create_post {
    my $thread_id = shift;
    my $post_id;
    
    user::require_permission('forums_create_posts');
    style::include_template('create_post');
    
    # Check to make sure the forums are not read-only
    throw 'validation_error', 'The forums are currently locked and read-only for maintenance. Please try again later.' if $config{'read_only'} == 1;
    
    # Get the thread by id if it exists or error
    my $query = $DB->query(
        "SELECT title, forum_id, post_id, author_id, author_name, replies, sticky, locked 
        FROM ${module_db_prefix}threads 
        WHERE id = ? 
        LIMIT 1", 
        $thread_id
    );
    throw 'request_404' if $query->rows() == 0;
    my ($thread_title, $forum_id, $post_id, $author_id, $author_name, $replies, $sticky, $locked) = @{$query->fetchrow_arrayref()};
    
    # Error if the thread is locked
    throw 'validation_error', 'The topic is locked and replies are disabled.' if $locked == 1;
    
    # Print the forum node
    print qq~\t<forums action="create_post" thread_id="$thread_id" forum_id="$forum_id" subject_length="$config{'max_subject_length'}" post_length="$config{'max_post_length'}">\n~;

    # Get the forum details by id
    my ($forum_title, $forum_description, $forum_parent) = ($forums{ $forum_id }->{'name'}, $forums{ $forum_id }->{'description'}, $forums{ $forum_id }->{'parent_id'});

    # Print the parent forum nodes and set the indent level
    my ($depth, $closing_nodes) = _print_parents($forum_id);
    my $indent = "\t" x $depth;
    print qq~\t$indent<forum id="$forum_id" name="$forum_title" parent_id="$forum_parent" description="$forum_description">\n~;

    # Print the thread node 
    print qq~\t\t$indent<thread id="$thread_id" title="$thread_title" author_id="$author_id" author_name="$author_name" replies="$replies">\n~;

    # Check if the user has notify set for this thread
    $exists_notify->execute($USER{'id'}, $thread_id);
    my $notify = $exists_notify->rows() ? 1 : 0;

    # If quoting another post and the form has not been submitted
    my $body;
    if (defined $INPUT{'q'} and $ENV{'REQUEST_METHOD'} ne 'POST') {
        
        # Error if the post id is not numeric
        throw 'request_404' unless string::is_numeric($INPUT{'q'});
        
        # Get the post by id if it exists or error
        $query = $DB->query("SELECT thread_id, author_name, body FROM ${module_db_prefix}posts WHERE id = ? LIMIT 1", $INPUT{'q'});
        throw 'request_404' if $query->rows() == 0;
        my ($quote_id, $quote_author, $quote_body) = @{$query->fetchrow_arrayref()};
        
        # Error if the quote's thread is not this thread
        throw 'request_404' if $quote_id != $thread_id;
        
        # Add the quote to the post body
        $body = '[quote='. $quote_author .']'. $quote_body .'[/quote]'."\n";
        
        # Print the post
        print qq~\t\t\t$indent<post notify="$notify">\n~;
        print qq~\t\t\t\t$indent<body>\n~;
        print qq~\t\t\t\t\t$indent<raw>$body</raw>\n~;
        print qq~\t\t\t\t$indent</body>\n~;
        print qq~\t\t\t$indent</post>\n~;
    }
    
    # If the form has not been submited and not quoting a post
    elsif (!defined $INPUT{'q'} and $ENV{'REQUEST_METHOD'} ne 'POST') {
        print qq~\t\t\t$indent<post notify="$notify" />\n~;
    }

    # If the form has been submitted
    if ($ENV{'REQUEST_METHOD'} eq 'POST') {
        my $gmtime      = datetime::gmtime();
        my $ctime       = datetime::from_unixtime($gmtime);
        $notify         = defined $INPUT{'enable_notification'} ? 1 : 0;
        my $signature   = defined $INPUT{'disable_signature'} ? 1 : 0;
        my $smiles      = defined $INPUT{'disable_smiles'} ? 1 : 0;
        my $bbcode      = defined $INPUT{'disable_bbcode'} ? 1: 0;
        my $subject     = xml::entities($INPUT{'subject'}, 'proper_english');
        $body          .= xml::entities($INPUT{'body'}, 'proper_english');
        my $body_xhtml;
        
        # Validate post
        my $success = try {
            my @errors;
            
            # Subject min-length
            push @errors, 'Subject is too short. Minimum of '. $config{'min_subject_length'} .' characters required.' if length $INPUT{'subject'} < $config{'min_subject_length'} and length $INPUT{'subject'} > 0;
                        
            # Subject max-length
            push @errors, 'Subject is too long. Maximum of '. $config{'max_subject_length'} .' characters allowed.' if length $INPUT{'subject'} > $config{'max_subject_length'} and length $INPUT{'subject'} > 0;
            
            # Post body min-length
            push @errors, 'Post body is too short. Minimum of '. $config{'min_post_length'} .' characters required.' if length $INPUT{'body'} < $config{'min_post_length'};
                        
            # Post body max-length
            push @errors, 'Post body is too long. Maximum of '. $config{'max_post_length'} .' characters allowed.' if length $INPUT{'body'} > $config{'max_post_length'};
                      
            # Post body bbcode
            try { $body_xhtml = $bbcode == 1 ? xml::bbcode($body, 'disabled_tags' => \%xml::bbcode) : xml::bbcode($body) } catch 'validation_error', with { push @errors, 'Message contains incorrect bbCode. '. shift; abort(1); }; 
            
            # Throw errors if any
            throw 'validation_error' => @errors if @errors > 0;
        };
        
        # If validation fails or previewing
        if (!$success or $INPUT{'preview'}) {
            my $signature_xhtml = xml::bbcode($USER{'signature'}) if $signature == 0;
            $body_xhtml = $body if $bbcode == 1;
                    
            print qq~\t\t\t$indent<post title="$subject" author_id="$USER{'id'}" author_name="$USER{'name'}" author_title="$PERMISSIONS{'name'}" author_posts="$USER{'posts'}" author_registered="$USER{'registered'}" author_avatar="$USER{'avatar'}" ctime="$ctime" notify="$notify" sticky="$sticky" locked="$locked" signature="$signature" smiles="$smiles" bbcode="$bbcode">\n~;
            print qq~\t\t\t\t$indent<body>\n~;
            print qq~\t\t\t\t\t$indent<raw>$body</raw>\n~;
            print qq~\t\t\t\t\t$indent<xhtml>$body_xhtml</xhtml>\n~ if $success;
            print qq~\t\t\t\t$indent</body>\n~;
            print qq~\t\t\t\t$indent<signature>$signature_xhtml</signature>\n~ if defined $signature_xhtml;
            print qq~\t\t\t$indent</post>\n~;
        }
        
        # If validation succeeded and saving
        elsif ($success and $INPUT{'save'}) {
            
            # Insert into the post table
            $DB->query(
                "INSERT INTO ${module_db_prefix}posts (title, thread_id, author_id, author_name, body, date, disable_signature, disable_smiles, disable_bbcode) 
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)", 
                $subject, $thread_id, $USER{'id'}, $USER{'name'}, $body, $gmtime, $signature, $smiles, $bbcode
            );
            $post_id = $DB->insert_id();
            
            # Update the lastpost data and replies
            $DB->query(
                "UPDATE ${module_db_prefix}threads 
                SET lastpost_id = ?, lastpost_author = ?, lastpost_date = ?, replies = replies + 1 
                WHERE id = ? LIMIT 1", 
                $post_id, $USER{'name'}, $gmtime, $thread_id
            );
                
            # Increment forum post and thread totals
            $increment_totals->execute($forum_id);

            # Increment user's post count
            # Todo pending profiles!
            
            # Update cache and sync daemons
            ipc::do('forums', '_cache_forums');

            # Add user to notify table for this thread unless they are already in the db
            if ($notify == 1) {
                $exists_notify->execute($USER{'id'}, $thread_id);
                $insert_notify->execute($USER{'id'}, $thread_id) unless $exists_notify->rows();
            }
            
            # Remove the user from the notify table
            else {
                $delete_notify->execute($USER{'id'}, $thread_id);
            }
         
            # Notify users of replies
            $new_reply_notify = $thread_id;

            # Confirmation
            confirmation('Your reply has been posted. You will be redirected to your new post.');
            print qq~\t\t$indent<post title="$subject" id="$post_id" />\n~; 
        }
    }
    
    # Close the thread, forum, parent nodes and forums node
    print "\t\t$indent</thread>\n\t$indent</forum>\n" . $closing_nodes . "\t</forums>\n";
}

=xml
        <function name="edit_post">
            <synopsis>
                Edits a post
            </synopsis>
            <todo>
              Consider using the multitable format for the SQL UPDATE query
            </todo>
        </function>
=cut

sub edit_post {
    my $post_id = shift;

    user::require_permission('forums_view');
    user::print_module_permissions('forums');
    style::include_template('edit_post');
    
    # Check to make sure the forums are not read-only
    throw 'validation_error', 'The forums are currently locked and read-only for maintenance. Please try again later.' if $config{'read_only'} == 1;
    
    # Get the post by id if it exists or error
    my $query = $DB->query(
        "SELECT title, thread_id, author_id, author_name, body, date, disable_signature, disable_smiles, disable_bbcode 
        FROM ${module_db_prefix}posts 
        WHERE id = ? 
        LIMIT 1", 
        $post_id
    );
    throw 'request_404' if $query->rows() == 0;
    my ($post_title, $thread_id, $post_author_id, $post_author_name, $body, $post_date, $signature, $smiles, $bbcode) = @{$query->fetchrow_arrayref()};

    # Check permissions
    if ($USER{'id'} == $post_author_id and $PERMISSIONS{'forums_edit_posts'} != 2) {
        user::require_permission('forums_edit_posts', 1);
    }
    else {
        user::require_permission('forums_edit_posts', 2);
    }

    # Get the thread by id if it exists or error
    $query = $DB->query(
        "SELECT title, forum_id, post_id, author_id, author_name, replies, sticky, locked 
        FROM ${module_db_prefix}threads 
        WHERE id = ? 
        LIMIT 1", 
        $thread_id
    );
    throw 'request_404' if $query->rows() == 0;
    my ($thread_title, $forum_id, $op_id, $thread_author_id, $thread_author_name, $replies, $sticky, $locked) = @{$query->fetchrow_arrayref()};
    
    # Error if the thread is locked
    throw 'validation_error', 'The topic is locked and editing posts is disabled.' if $locked == 1;
    
    # Print the forum node
    print qq~\t<forums action="edit_post" post_id="$post_id" thread_id="$thread_id" forum_id="$forum_id" subject_length="$config{'max_subject_length'}" post_length="$config{'max_post_length'}">\n~;

    # Get the forum details by id
    my ($forum_title, $forum_description, $forum_parent) = ($forums{ $forum_id }->{'name'}, $forums{ $forum_id }->{'description'}, $forums{ $forum_id }->{'parent_id'});

    # Print the parent forum nodes and set the indent level
    my ($depth, $closing_nodes) = _print_parents($forum_id);
    my $indent = "\t" x $depth;
    print qq~\t$indent<forum id="$forum_id" name="$forum_title" parent_id="$forum_parent" description="$forum_description">\n~;

    # Print the thread node 
    print qq~\t\t$indent<thread id="$thread_id" title="$thread_title" op_id="$op_id" author_id="$thread_author_id" author_name="$thread_author_name" replies="$replies">\n~;

    # Retrieve the user groups and get the group name by author id
    $query = $DB->query("SELECT * FROM ${DB_PREFIX}user_permissions WHERE user_id = ? LIMIT 1", $post_author_id);
    my $post_author_title = $user::groups{ $query->fetchrow_arrayref()->[1] }->{'name'};
    
    # Retrieve the user data
    # Pending profiles! posts, registered, location, avatar, signature
    $query = $DB->query("SELECT id FROM users WHERE id = ? LIMIT 1", $post_author_id);
    my @author = @{$query->fetchrow_arrayref()};
    
    # Check if the thread has notifications set for this user
    $exists_notify->execute($USER{'id'}, $thread_id);
    my $notify = $exists_notify->rows() ? 1 : 0;

    # If the form has been submitted
    my ($body_xhtml, $edit_reason, $gmtime, $ctime, $disable_edit, $edit_date);
    my $subject = $post_title;
    if ($ENV{'REQUEST_METHOD'} eq 'POST') {
        $gmtime       = datetime::gmtime();
        $ctime        = datetime::from_unixtime($gmtime);
        $notify    = defined $INPUT{'enable_notification'} ? 1 : 0;
        $signature    = defined $INPUT{'disable_signature'} ? 1 : 0;
        $smiles       = defined $INPUT{'disable_smiles'} ? 1 : 0;
        $bbcode       = defined $INPUT{'disable_bbcode'} ? 1: 0;
        $subject      = xml::entities($INPUT{'subject'}, 'proper_english');
        $body         = xml::entities($INPUT{'body'}, 'proper_english');
        #$disable_edit = defined $INPUT{'disable_edit'} ? 1: 0;
        $edit_reason  = xml::entities($INPUT{'reason'}, 'proper_english');
        #$edit_date    = datetime::from_unixtime($gmtime) unless $disable_edit == 1;
        
        # Validate post
        my $success = try {
            my @errors;
            
            # Subject min-length
            push @errors, 'Subject is too short. Minimum of '. $config{'min_subject_length'} .' characters required.' if length $INPUT{'subject'} < $config{'min_subject_length'} and $INPUT{'subject'} ne '';
                        
            # Subject max-length
            push @errors, 'Subject is too long. Maximum of '. $config{'max_subject_length'} .' characters allowed.' if length $INPUT{'subject'} > $config{'max_subject_length'} and $INPUT{'subject'} ne '';
            
            # Post body min-length
            push @errors, 'Post body is too short. Minimum of '. $config{'min_post_length'} .' characters required.' if length $INPUT{'body'} < $config{'min_post_length'};
                        
            # Post body max-length
            push @errors, 'Post body is too long. Maximum of '. $config{'max_post_length'} .' characters allowed.' if length $INPUT{'body'} > $config{'max_post_length'};
                      
            # Post body bbcode
            try { $body_xhtml = $bbcode == 1 ? xml::bbcode($body, 'disabled_tags' => \%xml::bbcode) : xml::bbcode($body) } catch 'validation_error', with { push @errors, 'Message contains incorrect bbCode. '. shift; abort(1); }; 
            
            # Edit reason
            push @errors, 'Edit reason is too long. Maximum of '. $config{'max_subject_length'} .' characters allowed.' if length $INPUT{'reason'} > $config{'max_subject_length'};
            
            # Throw errors if any
            throw 'validation_error' => @errors if @errors > 0;
        };
        
        # If validation succeeded and saving
        if ($success and $INPUT{'save'}) {
            
            # Ipdate the post table
            $DB->query(
                "UPDATE ${module_db_prefix}posts 
                SET title = ?, body = ?, disable_signature = ?, disable_smiles = ?, disable_bbcode = ?, edit_user = ?, edit_reason = ?, edit_date = ?, edit_count = edit_count + 1 
                WHERE id = ? 
                LIMIT 1", 
                $subject, $body, $signature, $smiles, $bbcode, $USER{'name'}, $edit_reason, $gmtime, $post_id
            );
            
            # If the post is the thread's opening post, update the title if it changed
            $DB->query("UPDATE ${module_db_prefix}threads SET title = ? WHERE id = ? LIMIT 1", $subject, $thread_id) if $op_id == $post_id and $subject ne $thread_title;
                                
            # Update cache and sync daemons
            ipc::do('forums', '_cache_forums');
            
            # Add user to notify table for this thread unless they are already in the db
            if ($notify == 1) {
                $exists_notify->execute($USER{'id'}, $thread_id);
                $insert_notify->execute($USER{'id'}, $thread_id) unless $exists_notify->rows();
            }
            
            # Remove the user from the notify table
            else {
                $delete_notify->execute($USER{'id'}, $thread_id);
            }

            # Confirmation
            confirmation('Your post has been saved. You will be redirected to your post.');
        }           
    }
    
    # Print the post
    $body_xhtml  = $body if $bbcode == 1;
    my $post_ctime = datetime::from_unixtime($post_date);
    my $signature_xhtml = xml::bbcode($author[4]) if $signature == 0;
    
    print qq~\t\t\t$indent<post id="$post_id" title="$subject" author_id="$post_author_id" author_name="$post_author_name" author_title="$post_author_title" author_posts="$author[0]" author_registered="$author[1]" author_location="$author[2]" author_avatar="$author[3]" ctime="$post_ctime" signature="$signature" smiles="$smiles" bbcode="$bbcode" notify="$notify" edit_user="$USER{'name'}" edit_reason="$edit_reason" edit_ctime="$ctime" disable_edit="$disable_edit">\n~;
    print qq~\t\t\t\t$indent<body>\n~;
    print qq~\t\t\t\t\t$indent<raw>$body</raw>\n~;
    print qq~\t\t\t\t\t$indent<xhtml>$body_xhtml</xhtml>\n~ if $body_xhtml and $ENV{'REQUEST_METHOD'} eq 'POST';
    print qq~\t\t\t\t$indent</body>\n~;
    print qq~\t\t\t\t$indent<signature>$signature_xhtml</signature>\n~ if defined $signature_xhtml;
    print qq~\t\t\t$indent</post>\n~;
    
    # Close the thread, forum, parent nodes and forums node
    print "\t\t$indent</thread>\n\t$indent</forum>\n" . $closing_nodes . "\t</forums>\n";
}

=xml
        <function name="delete_post">
            <synopsis>
                Deletes a post
            </synopsis>
            <todo>
              Consider using the multitable format for the SQL UPDATE query
            </todo>
        </function>
=cut

sub delete_post {
    my $post_id = shift;

    user::require_permission('forums_view');
    user::print_module_permissions('forums');
    style::include_template('delete_post');
    
    # Check to make sure the forums are not read-only
    throw 'validation_error', 'The forums are currently locked and read-only for maintenance. Please try again later.' if $config{'read_only'} == 1;
    
    # Get the post by id if it exists or error
    my $query = $DB->query(
        "SELECT title, thread_id, author_id, author_name, body, date, disable_signature, disable_smiles, disable_bbcode 
        FROM ${module_db_prefix}posts 
        WHERE id = ? 
        LIMIT 1", 
        $post_id
    );
    throw 'request_404' if $query->rows() == 0;
    my ($post_title, $thread_id, $post_author_id, $post_author_name, $body, $post_date, $signature, $smiles, $bbcode) = @{$query->fetchrow_arrayref()};

    # Check permissions
    if ($USER{'id'} == $post_author_id and $PERMISSIONS{'forums_delete_posts'} != 2) {
        user::require_permission('forums_delete_posts', 1);
    }
    else {
        user::require_permission('forums_delete_posts', 2);
    }

    # Get the thread by id if it exists or error
    $query = $DB->query(
        "SELECT title, forum_id, post_id, author_id, author_name, replies, sticky, locked 
        FROM ${module_db_prefix}threads 
        WHERE id = ? 
        LIMIT 1", 
        $thread_id
    );
    throw 'request_404' if $query->rows() == 0;
    my ($thread_title, $forum_id, $op_id, $thread_author_id, $thread_author_name, $replies, $sticky, $locked) = @{$query->fetchrow_arrayref()};

    # Print the forum node
    print qq~\t<forums action="delete_post" post_id="$post_id" thread_id="$thread_id" forum_id="$forum_id" subject_length="$config{'max_subject_length'}" post_length="$config{'max_post_length'}">\n~;

    # Get the forum details by id
    my ($forum_title, $forum_description, $forum_parent) = ($forums{ $forum_id }->{'name'}, $forums{ $forum_id }->{'description'}, $forums{ $forum_id }->{'parent_id'});

    # Print the parent forum nodes and set the indent level
    my ($depth, $closing_nodes) = _print_parents($forum_id);
    my $indent = "\t" x $depth;
    print qq~\t$indent<forum id="$forum_id" name="$forum_title" parent_id="$forum_parent" description="$forum_description">\n~;

    # Print the thread node 
    print qq~\t\t$indent<thread id="$thread_id" title="$thread_title" op_id="$op_id" author_id="$thread_author_id" author_name="$thread_author_name" replies="$replies">\n~;

    # If the form has been submitted
    if ($ENV{'REQUEST_METHOD'} eq 'POST') {

            # Delete the posts
            $DB->query("DELETE FROM ${module_db_prefix}posts WHERE id = ? LIMIT 1", $post_id);
            
            # Update thread replies
            $DB->query("UPDATE ${module_db_prefix}threads SET replies = replies - 1 WHERE id = ? LIMIT 1", $thread_id);
  
            # Update forum post/thread totals
            $DB->query("UPDATE ${DB_PREFIX}forums SET posts = posts - 1 WHERE id = ? LIMIT 1", $forum_id);

            # Update cache and sync daemons
            ipc::do 'forums', '_cache_forums';

            # Confirmation
            confirmation('The post has been deleted. You will be redirected to the parent thread.');         
    }

    # Print the post details
    print qq~\t\t\t$indent<post title="$post_title" id="$post_id" />\n~ unless $ENV{'REQUEST_METHOD'} eq 'POST';

    # Close the thread, forum, parent nodes and forums node
    print "\t\t$indent</thread>\n\t$indent</forum>\n" . $closing_nodes . "\t</forums>\n";
}

=xml
        <function name="admin">
            <synopsis>
                The administration menu
            </synopsis>
        </function>
=cut

sub admin {
    user::require_permission('forums_admin');
    
    # create admin center menu
    my $menu = 'forums_admin';
    menu::label($menu, 'Forums Administration');
    menu::description($menu, 'Some description...');

    # populate the admin menu
    menu::add_item('menu' => $menu, 'label' => 'Configuration', 'url' => $module_admin_base_url . 'config/') if $PERMISSIONS{'forums_admin_config'};

    # print the admin center menu
    throw 'permission_error' unless menu::print_xml($menu);
}

=xml
        <function name="admin_config">
            <synopsis>
                Manages the forums configuration
            </synopsis>
        </function>
=cut

sub admin_config {
    user::require_permission('forums_admin_config');
    style::include_template('admin_config');
    
    # configuration variables
    my @site_fields = qw(lock_forum show_online_users threads_per_page posts_per_page hot_posts_threshold hot_views_threshold max_post_length min_subject_length max_subject_length read_only);
    
    # the input source for the edit config form, defaults to the existing config
    my $input_source  = \%config;
    
    # the form has been submitted
    try {
        $input_source = \%INPUT;

        # validate user input
        $INPUT{'read_only'}         = $INPUT{'read_only'} ? 1 : 0 ;
        $INPUT{'show_online_users'} = $INPUT{'show_online_users'} ? 1 : 0 ;
        throw 'validation_error' => 'Invalid threads per page.'         unless $INPUT{'threads_per_page'} =~ /^\d+$/;
        throw 'validation_error' => 'Invalid posts per page.'           unless $INPUT{'posts_per_page'} =~ /^\d+$/;
        throw 'validation_error' => 'Invalid hot posts threshold.'      unless $INPUT{'hot_posts_threshold'} =~ /^\d+$/;
        throw 'validation_error' => 'Invalid hot views threshold.'      unless $INPUT{'hot_views_threshold'} =~ /^\d+$/;
        throw 'validation_error' => 'Invalid maximum post length.'      unless $INPUT{'max_post_length'} =~ /^\d+$/;
        throw 'validation_error' => 'Invalid minimum subject length.'   unless $INPUT{'min_subject_length'} =~ /^\d+$/;
        throw 'validation_error' => 'Invalid maximum subject length.'   unless $INPUT{'max_subject_length'} =~ /^\d+$/;
        
        # everything validated, update settings
        my $query = $DB->prepare("UPDATE ${module_db_prefix}config SET value = ? WHERE name = ?");
        map { $query->execute($INPUT{$_}, $_) } @site_fields;

        # print a confirmation message
        confirmation('Forums settings have been saved.');

        # reload configuration for all daemons
        ipc::do('module', 'load_config', 'forums');
    } if $ENV{'REQUEST_METHOD'} eq 'POST';
    
    # print the edit config form
    my $fields = join '', map { " $_=\"" . xml::entities($input_source->{$_}) . '"' } @site_fields;
    print qq~\t<forums action="admin_config"$fields />\n~;
}

=xml
    <function name="_print_forums">
        <synopsis>
            Recursively print forums and their subforums.
        </synopsis>
        <example>
            _print_forums($forum_id, $depth);
        </example>
    </function>
=cut

sub _print_forums {
    my ($parent, $depth) = @_;
    
    # Set default values
    $parent    = 0 unless defined $parent;
    $depth     = 0 unless defined $depth;
    my $indent = "\t" x $depth;
    
    # Retrieve the forums with the same parent
    my @forums = _get_children($parent);
    
    # Order forums by priority
    @forums = sort { $a->{'priority'} <=> $b->{'priority'} } @forums;

    # Start printing out the forum index
    for my $forum (@forums) {
        
        # Calculate how long ago the last post was
        my $lastpost_date = _pretty_dates($forum->{'lastpost_date'});
        
        # Last post date
        my $lastpost_ctime = datetime::from_unixtime($forum->{'lastpost_date'});
        
        # If there are subforums print them
        if ( scalar _get_children($forum->{'id'}) > 0 ) {
            print qq~\t\t$indent<forum id="$forum->{'id'}" name="$forum->{'name'}" parent_id="$forum->{'parent_id'}" description="$forum->{'description'}" threads="$forum->{'threads'}" posts="$forum->{'posts'}" last_date="$lastpost_date" last_ctime="$lastpost_ctime" last_user="$forum->{'lastpost_author'}" last_id="$forum->{'lastpost_id'}" last_title="$forum->{'lastpost_title'}">\n~;
            _print_forums($forum->{'id'}, ++$depth); # recurse the forum
            print "\t\t$indent</forum>\n";
        }
        
        # Otherwise just print the forum
        else {
             print qq~\t\t$indent<forum id="$forum->{'id'}" name="$forum->{'name'}" parent_id="$forum->{'parent_id'}" description="$forum->{'description'}" threads="$forum->{'threads'}" posts="$forum->{'posts'}" last_date="$lastpost_date" last_ctime="$lastpost_ctime" last_user="$forum->{'lastpost_author'}" last_id="$forum->{'lastpost_id'}" last_title="$forum->{'lastpost_title'}" />\n~;
        }
    }
}

=xml
    <function name="_get_children">
        <synopsis>
            Returns the child forum(s) of a parent forum
        </synopsis>
        <note>
            Used internally by _print_forums
        </note>
    </function>
=cut

sub _get_children {
    my $parent_id = shift;
    my @forums;
    
    # Get the child forums by parent id
    for my $forum ( values %forums ) {
        push @forums, $forum if $forum->{'parent_id'} == $parent_id;
    }
    
    return @forums;
}

=xml
    <function name="_print_parents">
        <synopsis>
            Lookup the parent forums, print the opening nodes and return the indent depth + closing nodes
        </synopsis>
        <example>
            my ($depth, $closing_nodes) = _print_parents($forum_id);
        </example>
    </function>
=cut

sub _print_parents {
    my $child = shift;
    my $depth = 1;
    my $closing_nodes;
    
    # Retrieve the parent forums
    $parents = _get_parents($child);
    
    # Print the parent forums in the proper order and set the node depth
    foreach my $parent ( reverse @{$parents} ) { 
        my $indent = "\t" x ++$depth;
        print qq~$indent<forum id="$parent->{'id'}" name="$parent->{'name'}" parent_id="$parent->{'parent_id'}">\n~;
        $closing_nodes .= qq~$indent</forum>\n~;
    }
    
    return $depth, $closing_nodes;
}
        
=xml
    <function name="_get_children">
        <synopsis>
            Returns the parent(s) forums of a child forum
        </synopsis>
        <note>
            Used internally by _print_parents
        </note>
    </function>
=cut

sub _get_parents { 
    my ($child, $parents) = @_;
    $parents = [] unless defined $parents;
  
    # Get the parent of this child forum
    my $parent = $forums{ $forums{$child}->{'parent_id'} };
        
    # Append the the parent forum if any
    push @{$parents}, $parent if defined $parent;
    
    # Recurse if there was a parent forum of the child
    _get_parents($parent->{'id'}, $parents) if defined $parent;
    
    return $parents;
}

=xml
    <function name="_cache_forums">
        <synopsis>
            Caches the forums as an array of hash references
        </synopsis>
        <note>
            %forums = ( forum_id => ( id => value, name => value, parent_id => value, description => value, priority => value ), );
        </note>
    </function>
=cut

sub _cache_forums {
    # Clear the current cache, if any
    %forums = ();
    
    # Retrieve the forums
    my $query = $DB->query("SELECT id, name, parent_id, description, priority, threads, posts FROM ${DB_PREFIX}forums");
    
    # Stick it in
    while ( my $forum = $query->fetchrow_hashref() ) {
        
        # The last post data
        my $query = $DB->query(
            "SELECT lastpost_date, lastpost_author, lastpost_id, title 
            FROM ${module_db_prefix}threads 
            WHERE forum_id = ? 
            ORDER BY lastpost_date DESC LIMIT 1", 
            $forum->{'id'}
        );
        ($forum->{'lastpost_date'}, $forum->{'lastpost_author'}, $forum->{'lastpost_id'}, $forum->{'lastpost_title'}) = @{$query->fetchrow_arrayref()};

        # Everything else
        $forums{ $forum->{'id'} } = $forum;
    }
}

=xml
    <function name="_user_activity">
        <synopsis>
            Logs and prints user activity.
        </synopsis>
    </function>
=cut

sub _user_activity {
    my $date = datetime::gmtime();
    my ($type, $depth, $id, $title) = @_;
    
    $depth  = 0 unless defined $depth;
    my $indent = "\t" x $depth;
    
    # Check to make sure the forums are not read-only
    if ($config{'read_only'} == 0) {
    
        # Log the users activity
        my $sql_set = "date = '". datetime::gmtime() ."', type = '". $type ."'";
        $sql_set .= defined $id ? ", id = '". $id ."'" : ", id = NULL";
        $sql_set .= defined $title ? ", title = '". $title ."'" : ", title = NULL";
        my $username = $USER{'name'};
        $username .= "-". $USER{'session'} if $USER{'id'} == 0;
    
        # Update or insert a new row for the users activity
        my $sql_values;
        $sql_values = defined $id ? "'". $id ."'" : "NULL";
        $sql_values .= defined $title ? ", '". $title ."'" : ", NULL";
        $DB->query(
            "INSERT INTO ${module_db_prefix}activity (date, type, id, title, user_name, user_id) 
            VALUES (?, ?, $sql_values, ?, ?) 
            ON DUPLICATE KEY UPDATE $sql_set", 
            datetime::gmtime, $type, $username, $USER{'id'}
        );
    }
    
    # Check to make sure showing online users is enabled
    if ($config{'show_online_users'} == 1) {
      
        # Get the current active users
        my $current_time = datetime::gmtime() - 300;
        my $current_where = "date > ". $current_time;
        $current_where .= " and type = '". $type ."'" unless $type eq "overview";
        $current_where .= " and id = ". $id if defined $id;
        $query = $DB->query("SELECT user_name FROM ${module_db_prefix}activity WHERE $current_where ORDER BY date DESC");

        # Prepare a list of the current active users and count guests + users
        my $current_guests = 0;
        my @current_users;
        while ( my $user = $query->fetchrow_arrayref() ) {
            ++$current_guests if $user->[0] =~ /^Guest(.*)?/;
            push @current_users, $user->[0] unless $user->[0] =~ /^Guest(.*)?/;
        }
        my $current_usernames = join ', ', @current_users;
        my $current_users = scalar @current_users;

        # Print the current active users 
        print qq~\t\t$indent<activity-current usernames="$current_usernames" users="$current_users" guests="$current_guests" />\n~;

        # For the overview do the same as above for the entire day
        if ($type eq "overview") {

            # Get todays active users
            my $todays_time = datetime::gmtime() - 86400;
            $query = $DB->query("SELECT user_name FROM ${module_db_prefix}activity WHERE date > $todays_time ORDER BY date DESC");

            # Prepare a list of all of todays for the overview
            my $todays_guests = 0;
            my @todays_users;
            while ( my $user = $query->fetchrow_arrayref() ) {
                ++$todays_guests if $user->[0] =~ /^Guest(.*)?/;
                push @todays_users, $user->[0] unless $user->[0] =~ /^Guest(.*)?/;
            }
            my $todays_usernames = join ', ', @todays_users;
            my $todays_users = scalar @todays_users;

            # Print today's active users
            print qq~\t\t$indent<activity-todays usernames="$todays_usernames" users="$todays_users" guests="$todays_guests" />\n~;        
        }  
    }
}

=xml
    <function name="_new_reply_notify">
        <synopsis>
            Notifies users of new posts.
        </synopsis>
        <note>
            This uses event::register_hook() to execute at the right times.
        </note>
        <example>
            $new_reply_notify = $thread_id;
        </example>
    </function>
=cut

event::register_hook('request_cleanup', '_new_reply_notify');
sub _new_reply_notify {
    $thread_id = defined $new_reply_notify ? $new_reply_notify : 0;
    
    if ($thread_id != 0) {
        
        # Retrieve the users to be notified for this thread
        $query = $DB->query(
            "SELECT ${module_db_prefix}notify.user_id, ${module_db_prefix}notify.last_ntime, users.name, users.email, users.date_format, ${module_db_prefix}activity.date 
            FROM ${module_db_prefix}notify, users, ${module_db_prefix}activity 
            WHERE ${module_db_prefix}notify.thread_id = ? and users.id = ${module_db_prefix}notify.user_id and ${module_db_prefix}activity.user = users.name", 
            $thread_id
        );
        
        # Set the notification time to avoid duplicate notifications later
        $DB->query("UPDATE ${module_db_prefix}notify SET last_ntime = ? WHERE thread_id = ?", datetime::gmtime(), $thread_id);
        
        while ( my $notice = $query->fetchrow_arrayref() ) {
            my ($user_id, $last_ntime, $user_name, $email, $date_format, $last_atime) = @{$notice};
        
            # Check if the user has been notified before
            if ( (!defined $last_ntime or (defined $last_ntime and (!defined $last_atime or $last_atime > $last_ntime))) and $user_id != $USER{'id'} ) {
                
                # Send the email notifcation
                email::send_template(
                    'forums_notify',
                    $email,
                    {
                        'site_name'    => $CONFIG{'site_name'},
                        'username'     => $user_name,
                        'date_format'  => $date_format,
                        'post_url'     => "$CONFIG{full_url}forums/post/$post_id/",
                        'thread_title' => $thread_title,
                    }
                );
            }
        }
    }
}

=xml
    <function name="_pretty_dates">
        <synopsis>
            Returns how long ago a post was
        </synopsis>
        <note> 
            This should ideally be done in XSL but the required XSLT 1.0 for calculating date differences is rather heavy.
        </note>
    </function>
=cut

sub _pretty_dates {
    my $date = shift;
    my $date_pretty;

    # Age of the post in seconds
    $date = datetime::gmtime() - $date;

    # Days in this month
    my $days = datetime::days_in_month(1900 + [gmtime()]->[5], ++[gmtime()]->[4]);

    if ($date <= 60) {                                      # lte one minute
        $date_pretty = "today, second";
    }
    elsif ($date <= 3600) {                                 # lte one hour
        $date = math::round($date / 60);
        $date_pretty = "today, ". $date ." minute";
    }
    elsif ($date <= 86400) {                                # lte one day
        $date = math::round($date / 3600);
        $date_pretty = "today, ". $date ." hour";
    }
    #elsif ($date <= 172800) {                               # lte two days
    #    $date = math::round($date / 3600);
    #    $date_pretty = "yesterday, ". $date ." day";
    #}
    elsif ($date <= 604800) {                               # lte one week
        $date = math::ceil($date / 86400);
        $date_pretty = $date ." day";
    }
    elsif ($date <= (86400 * $days)) {                      # lte one month
        $date = math::round($date / 604800);
        $date_pretty = $date ." week";
    }
    elsif ($date <= 31536000) {                             # lte one year
        $date = math::round($date / 2629743.83);
        $date_pretty = $date ." month";
    }
    #elsif ($date <= 63072000) {                             # lte 2 years
    #    $date = 1;
    #    $date_pretty = "1 year";
    #}
    else {
        $date = math::round($date / 31536000);
        $date_pretty = $date ." year";
    }
    
    # Plural?
    $date_pretty .= 's' if $date != 1;
    
    return $date_pretty;
}

=xml
    <function name="_clean_activity">
        <synopsis>
            Cleans up old activity entries from the database
        </synopsis>
    </function>
=cut

sub _clean_activity {
    my $interval = 86400; # 24 hours
    
    $DB->query("DELETE FROM ${module_db_prefix}activity WHERE user_id = '0' and date <= ?", datetime::gmtime() - $interval);
}

=xml
</document>
=cut

1;

# Copyright BitPiston 2009