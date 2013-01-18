=xml
<document title="Content Module">
    <synopsis>
        Content management of pages.
    </synopsis>
    <warning>
        Work in progress.
    </warning>
=cut

package content;

# import libraries
use oyster 'module';
use exceptions;
use string;
use hash;
use url;
use xml;

# import modules
use user;

=xml
    <function name="hook_load">
        <synopsis>
            Prepares queries to be used later.
        </synopsis>
        <note>
            This uses event::register_hook() to execute at the right times.
        </note>
    </function>
=cut

event::register_hook('load', 'hook_load');
sub hook_load {
    
    # pages cant be named this!
    our @reserved_urls = ('content', 'admin'); # note: 'content' is required so short urls don't confuse things, 'admin' is the content admin page

    # used to validate field types
    our %field_types = (
        'text_small'     => 1,
        'text'           => 1,
        'text_large'     => 1,
        'text_full'      => 1,
        'textarea_small' => 1,
        'textarea'       => 1,
        'textarea_large' => 1,
        'textarea_full'  => 1,
        'dropdown'       => 1,
    );
    
    our $fetch_page_by_hash = $DB->prepare("SELECT id, title, ctime, mtime, url_hash FROM ${module_db_prefix}pages WHERE url_hash = ? LIMIT 1");
    our $fetch_page_by_id   = $DB->prepare("SELECT id, title, ctime, mtime, url_hash FROM ${module_db_prefix}pages WHERE id = ? LIMIT 1");
    our $fetch_fields       = $DB->prepare("SELECT name, translated_value, inside_content_node, call_data FROM ${module_db_prefix}page_fields WHERE page_id = ?");
    our $fetch_subpages     = $DB->prepare("SELECT id, title, url FROM ${module_db_prefix}pages WHERE parent_id = ?");
}

=xml
    <function name="view_page">
        <synopsis>
            Retrieve and print the content page's fields.
        </synopsis>
        <prototype>
            view_page(string page_url, int page_id[, ignore_query_string => bool][, skip_admin_links => bool])
        </prototype>
    </function>
=cut

sub view_page {
    #my $url = $_[0]; # don't shift! (see "administrative links" below)
    my $url     = $REQUEST{'url'}; # why not? why did we pass params from the url table?
    my $id      = shift;
    my %options = @_;
    my ($title, $ctime, $mtime, $url_hash);
    
    # check for query string actions
    if ($INPUT{'a'} and !$options{'ignore_query_string'}) {
        if ($INPUT{'a'} eq 'create') {
            create_page();
            return;
        } elsif ($INPUT{'a'} eq 'edit') {
            edit_page();
            return;
        } elsif ($INPUT{'a'} eq 'delete') {
            delete_page();
            return;
        } elsif ($INPUT{'a'} eq 'revisions') {
            page_revisions();
            return;
        }
    }
        
    #user::require_permission('content_view');
    #user::print_module_permissions('content');

    # page_view() was passed a page url
    if ($id) {
        
        # Retrieve page matching url from the db or 404 error
        $fetch_page_by_id->execute($url_hash);
        
        # extract data from the query
        ($id, $title, $ctime, $mtime, $url_hash) = @{$fetch_page_by_id->fetchrow_arrayref()};
        
        #throw 'request_404' unless $fetch_page->rows();
    }
    
    else {
        
        if ($url) {
            $url_hash = hash::fast($url);
        }

        # no url was passed to page_view() fall back to the default page
        else {
            $url = $config{'default_url'};
            $url_hash = hash::fast($url);
        }
    
        # Retrieve page matching url from the db or 404 error
        $fetch_page_by_hash->execute($url_hash);
        
        # extract data from the query
        ($id, $title, $ctime, $mtime, $url_hash) = @{$fetch_page_by_hash->fetchrow_arrayref()};
        
        #throw 'request_404' unless $fetch_page->rows();
    }
    
    style::include_template('view_page');
    
    # print the page
    print "\t<content action=\"view\" title=\"$title\" ctime=\"$ctime\" mtime=\"$mtime\">\n";
    $fetch_fields->execute($id);
    while (my $field = $fetch_fields->fetchrow_arrayref()) {
        my ($name, $value, $inside_content_node, $call_data) = @{$field};
        
        replace_call_data($value, $call_data) if $call_data;
        print "\t\t<$name>$value</$name>\n";
    }
    print "\t</content>\n";
    
    #url::_load_nav_urls_by_parent_id($id, $config{'subpage_depth'}) if $config{'subpage_depth'};
    
    # contextual admin menu
    _contextual_admin_menu($id);
}

=xml
    <function name="edit_page">
        <synopsis>
            Edits and existing page.
        </synopsis>
    </function>
=cut

