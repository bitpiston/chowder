=xml
<document title="Forum Module">
    <synopsis>
        Forums. Bulletin board. Thing people post messages on.
    </synopsis>
    <warning>
        Work in progress.
    </warning>
    <todo>
        Replace 404s with specific forum errors.
    </todo>
    <todo>
        Add support for parsing smileys
    </todo>
=cut

package forums;

# import libraries
use oyster 'module';
use exceptions;

# import modules
use user;

our %forums;

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
    
    # load forums
    _cache_forums();
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
    
    # Error if the forum id is not numeric
    throw 'request_404' unless string::is_numeric($forum_id);
    
    # Get the forum by id if it exists or error
    throw 'request_404' if !exists $forums{ $forum_id };
    my ($forum_title, $forum_description, $forum_parent) = ($forums{ $forum_id }->{'name'}, $forums{ $forum_id }->{'description'}, $forums{ $forum_id }->{'parent_id'});
    
    # Goto actions
    goto &create_thread if $INPUT{'a'} eq "create";
    
    # Get the page number if it exists and is numeric
    my $page = $INPUT{'p'} if string::is_numeric($INPUT{'p'});
    
    user::require_permission('forums_view');
    style::include_template('view_forum');
    user::print_module_permissions('forums');
    
    # Check how many pages of threads the forum has
    $pages = math::ceil($forums{ $forum_id }->{'threads'} / $config{'threads_per_page'});
    
    # Print the module node
    my $current_page = defined $page ? ' page="'. $page .'"' : ' page="1"';
    print qq~\t<forums action="view_forum" forum_id="$forum_id"$current_page>\n~;
    
    # Print the parent forum nodes and set the indent level
    my ($depth, $closing_nodes) = _print_parents($forum_id);
    my $indent = "\t" x $depth;
    print qq~\t$indent<forum id="$forum_id" name="$forum_title" parent_id="$forum_parent" description="$forum_description" pages="$pages">\n~;    
    
    # Print sub forums if any
    _print_forums($forum_id, $depth);
    
    # Set the thread starting count
    my $limit_from = defined $page ? ($page * $config{'threads_per_page'}) - $config{'threads_per_page'} : 0;
    
    # Retrieve the threads for this page
    my $threads = $DB->query("SELECT * FROM ${module_db_prefix}threads WHERE forum_id = ? ORDER BY sticky DESC, lastpost_date DESC LIMIT $limit_from , $config{'threads_per_page'}", $forum_id);
    
    # Error if no threads 
    throw 'request_404' if $threads->rows() == 0;
    
    # Print the regular threads
    while ( my $row = $threads->fetchrow_arrayref() ) {
        
        # Calculate how many pages the thread is
        my $pages = math::ceil(($row->[10] + 1) / $config{'posts_per_page'});
        
        # Calculate how long ago the last post was
        my $lastpost_date = _pretty_dates($row->[6]);
        
        # Last post date
        my $lastpost_ctime = datetime::from_unixtime($row->[6]);
        
        # My thread flag
        my $mythread = ' mine="1"' if $row->[3] == $USER{'id'};
        
        print qq~\t\t$indent<thread id="$row->[0]" title="$row->[1]" parent_id="$row->[2]" author_id="$row->[3]" author_name="$row->[4]" ctime="$row->[5]" last_date="$lastpost_date" last_ctime="$lastpost_ctime" last_id="$row->[7]" last_author="$row->[8]" views="$row->[9]" replies="$row->[10]" sticky="$row->[11]" pages="$pages"$mythread />\n~;
    }
    
    # Close the thread, forum, parent nodes and forums node
    print "\t$indent</forum>\n" . $closing_nodes . "\t</forums>\n";
}

=xml
    <function name="view_thread">
        <synopsis>
            Displays a thread.
        </synopsis>
    </function>
=cut