sub edit_page {
    user::require_permission('content_edit');
    user::print_module_permissions('content');

    # validate page id and fetch page data
    my $select_page      = $DB->query('SELECT * ' . _from());
    throw 'request_404' unless $select_page->rows();
    my $page             = $select_page->fetchrow_hashref();
    my $page_id          = $page->{'id'};
    my $page_slug        = $page->{'slug'};
    $page->{'url'}       = $REQUEST{'url'}; # this needs to be deprecated and replaced with $REQUEST{'url}
    $page->{'parent_id'} = $REQUEST{'current_url'}->{'parent_id'}; # this needs to be deprecated and replaced with $REQUEST{'current_url'}->{'parent_id'}
    my $parent           = url::get_by_id($page->{'parent_id'});
    
    # if the form has been submitted
    if ($ENV{'REQUEST_METHOD'} eq 'POST') {
        my ($show_nav_link, @fields, $has_validated, $fields_validated);

        # process fields in %INPUT
        @fields = _process_input_fields();

        # validate form input
        $has_validated = try {

            # validate title
            throw validation_error, 'A page title is required.' unless length $INPUT{'title'};
            
            # validate title
            throw validation_error, 'A page slug is required.' unless length $INPUT{'slug'};
            
            # validate show navigation link checkbox
            $show_nav_link = $INPUT{'show_nav_link'} ? 1 : 0 ;

            # validate fields
            $fields_validated = try { _validate_fields(@fields) };
            abort(1) unless $fields_validated; # abort the current try block if _validate_fields failed (so $has_validated is false)
        };

        # assemble some variables
        my $title = xml::entities($INPUT{'title'}, 'proper_english');
        my $slug  = $INPUT{'slug'};

        # is the user trying to save this?
        if ($has_validated and $INPUT{'save'}) {
            my %update_url; # fields that need to be updated in the url

            # find a unique url for this page if the page title has changed
            my $url = string::urlify($slug);
            $url    = "$parent->{url}/$url" if $parent->{'id'};
            if ($url ne $page->{'url'}) {
                $url = url::unique($url);
                $update_url{'url'}   = $url;   # update url
                $update_url{'title'} = $title; # update url title
            }
            
            # update show_nav_link in the url (if necessary)
            $update_url{'show_nav_link'} = $show_nav_link if $show_nav_link != $page->{'show_nav_link'};

            # update the url (if necessary)
            url::update(url => $page->{'url'}, %update_url) if %update_url;

            # make a revision of this page
            _create_revision($page_id);

            # update the page
            my $query = $DB->query(
                "UPDATE ${module_db_prefix}pages SET title = ?, mtime = NOW(), author_id = ?, url_hash = ?, slug = ? WHERE id = ?",
                $title, $user::data{'id'}, hash::fast($url), $slug, $page_id
            );

            # save fields
            _save_fields($page_id, @fields);

            # confirmation
            confirmation('The page has been saved.');

            # reload navigation
            ipc::do('url', 'load_navigation') if $show_nav_link == 1;

            # display the page
            view_page($page_id, 'ignore_query_string' => 1, 'skip_admin_links' => 1);

            # contextual admin menu
            _contextual_admin_menu($page_id);
        }

        # the user is not trying to submit, only preview, or they tried to submit and their page did not validate
        else {

            # preview
            # TODO: does not obey inside_content_node
            if ($has_validated) {
                print "\t<content action=\"view\" preview=\"true\" title=\"$title\" slug=\"$slug\">\n";
                for my $field (@fields) {
                    replace_call_data($field->{'translated_value'}, $field->{'call_data'}) if $field->{'call_data'};
                    print "\t\t<$field->{id}>$field->{translated_value}</$field->{id}>\n";
                }
                print "\t</content>\n";
            }

            # make changes/save form
            style::include_template('create_edit');
            print "\t<content action=\"edit\" id=\"$page_id\" parent=\"$page->{parent_id}\" has_validated=\"$has_validated\" title=\"$title\" slug=\"$slug\" show_nav_link=\"" . ( $show_nav_link ? 'true' : 'false' ) . "\" can_add_files=\"" . ( $PERMISSIONS{'file_add'} ? 'true' : 'false' ) . "\">\n";
            if ($fields_validated) {
                #print "\t\t<field type=\"text\" />\n";
            } else {
                #my $field = shift(@fields);
                #print "\t\t<field name=\"$field->{name}\" type=\"$field->{type}\" translation_mode=\"$field->{translation_mode}\" inside_content_node=\"$field->{inside_content_node}\" />\n";
            }
            _print_fields(@fields);
            print "\t</content>\n";

            # contextual admin menu
            _contextual_admin_menu($page_id, 'edit');
        }
    }

    # print a fresh edit page form
    else {
        style::include_template('create_edit');
        print "\t<content action=\"edit\" id=\"$page->{id}\" parent=\"$page->{parent_id}\" title=\"$page->{title}\" slug=\"$page->{slug}\" show_nav_link=\"" . ( $page->{'show_nav_link'} ? 'true' : 'false' ) . "\" can_add_files=\"" . ( $PERMISSIONS{'file_add'} ? 'true' : 'false' ) . "\">\n";
        #print "\t\t<field type=\"text\" />\n";
        _print_page_fields($page_id);
        print "\t</content>\n";

        # contextual admin menu
        _contextual_admin_menu($page_id, 'edit');
    }
}

=xml
    <function name="create_page">
        <synopsis>
            Creates a new content page.
        </synopsis>
    </function>
=cut

sub create_page {
    user::require_permission('content_create');
    user::print_module_permissions('content');
    
    # validate parent id
    my $parent = {'id' => 0, 'url' => ''};
    if ($INPUT{'parent'}) {
        $parent = url::get_by_id($INPUT{'parent'});
        throw validation_error, 'Invalid parent ID.' unless $parent->{'id'};
    }

    # if the form has been submitted
    if ($ENV{'REQUEST_METHOD'} eq 'POST') {
        my ($show_nav_link, @fields, $has_validated, $fields_validated);

        # process fields in %INPUT
        @fields = _process_input_fields();

        # validate form input
        $has_validated = try {
            my @errors;

            # validate title
            push @errors, 'A page title is required.' unless length $INPUT{'title'};
            
            # validate title
            push @errors, 'A page slug is required.' unless length $INPUT{'slug'};
            
            # validate show navigation link checkbox
            $show_nav_link = $INPUT{'show_nav_link'} ? 1 : 0 ;

            # validate fields
            $fields_validated = try { _validate_fields(@fields) };
            abort(1) unless $fields_validated; # abort the current try block if _validate_fields failed (so $has_validated is false)
            
            throw 'validation_error' => @errors if @errors > 0;
        };
        
        # assemble some variables
        my $title = xml::entities($INPUT{'title'}, 'proper_english');

        # is the user trying to save this?
        if ($has_validated and $INPUT{'save'}) {

            # find a unique url for this page
            my $url = string::urlify($INPUT{'slug'});
            $url = "$parent->{url}/$url" if $parent->{'id'};
            $url = url::unique($url);

            # register this page's url
            my $url_id = url::register(
                'url'           => $url,
                'module'        => 'content',
                'function'      => 'view_page',
                'title'         => $title,
                'show_nav_link' => $show_nav_link
            );

            # insert the page into the database
            my $query = $DB->query(
                "INSERT INTO ${module_db_prefix}pages (id, parent_id, title, ctime, mtime, author_id, url_hash, slug) VALUES (?, ?, ?, NOW(), NOW(), ?, ?, ?)",
                $url_id, $parent->{'id'}, $title, $USER{'id'}, hash::fast($url), $INPUT{'slug'}
            );
            my $page_id = $DB->insert_id();

            # update the url to contain the page's id
            # we don't need this anymore do we? since we switched from param to a hash of the current request url...
            #url::update($url, 'params' => [$page_id]);
            
            # save fields
            _save_fields($page_id, @fields);

            # confirmation
            confirmation('A page has been created.');

            # reload navigation
            ipc::do('url', 'load_navigation') if $show_nav_link == 1;

            # display the page
            #view_page($url, $page_id, 'ignore_query_string' => 1, 'skip_admin_links' => 1);
            view_page($page_id, 'ignore_query_string' => 1, 'skip_admin_links' => 1);

            # add admin menu items
            #module::sims::admin_menu::menu_url('This Page' => "$BASE_URL$url/");
            #module::sims::admin_menu::add_sub_page_item('menu' => 'This Page', 'parent_id' => $url_id);
            #module::sims::admin_menu::add_item('menu' => 'This Page', 'label' => 'Edit',   'url' => "BASE_URL$url?a=edit")   if $PERMISSIONS{'content_edit'};
            #module::sims::admin_menu::add_item('menu' => 'This Page', 'label' => 'Delete', 'url' => "BASE_URL$url?a=delete") if $PERMISSIONS{'content_delete'};
        }

        # the user is not trying to submit, only preview, or they tried to submit and their page did not validate
        else {

            # preview
            # TODO: does not obey inside_content_node
            if ($has_validated) {
                print "\t<content action=\"view\" preview=\"true\" title=\"$title\">\n";
                for my $field (@fields) {
                    replace_call_data($field->{'translated_value'}, $field->{'call_data'}) if $field->{'call_data'};
                    print "\t\t<$field->{id}>$field->{translated_value}</$field->{id}>\n";
                }
                print "\t</content>\n";
            }

            # make changes/save form
            style::include_template('create_edit');
            print "\t<content action=\"create\" parent=\"$parent->{id}\" has_validated=\"$has_validated\" title=\"$title\" slug=\"$INPUT{slug}\" show_nav_link=\"" . ( $show_nav_link ? 'true' : 'false' ) . "\" can_add_files=\"" . ( $PERMISSIONS{'file_add'} ? 'true' : 'false' ) . "\">\n";
            if ($fields_validated) { # if fields validated, add a new field to the list
                #print "\t\t<field type=\"text\" />\n";
            } else {                 # field's didn't validate, the top field needs to be populated with the invalid field data
                #my $field = shift(@fields);
                #print "\t\t<field name=\"$field->{name}\" type=\"$field->{type}\" translation_mode=\"$field->{translation_mode}\" inside_content_node=\"$field->{inside_content_node}\" />\n";
            }
            _print_fields(@fields);
            print "\t</content>\n";
        }
    }

    # print a blank create page form or ask for a template
    else {
        style::include_template('create_edit');

        # validate the template id
        my $template_id;
        if ($INPUT{'template'}) {
            my $query = $DB->query("SELECT id FROM ${module_db_prefix}templates WHERE id = ? LIMIT 1", $INPUT{'template'});
            $template_id = $query->fetchrow_arrayref->[0] if $query->rows() == 1;
        }

        # check if there is only one template, if so use it
        unless ($template_id) {
            my $query = $DB->query("SELECT id FROM ${module_db_prefix}templates LIMIT 2");
            $template_id = $query->fetchrow_arrayref->[0] if $query->rows() == 1;
        }

        # if a valid template id is specified
        my $can_add_files = $PERMISSIONS{'file_add'} ? 'true' : 'false';
        if ($template_id) {
            print "\t<content action=\"create\" parent=\"$parent->{id}\" can_add_files=\"$can_add_files\">\n";
            #print "\t\t<field type=\"text\" />\n";
            _print_page_fields($template_id);
            print "\t</content>\n";
        }

        # otherwise, ask the user which template to use
        else {
            print "\t<content action=\"create_select_template\" parent=\"$parent->{id}\" can_add_files=\"$can_add_files\">\n";
            my $query = $DB->query("SELECT id, name FROM ${module_db_prefix}templates");
            while (my $template = $query->fetchrow_hashref()) {
            	print "\t\t<template id=\"$template->{id}\" name=\"$template->{name}\" />\n";
            }
            print "\t</content>\n";
        }
    }
}