sub view_thread {
    my $thread_id = $_[0];
    
    # Error if the thread id is not numeric
    throw 'request_404' unless string::is_numeric($thread_id);
    
    # Get the thread by id if it exists or error
    my $thread = $DB->query("SELECT title, forum_id, author_id, author_name, lastpost_date, lastpost_id, lastpost_author, date, views, replies FROM ${module_db_prefix}threads WHERE id = ? LIMIT 1", $thread_id);
    throw 'request_404' if $thread->rows() == 0;
    my ($thread_title, $forum_id, $author_id, $author_name, $lastpost_date, $lastpost_id, $lastpost_author, $date, $views, $replies) = @{$thread->fetchrow_arrayref()};
    
    # Goto actions
    goto &reply if $INPUT{'a'} eq "reply";
    goto &edit_thread if $INPUT{'a'} eq "edit";
    goto &delete_thread if $INPUT{'a'} eq "delete";
    
    # Get the page number if it exists and is numeric
    my $page = $INPUT{'p'} if string::is_numeric($INPUT{'p'});

    user::require_permission('forums_view');
    style::include_template('view_thread');
    user::print_module_permissions('forums');
    
    # Check how many pages of posts the thread has
    $pages = math::ceil(($replies + 1) / $config{'posts_per_page'});

    # Print the forum node
    my $current_page = defined $page ? ' page="'. $page .'"' : ' page="1"';
    print qq~\t<forums action="view_thread" thread_id="$thread_id" forum_id="$forum_id"$current_page>\n~;

    # Get the forum details by id
    my ($forum_title, $forum_description, $forum_parent) = ($forums{ $forum_id }->{'name'}, $forums{ $forum_id }->{'description'}, $forums{ $forum_id }->{'parent_id'});

    # Print the parent forum nodes and set the indent level
    my ($depth, $closing_nodes) = _print_parents($forum_id);
    my $indent = "\t" x $depth;
    print qq~\t$indent<forum id="$forum_id" name="$forum_title" parent_id="$forum_parent" description="$forum_description">\n~;
    
    # Print the thread node 
    print qq~\t\t$indent<thread id="$thread_id" title="$thread_title" author_id="$author_id" author_name="$author_name" last_date="$lastpost_date" last_id="$lastpost_id" last_author="$lastpost_author" ctime="$date" views="$views" replies="$replies" pages="$pages">\n~;

    # Retrieve the posts for this thread's page or error if none
    my $limit_from = ($page * $config{'posts_per_page'}) - $config{'posts_per_page'} if defined $page;
    my $limit = defined $limit_from ? $limit_from ." , ". $config{'posts_per_page'} : $config{'posts_per_page'};
    my $posts = $DB->query("SELECT * FROM ${module_db_prefix}posts WHERE thread_id = ? ORDER BY date ASC LIMIT $limit", $thread_id);
    throw 'request_404' if $posts->rows() == 0;

    # Print the posts
    my $post_number = defined $page ? $limit_from : 0;
    while ( my $row = $posts->fetchrow_arrayref() ) {
        my $body       = xml::bbcode($row->[5]);                # Transform post body to xhtml
        my $post_ctime = datetime::from_unixtime($row->[6]);    # Post date
        my $edit_ctime = datetime::from_unixtime($row->[9]);    # Edit date
        
        # My post flag
        my $mypost = ' mine="1"' if $row->[3] == $USER{'id'};
                
        print qq~\t\t\t$indent<post id="$row->[0]" number="~. ++$post_number .qq~" title="$row->[1]" author_id="$row->[3]" author_name="$row->[4]" ctime="$post_ctime" edit_user="$row->[7]" edit_reason="$row->[8]" edit_ctime="$edit_ctime" edit_count="$row->[10]" replyto="$row->[11]"$mypost>\n~;
        print qq~\t\t\t\t$indent<body>$body</body>\n~;
        print qq~\t\t\t$indent</post>\n~;
    }

    # Close the thread, forum, parent nodes and forums node
    print "\t\t$indent</thread>\n\t$indent</forum>\n" . $closing_nodes . "\t</forums>\n";
    
    # increment thread views
    # TODO this needs to ignore views for the duration of the users session to avoid incrementing views for each page of thread
    $DB->query("UPDATE ${module_db_prefix}threads SET views = views + 1 WHERE id = ? LIMIT 1", $thread_id);
}

=xml
        <function name="create_thread">
            <synopsis>
                Create a new thread
            </synopsis>
            <todo>
                Formating editor, smiles and character count js
            </todo>
        </function>
=cut