=xml
    <function name="delete_page">
        <synopsis>
            Deletes the current page.
        </synopsis>
    </function>
=cut

sub delete_page {
    user::require_permission('content_delete');
    user::print_module_permissions('content');    

    # validate page id and fetch page data
    my $select_page = $DB->query('SELECT id, title, url_hash ' . _from());
    throw 'request_404' unless $select_page->rows();
    my ($page_id, $title, $url_hash) = @{$select_page->fetchrow_arrayref()};

    # contextual admin menu
    _contextual_admin_menu($page_id, 'delete');

    # check if the current page has subpages
    my $query = $DB->query("SELECT COUNT(*) FROM ${DB_PREFIX}urls WHERE parent_id = ? LIMIT 1", $REQUEST{'current_url'}->{'id'});
    throw 'validation_error', 'A page with subpages cannot be deleted.' if $query->fetchrow_arrayref()->[0];
    # ??? throw error, 

    # get confirmation
    confirm("Are you sure you wish to permanentally delete \"$title\"?");

    # delete the url
    $DB->query("DELETE FROM ${DB_PREFIX}urls WHERE module = 'content' and function = 'view_page' and url_hash = ?", $url_hash);

    # delete the page
    $DB->query("DELETE FROM ${module_db_prefix}pages WHERE id = ?", $page_id);

    # delete page fields
    $DB->query("DELETE FROM ${module_db_prefix}page_fields WHERE page_id = ?", $page_id);

    # delete page revisions and field history
    my $query_delete_page_revision      = $DB->prepare("DELETE FROM ${module_db_prefix}page_revisions WHERE id = ?");
    my $query_delete_page_field_history = $DB->prepare("DELETE FROM ${module_db_prefix}page_field_history WHERE revision_id = ?");
    my $query_select_revision_ids       = $DB->query("SELECT id FROM ${module_db_prefix}page_revisions WHERE page_id = ?", $page_id);
    while (my $rev = $query_select_revision_ids->fetchrow_arrayref()) {
        my $rev_id = $rev->[0];
        $query_delete_page_revision->execute($rev_id);
        $query_delete_page_field_history->execute($rev_id);
    }

    # print a confirmation message
    my %options;
    $options{'Content Administration'} = ${MODULE_ADMIN_BASE_URL} if $PERMISSIONS{'content_admin'};
    confirmation("\"$title\" has been deleted.", %options);

    # reload navigation if necessary
    ipc::do('url', 'load_navigation') if $REQUEST{'current_url'}->{'show_nav_link'};
}

=xml
    <function name="replace_call_data">
        <synopsis>
            Replaces include directives in text with the proper values for those directives.
        </synopsis>
        <note>
            Expects two arguments, the string to be interpolated into, and the include data.
        </note>
        <todo>
            Improved error catching - see # TODO.
        </todo>
    </function>
=cut

sub replace_call_data {
    my @calls = split(/\n/, $_[1]);
    for my $call (@calls) {
        my ($pos, $module, $function, @args) = split(/\0/, $call);
        substr($_[0], $pos, 0, &{"${module}::call_${function}"}(@args)); # TODO: wrap in eval to catch errors? or use UNIVERSAL::can?
    }
}

=xml
        <function name="admin">
            <synopsis>
                The administration menu
            </synopsis>
            <note>
                This is registered to the url 'admin/content'.
            </note>
        </function>
=cut

sub admin {

    # create admin center menu
    my $menu = 'content_admin';
    menu::label($menu, 'Content Administration');
    menu::description($menu, 'Some description...');

    # populate the admin menu
    menu::add_item('menu' => $menu, 'label' => 'Configuration', 'url' => $module_admin_base_url . 'config/') if $PERMISSIONS{'content_create'};
    menu::add_item('menu' => $menu, 'label' => 'Create a Page', 'url' => $module_admin_base_url . 'create/') if $PERMISSIONS{'content_admin_config'};
    menu::add_item('menu' => $menu, 'label' => 'Manage Templates', 'url' => $module_admin_base_url . 'templates/') if $PERMISSIONS{'content_templates'};
    

    # print the admin center menu
    throw 'permission_error' unless menu::print_xml($menu);
}

=xml
        <function name="admin_config">
            <synopsis>
                Manages the content module's configuration
            </synopsis>
            <note>
                This is registered to the url 'admin/content/config'.
            </note>
        </function>
=cut

sub admin_config {
    user::require_permission('user_admin_config');
    style::include_template('admin_config');
    
    # configuration variables
    my @fields = qw(num_revisions subpage_depth);

    # the input source for the edit config form, defaults to the existing config
    my $input_source = \%config;

    # the form has been submitted
    try {
        $input_source = \%INPUT;

        # validate input
        throw validation_error, 'Invalid number of revisions.' unless $INPUT{'num_revisions'} =~ /^\d+$/;
        throw validation_error, 'Invalid sub-page depth.'      unless $INPUT{'subpage_depth'} =~ /^\d+$/;

        # everything validated, update settings and print a confirmation
        my $query_update_config = $DB->prepare("UPDATE ${module_db_prefix}config SET value = ? WHERE name = ?");
        map { $query_update_config->execute($INPUT{$_}, $_) } @fields;

        # print a confirmation message
        confirmation('Content settings have been saved.');

        # reload content configuration in all daemons
        ipc::do('module', 'load_config', 'content');
    } if $ENV{'REQUEST_METHOD'} eq 'POST';

    # print the edit config form
    my $fields = join '', map { " $_=\"" . xml::entities($input_source->{$_}) . '"' } @fields;
    print "\t<content action=\"admin_config\"$fields />\n";
}

=xml
        <function name="admin_templates">
            <synopsis>
                Manages the content module's templates
            </synopsis>
            <note>
                This is registered to the url 'admin/content/templates'.
            </note>
        </function>
=cut

sub admin_templates {
    user::require_permission('content_templates');
    style::include_template('admin_templates');

    # the create template form has been submitted
    try {

        # validate template name
        throw validation_error, 'A template name is required.' unless $INPUT{'create_name'};
        my $name = xml::entities($INPUT{'create_name'});
        my $query = $DB->query("SELECT COUNT(*) FROM ${module_db_prefix}templates WHERE name = ? LIMIT 1", $name);
        throw validation_error, 'The selected template name is taken.' if $query->fetchrow_arrayref()->[0];

        # everything validated, create the template
        my $query = $DB->query("SELECT id FROM ${module_db_prefix}templates ORDER BY id ASC LIMIT 1");
        my $id = $query->rows() ? ($query->fetchrow_arrayref()->[0] - 1) : -1 ;
        $DB->query("INSERT INTO ${module_db_prefix}templates (id, name) VALUES (?, ?)", $id, $name);

        # print a confirmation
        confirmation('A new template has been created.');
    } if ($ENV{'REQUEST_METHOD'} eq 'POST' and $INPUT{'a'} eq 'create');

    # delete a template
    try {

        # if you only have one template, you can't delete it!
        my $query = $DB->query("SELECT COUNT(*) FROM ${module_db_prefix}templates LIMIT 2");
        throw validation_error, 'You must have at least one template. You cannot delete the last template.' if $query->fetchrow_arrayref()->[0] == 1;

        # validate template id
        my $query = $DB->query("SELECT COUNT(*) FROM ${module_db_prefix}templates WHERE id = ? LIMIT 1", $INPUT{'id'});
        throw validation_error, 'Invalid template ID.' unless $query->fetchrow_arrayref()->[0];

        # everything validated, delete the template
        $DB->query("DELETE FROM ${module_db_prefix}templates WHERE id = ? LIMIT 1", $INPUT{'id'});
        $DB->query("DELETE FROM ${module_db_prefix}page_fields WHERE page_id = ?", $INPUT{'id'});

        # print a confirmation
        confirmation('The selected template has been deleted.');
    } if ($INPUT{'a'} eq 'delete');

    # print manage templates menu
    print "\t<content action=\"admin_templates\" create_name=\"" . xml::entities($INPUT{'create_name'}) . "\">\n";
    my $query = $DB->query("SELECT id, name FROM ${module_db_prefix}templates");
    while (my $template = $query->fetchrow_hashref()) {
        print "\t\t<template id=\"$template->{id}\" name=\"$template->{name}\" />\n";
    }
    print "\t</content>\n";
}