sub create_thread {
    my $forum_id = shift;
    
    user::require_permission('forums_create_threads');
    user::require_permission('forums_create_posts');
    style::include_template('create_thread');
    user::print_module_permissions('forums');
    
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
        my $gmtime = datetime::gmtime();
        my $ctime = datetime::from_unixtime($gmtime);
        my $notify = defined $INPUT{'enable_notification'} ? 1 : 0;
        my $sticky = defined $INPUT{'sticky'} ? 1 : 0;
        my $locked = defined $INPUT{'locked'} ? 1 : 0;
        my $signature = defined $INPUT{'disable_signature'} ? 1 : 0;
        my $smiles = defined $INPUT{'disable_smiles'} ? 1 : 0;
        my $bbcode = defined $INPUT{'disable_bbcode'} ? 1: 0;
        my $subject = xml::entities($INPUT{'subject'}, 'proper_english');
        my $body = xml::entities($INPUT{'body'}, 'proper_english');
        my $body_xhtml;
        
        # Validate post title and body
        my $success = try {
            my @errors;
            
            # Subject min-length
            push @errors, 'Subject is too short. Minimum of '. $config{'min_subject_length'} .' characters required.' if length $INPUT{'subject'} < $config{'min_subject_length'};
                        
            # Subject max-length
            push @errors, 'Subject is too long. Maximum of '. $config{'max_subject_length'} .' characters allowed.' if length $INPUT{'subject'} > $config{'max_subject_length'};
            
            # Post body max-length
            push @errors, 'Post body is too long. Maximum of '. $config{'max_post_length'} .' characters allowed.' if length $INPUT{'body'} > $config{'max_post_length'};
            
            # Post body bbcode
            try { $body_xhtml = xml::bbcode($INPUT{'body'}) } catch 'validation_error', with { push @errors, 'Message contains incorrect bbCode. '. shift; abort(1); } if $bbcode == 0; 
            
            # Throw errors if any
            throw 'validation_error' => @errors if @errors > 0;
        };
        
        # If validation fails or previewing
        if (!$success or $INPUT{'preview'}) {
            my $signature_xhtml = xml::bbcode($USER{'signature'}) if $signature == 0;
            $body_xhtml = $body if $bbcode == 1;
                    
            print qq~\t\t$indent<post title="$subject" author_id="$USER{'id'}" author_name="$USER{'name'}" ctime="$ctime" notify="$notify" sticky="$sticky" locked="$locked" signature="$signature" smiles="$smiles" bbcode="$bbcode">\n~;
            print qq~\t\t\t$indent<body>\n~;
            print qq~\t\t\t\t$indent<raw>$body</raw>\n~;
            print qq~\t\t\t\t$indent<xhtml>$body_xhtml</xhtml>\n~ if $success;
            print qq~\t\t\t$indent</body>\n~;
            print qq~\t\t\t$indent<signature>$signature_xhtml</signature>\n~ if $signature_xhtml;
            print qq~\t\t$indent</post>\n~;
        }
        
        # If validation succeeded and saving
        elsif ($success and $INPUT{'save'}) {            
            
            # Insert into the thread table


            # Insert into the post table
            
            
            # Update cache and sync daemons
            ipc::do('forums', '_cache_forums');

            # Confirmation
            confirmation('Your thread has been created. You will be redirected to your new thread.');
            my $thread_id = 'test';
            print qq~\t\t$indent<post title="$subject" id="$thread_id" />\n~; 
        }           
    }
    
    # Close the forum, parent nodes and forums node
    print "\t$indent</forum>\n" . $closing_nodes . "\t</forums>\n";
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
        my $query_update_site_config = $DB->prepare("UPDATE ${module_db_prefix}config SET value = ? WHERE name = ?");
        map { $query_update_site_config->execute($INPUT{$_}, $_) } @site_fields;

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
    push(@{$parents}, $parent) if defined $parent;
    
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
            %forums = ( forum_id => { id => value, name => value, parent_id => value, description => value, priority => value }, );
        </note>
    </function>
=cut

sub _cache_forums {
    # Clear the current cache, if any
    %forums = ();
    
    # Retrieve the forums
    my $query = $DB->query("SELECT id, name, parent_id, description, priority FROM ${DB_PREFIX}forums");
    
    # Stick it in
    while ( my $forum = $query->fetchrow_hashref() ) {
        
        # The last post data
        my $lastpost = $DB->query("SELECT lastpost_date, lastpost_author, lastpost_id, title FROM ${module_db_prefix}threads WHERE forum_id = ? ORDER BY date DESC LIMIT 1", $forum->{'id'});
        ($forum->{'lastpost_date'}, $forum->{'lastpost_author'}, $forum->{'lastpost_id'}, $forum->{'lastpost_title'}) = @{$lastpost->fetchrow_arrayref()};

        # Thread and post count
        # To store in the sql table or not to is the question...
        my $counts = $DB->query("SELECT replies FROM ${module_db_prefix}threads WHERE forum_id = ?", $forum->{'id'});
        my ($threads, $posts) = 0;
        while ( my $row = $counts->fetchrow_arrayref() ) {
            $posts = ++$posts + $row->[0];
            ++$threads;
        }
        ($forum->{'threads'}, $forum->{'posts'}) = ($threads, $posts);

        # Everything else
        $forums{ $forum->{'id'} } = $forum;
    }
}

=xml
    <function name="_pretty_dates">
        <synopsis>
            Returns how long ago a post was
        </synopsis>
        <note> 
            This should ideally be done in XSL but the required XSL1 for calculating date differences is rather heavy
        </note>
    </function>
=cut

sub _pretty_dates {
    my $date = shift;

    # Age of the post in seconds
    $date = datetime::gmtime() - $date;

    # Days in this month
    my $days = datetime::days_in_month(1900 + [gmtime()]->[5], ++[gmtime()]->[4]);

    if ($date <= 60) { $date = "Today, " . $date . " seconds"; }                                # lte one minute
    elsif ($date <= 3600) { $date = "Today, " . math::ceil($date / 60) . " minutes"; }          # lte one hour
    elsif ($date <= 86400) { $date = "Today, " . math::ceil($date / 3600) . " hours"; }         # lte one day
    elsif ($date <= 172800) { $date = "Yesterday, " . math::ceil($date / 3600) . " hours"; }    # lte two days
    elsif ($date <= 604800) { $date = math::ceil($date / 86400) . " days"; }                    # lte one week
    elsif ($date <= (86400 * $days)) { $date = math::round($date / 604800) . " weeks"; }        # lte one month
    elsif ($date <= 31536000) { $date = math::round($date / 2629743.83) . " months"; }          # lte one year
    elsif ($date <= 63072000) { $date = "1 year"; }                                             # lte 2 years
    else { $date = math::round($date / 31536000) . " years"; }
    
    return $date;
}

=xml
</document>
=cut

1;

# Copyright BitPiston 2008