=xml
        <function name="admin_edit_templates">
            <synopsis>
                Manages the content module's templates
            </synopsis>
            <note>
                This is registered to the url 'admin/content/templates'.
            </note>
        </function>
=cut

sub admin_edit_template {
    user::require_permission('content_templates');
    style::include_template('admin_templates_edit');

    # validate template id
    my $id = $INPUT{'id'};
    my $query = $DB->query("SELECT name FROM ${module_db_prefix}templates WHERE id = ? LIMIT 1", $id);
    throw validation_error, 'Invalid template ID.' unless $query->rows();
    my $name = $query->fetchrow_arrayref()->[0];

    # if the form has been submitted
    if ($ENV{'REQUEST_METHOD'} eq 'POST') {

        # transform %INPUT field data into a nice data structure
        my @fields = _process_input_fields();

        # validate input
        $name = xml::entities($INPUT{'name'});
        my $validated = try {

            # validate template name
            throw validation_error,'Invalid name.' unless $name;

            # validate fields
            _validate_fields(@fields);
        };

        # if all input validated
        if ($validated) {

            # update the template name
            $DB->query("UPDATE ${module_db_prefix}templates SET name = ? WHERE id = ?", $name, $id);

            # save the template fields
            _save_fields($id, @fields);

            # print a confirmation message
            confirmation("The template '$name' has been saved.");
        }

        # reprint the edit template form
        print "\t<content action=\"admin_templates_edit\" name=\"$name\">\n";

        # print the new field form
        print "\t\t<field type=\"textarea\" translation_mode=\"xhtml\" inside_content_node=\"1\" />\n" if $validated;

        # print fields
        _print_fields(@fields);
        print "\t</content>\n";
    }

    # print a fresh edit template form
    else {
        print "\t<content action=\"admin_templates_edit\" name=\"$name\">\n";
        print "\t\t<field type=\"textarea\" translation_mode=\"xhtml\" inside_content_node=\"1\" />\n";
        _print_page_fields($id);
        print "\t</content>\n";
    }
}


# ----------------------------------------------------------------------------
# Administration Center Menus
# ----------------------------------------------------------------------------

# config, create page and manage templates menus
event::register_hook('admin_center_config_menu', 'hook_admin_center_config_menu');
sub hook_admin_center_config_menu {
    menu::add_item('parent' => $_[0], 'label' => 'Configuration', 'url' => $module_admin_base_url . 'config/') if $PERMISSIONS{'content_create'};
    menu::add_item('parent' => $_[0], 'label' => 'Create a Page', 'url' => $module_admin_base_url . 'create/') if $PERMISSIONS{'content_admin_config'};
    menu::add_item('parent' => $_[0], 'label' => 'Manage Templates', 'url' => $module_admin_base_url . 'templates/') if $PERMISSIONS{'content_templates'};
}

# modules menu
event::register_hook('admin_center_modules_menu', 'hook_admin_center_modules_menu');
sub hook_admin_center_modules_menu {
    menu::add_item('parent' => $_[0], 'label' => 'Content', 'url' => $module_admin_base_url) if $PERMISSIONS{'content_admin_config'};
}

# called when the admin menu is printed (after the module admin menu)
event::register_hook('admin_menu', 'hook_admin_menu');
sub hook_admin_menu {
    menu::add_item('parent' => $_[0], 'label' => 'Content', 'url' => $module_admin_base_url) if ($REQUEST{'module'} ne 'content' and $PERMISSIONS{'content_admin'});

    my $item = menu::add_item('menu' => 'admin', 'label' => 'Content', 'id' => 'content', 'require_children' => 1);
    menu::add_item('parent' => $item, 'label' => 'Create a Page',    'url' => $module_admin_base_url . 'create/') if $PERMISSIONS{'content_create'};
    menu::add_item('parent' => $item, 'label' => 'Manage Templates', 'url' => $module_admin_base_url . 'templates/') if $PERMISSIONS{'content_templates'};
    menu::add_item('parent' => $item, 'label' => 'Configuration',    'url' => $module_admin_base_url . 'config/') if $PERMISSIONS{'content_admin_config'};
}


# ----------------------------------------------------------------------------
# Helpers
# ----------------------------------------------------------------------------

# constructs FROM and WHERE clauses for a mysql statement to find the current content page
sub _from {
    return "FROM ${module_db_prefix}pages WHERE url_hash = '" . hash::fast($REQUEST{'url'}) . "' LIMIT 1";
}

# used to get an id for a custom field from the name
sub _get_field_id {
    my $text = lc(shift());
    $text =~ s!\s+!_!g; # replace whitespace with underscores
    $text =~ s!_+!_!g;  # replace multiple underscores with a single underscore
    $text =~ s!\W!!g;   # remove non alphanumeric/underscore characters
    $text =~ s!^_!!;    # trim leading underscore
    $text =~ s!_$!!;    # trim trailing underscore
    return $text;
}

# processes %INPUT to get field data and puts it in a nice data structure
sub _process_input_fields {

    # iterate through fields and store their info in a data structure
    my @fields;
    my $i = 1;
    while ($INPUT{"field_$i"}) {
        next unless $INPUT{"field_${i}_name"}; # skip this field unless it has a name
        my %field = (
            'name'                => $INPUT{"field_${i}_name"},
            'value'               => $INPUT{"field_${i}_value"},
            'type'                => $INPUT{"field_${i}_type"},
            'inside_content_node' => $INPUT{"field_${i}_inside_content_node"},
            'translation_mode'    => '',
            'call_data'           => '',
        );
        $field{'translation_mode'} = $INPUT{"field_${i}_translation_mode"} if $field{'type'} =~ m!^textarea!; # only textareas have a translation mode
        if ($field{'type'} eq 'dropdown') {
            $field{'options'} = [];
            my $x = 1;
            while (defined($INPUT{"field_${i}_dropdown_option_$x"})) {
                next unless $INPUT{"field_${i}_dropdown_option_$x"}; # skip empty options
                push(@{$field{'options'}}, xml::entities($INPUT{"field_${i}_dropdown_option_$x"}));
            } continue {
                $x++;
            }
        }
        push(@fields, \%field);
    } continue {
        $i++;
    }

    return @fields;
}

# validates the data structure returned by _process_input_fields, expects one arg, @fields (not a ref!)
sub _validate_fields {

    # iterate through fields and validate them
    for my $field (@_) {

        # validate field name
        $field->{'name'} = xml::entities($field->{'name'});
        throw validation_error, 'Invalid field name.' unless $field->{'name'};
        $field->{'id'} = _get_field_id($field->{'name'});
        # TODO: field names must be xml node-name compliant! i dont think whitespace or numbers qualify, subpage shouldnt be a reserved name anymore, although menu should
        throw validation_error, 'Invalid field name.  A field name must contain at least one alphanumeric or whitespace character.' unless $field->{'id'};
        throw validation_error, "'$field->{name}' is a reserved name." if $field->{'id'} eq 'subpages';

        # validate inside_content_node
        $field->{'inside_content_node'} = $field->{'inside_content_node'} ? 1 : 0;

        # validate field type
        throw validation_error, 'Invalid field type.' unless ($field_types{$field->{'type'}});

        # validate translation mode (if the type is a textarea)
        $field->{'translation_mode'} = $field->{'translation_mode'} eq 'xhtml' ? 'xhtml' : 'bbcode' if $field->{'type'} =~ /^textarea/;
        
        # if the field has a value and has to be translated
        if ($field->{'value'}) {
            if ($field->{'translation_mode'}) {
                if ($field->{'translation_mode'} eq 'xhtml') {
                    ($field->{'translated_value'}, $field->{'call_data'}) = xml::validate_xhtml($field->{'value'}, 'allow_calls' => 1, 'allow_includes' => 1);
                } else {
                    ($field->{'translated_value'}, $field->{'call_data'}) = xml::bbcode($field->{'value'}, 'allow_calls' => 1, 'allow_includes' => 1);
                }
            } else {
                $field->{'translated_value'} = xml::entities($field->{'value'});
            }
        } else {
            ($field->{'value'}, $field->{'translated_value'}) = ('', ''); # can't be null
        }
    }
}

# saves fields to a page/template, expects two args, the page id and @fields (not a ref!)
sub _save_fields {
    my $page_id = shift;

    # delete existing fields by this page id
    $DB->do("DELETE FROM ${module_db_prefix}page_fields WHERE page_id = $page_id");

    # iterate through fields and save them
    for my $field (@_) {
        my $data = '';
        if ($field->{'type'} eq 'dropdown') {
            $data = join("\n", @{$field->{'options'}});
        }
        $DB->query(
            "INSERT INTO ${module_db_prefix}page_fields (page_id, data, name, type, translation_mode, value, translated_value, call_data, inside_content_node) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
            $page_id, $data, $field->{'name'}, $field->{'type'}, $field->{'translation_mode'}, $field->{'value'}, $field->{'translated_value'}, $field->{'call_data'}, $field->{'inside_content_node'}
        );
    }
}

# print field data for editing, expects one or more arguments
sub _print_fields {
    for my $field (@_) {
        print "\t\t<field name=\"$field->{name}\" type=\"$field->{type}\" translation_mode=\"$field->{translation_mode}\" inside_content_node=\"$field->{inside_content_node}\">\n";
        if ($field->{'type'} eq 'dropdown') {
            for my $option (@{$field->{'options'}}) {
                print "\t\t\t<option value=\"$option\"/>\n";
            }
        }
        print "\t\t\t<value>" . xml::entities($field->{'value'}) . "</value>\n";
        print "\t\t</field>\n";
    }
}

# print field data for editing, expects one argument, page_id
sub _print_page_fields {
    my $page_id = shift;

    my $query = $DB->query("SELECT * FROM ${module_db_prefix}page_fields WHERE page_id = ?", $page_id);
    while (my $field = $query->fetchrow_hashref()) {
        print "\t\t<field name=\"$field->{name}\" type=\"$field->{type}\" translation_mode=\"$field->{translation_mode}\" inside_content_node=\"$field->{inside_content_node}\">\n";
        if ($field->{'type'} eq 'dropdown') {
            my @options = split(/\n/, $field->{'data'});
            for my $option (@options) {
                print "\t\t\t<option value=\"$option\"/>\n";
            }
        }
        print "\t\t\t<value>" . xml::entities($field->{'value'}) . "</value>\n";
        print "\t\t</field>\n";
    }
}

# create a revision of a page
sub _create_revision {
    return unless $config{'num_revisions'};

    my ($page_id, $dont_delete_yet) = @_;

    # fetch current page data
    my $page = $DB->query("SELECT title, mtime, author_id FROM ${module_db_prefix}pages WHERE id = ? LIMIT 1", $page_id)->fetchrow_hashref();

    # create revision entry
    my $query = $DB->query("INSERT INTO ${module_db_prefix}page_revisions (page_id, mtime, title, author_id) VALUES (?, ?, ?, ?)", $page_id, @{$page}{qw(mtime title author_id)});
    my $rev_id = $DB->insert_id("${module_db_prefix}page_revision_id");

    # copy all fields
    my $query = $DB->query("SELECT page_id, name, type, data, translation_mode, inside_content_node, value, translated_value, call_data FROM ${module_db_prefix}page_fields WHERE page_id = ?", $page_id);
    while (my $field = $query->fetchrow_arrayref()) {
        $DB->query("INSERT INTO ${module_db_prefix}page_field_history (revision_id, page_id, name, type, data, translation_mode, inside_content_node, value, translated_value, call_data) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", $rev_id, @{$field});
    }

    _delete_old_revisions($page_id) unless $dont_delete_yet;
}

sub _delete_old_revisions {
    my $page_id = shift;

    # delete old revision beyond num_revisions threshhold
    my $query = $DB->query("SELECT id FROM ${module_db_prefix}page_revisions WHERE page_id = ? ORDER BY id DESC LIMIT $config{num_revisions}, 100", $page_id);
    while (my $rev = $query->fetchrow_arrayref()) {
        my $rev_id = $rev->[0];
        $DB->do("DELETE FROM ${module_db_prefix}page_revisions WHERE id = $rev_id LIMIT 1");
        $DB->do("DELETE FROM ${module_db_prefix}page_field_history WHERE revision_id = $rev_id");
    }
}

# Prints contextual admin menus
sub _contextual_admin_menu {
    my ($id, $exclude) = @_;
    if ($PERMISSIONS{'content_admin'}) {
        my $item = menu::add_item('menu' => 'admin', 'label' => 'This Page', 'id' => 'content');
        menu::add_item('parent' => $item, 'label' => 'Create a Sub-page',    'url' => '/' . $REQUEST{'url'} . '/?a=create&amp;parent=' . $id) if $PERMISSIONS{'content_create'} and $exclude ne 'create';
        menu::add_item('parent' => $item, 'label' => 'Edit',                 'url' => '/' . $REQUEST{'url'} . '/?a=edit') if $PERMISSIONS{'content_edit'} and $exclude ne 'edit';
        menu::add_item('parent' => $item, 'label' => 'Delete',               'url' => '/' . $REQUEST{'url'} . '/?a=delete') if $PERMISSIONS{'content_delete'} and $exclude ne 'delete';
        #menu::add_item('parent' => $item, 'label' => 'Revisions',            'url' => '/' . $REQUEST{'url'} . '/?a=revisions') if $PERMISSIONS{'content_revisions'} and $exclude ne 'revisions';
    }
}

=xml
</document>
=cut

1;

# Copyright BitPiston 2011