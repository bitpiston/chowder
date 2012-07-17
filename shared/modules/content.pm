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
    
    our $fetch_page   = $DB->prepare("SELECT id, title, ctime, mtime FROM ${module_db_prefix}pages WHERE url_hash = ? LIMIT 1");
    our $fetch_fields = $DB->prepare("SELECT name, translated_value, inside_content_node, call_data FROM ${module_db_prefix}page_fields WHERE page_id = ?");
}

=xml
    <function name="view_page">
        <synopsis>
            Retrieve and print the content page's fields.
        </synopsis>
    </function>
=cut

sub view_page {
    #my $url = $_[0]; # don't shift! (see "administrative links" below)
    my $url = $oyster::REQUEST{'url'}; # why not? why did we pass params from the url table?
    my $url_hash;
    
    #user::require_permission('content_view');
    #user::print_module_permissions('content');

    # page_view() was passed a page url
    if ($url) {
        $url_hash = hash::fast($url);
    }

    # no url was passed to page_view() fall back to the default page
    else {
        $url = $config{'default_url'};
        $url_hash = hash::fast($url);
    }
    
    # Retrieve page matching url from the db or 404 error
    $fetch_page->execute($url_hash);
    #throw 'request_404' unless $fetch_page->rows();
    
    # extract data from the query
    my ($id, $title, $ctime, $mtime) = @{$fetch_page->fetchrow_arrayref()};
    
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

sub page_create {
    user::require_permission('content_create');
    user::print_module_permissions('content');

    # validate parent id
    my ($parent_id, $parent_url) = (0, '');
    if ($INPUT{'parent'}) {
        my $query = $DB->query("SELECT id, url FROM ${module_db_prefix}pages WHERE id = ? LIMIT 1", $INPUT{'parent'});
        throw 'validation_error', 'Invalid parent ID.' unless $query->rows();
        ($parent_id, $parent_url) = @{$query->fetchrow_arrayref()};
    }

    # if the form has been submitted
    if ($ENV{'REQUEST_METHOD'} eq 'POST') {
        my ($show_nav_link, @fields, $has_validated, $fields_validated);

        # process fields in %INPUT
        @fields = _process_input_fields();

        # validate form input
        $has_validated = try {

            # validate show navigation link checkbox
            $show_nav_link = $INPUT{'show_nav_link'} ? 1 : 0 ;

            # validate fields
            $fields_validated = try { _validate_fields(@fields) };
            throw 'validation_error', 'Invalid fields.' unless $fields_validated;

            # validate title
            throw 'validation_error', 'A page title is required.' unless length($INPUT{'title'});
            my $url = xml::entities $INPUT{'title'};
            throw 'validation_error', "\"$url\" is a reserved url." if grep(/^$url$/, @reserved_urls);
        };

        # assemble some variables
        my $title = xml::entities($INPUT{'title'});

        # is the user trying to save this?
        if ($has_validated and $INPUT{'save'}) {

            # find a unique url for this page
            my $url = string::urlify($INPUT{'title'});
            $url = "${parent_url}/$url" if $parent_id;
            my $orig_url = $url;
            my $x = 0;
            my $query = $DB->prepare("SELECT COUNT(*) FROM ${module_db_prefix}pages WHERE url_hash = ? LIMIT 1");
            FIND_UNIQUE_URL: while (1) {
                $query->execute(hash::fast $url);
                last FIND_UNIQUE_URL if $query->fetchrow_arrayref->[0] == 0;
                $url = $orig_url . ++$x;
            }

            # insert the page into the database
            my $query = $DB->query("INSERT INTO ${module_db_prefix}pages (parent_id, show_nav_link, title, url, url_hash, ctime, mtime) VALUES (?, ?, ?, ?, ?, NOW(), NOW())", $parent_id, $show_nav_link, $title, $url, hash::fast($url));
            my $page_id = $DB->insert_id("${DB_PREFIX}content_page_id");

            # save fields
            _save_fields($page_id, @fields);

            # confirmation
            confirmation('The page has been created.');

            # reload navigation
            ipc::eval('module::content::_load_nav_links()') if $show_nav_link == 1;

            # display the page
            view_page($url);

            # add admin menu items
            #module::sims::add_admin_menu_item('menu' => 'This Page', 'label' => 'Create a Sub-page', 'url' => "${BASE_URL}content/$url?a=create&amp;parent=$id") if $user::permissions{'content_create'};
            #module::sims::add_admin_menu_item('menu' => 'This Page', 'label' => 'Edit',              'url' => "${BASE_URL}content/$url?a=edit")                  if $user::permissions{'content_edit'};
            #module::sims::add_admin_menu_item('menu' => 'This Page', 'label' => 'Delete',            'url' => "${BASE_URL}content/$url?a=delete")                if $user::permissions{'content_delete'};
        }

        # the user is not trying to submit, only preview, or they tried to submit and their page did not validate
        else {

            # preview
            # TODO: does not obey inside_content_node
            if ($has_validated) {
                print "\t<content mode=\"view\" preview=\"true\" title=\"$title\">\n";
                for my $field (@fields) {
                    print "\t\t<$field->{id}>$field->{translated_value}</$field->{id}>\n";
                }
                print "\t</content>\n";
            }

            # make changes/save form
            style::include_template('create_edit');
            print "\t<content mode=\"create\" parent=\"$parent_id\" has_validated=\"$has_validated\" title=\"$title\" show_nav_link=\"" . ( $show_nav_link ? 'true' : 'false' ) . "\" can_add_files=\"" . ( $user::permissions{'file_add'} ? 'true' : 'false' ) . "\">\n";
            if ($fields_validated) {
                print "\t\t<field type=\"text\" />\n";
            } else {
                my $field = shift(@fields);
                print "\t\t<field name=\"$field->{name}\" type=\"$field->{type}\" translation_mode=\"$field->{translation_mode}\" inside_content_node=\"$field->{inside_content_node}\" />\n";
            }
            _print_fields(@fields);
            print "\t</content>\n";
        }
    }

    # print a blank create page form or ask for a template
    else {
        style::set_template('create_edit');

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
        if ($template_id) {
            print "\t<content mode=\"create\" parent=\"$parent_id\">\n";
            print "\t\t<field type=\"text\" />\n";
            _print_page_fields($template_id);
            print "\t</content>\n";
        }

        # otherwise, ask the user which template to use
        else {
            print "\t<content mode=\"create_select_template\" parent=\"$parent_id\" can_add_files=\"" . ( $user::permissions{'file_add'} ? 'true' : 'false' ) . "\">\n";
            my $query = $DB->query("SELECT id, name FROM ${module_db_prefix}templates");
            while (my $template = $query->fetchrow_hashref()) {
            	print "\t\t<template id=\"$template->{id}\" name=\"$template->{name}\" />\n";
            }
            print "\t</content>\n";
        }
    }
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
        throw 'validation_error', 'Invalid field name.' unless $field->{'name'};
        $field->{'id'} = _get_field_id($field->{'name'});
        throw 'validation_error', 'Invalid field name.  A field name must contain at least one alphanumeric or whitespace character.' unless $field->{'id'};
        throw 'validation_error', "'$field->{name}' is a reserved name." if $field->{'id'} eq 'subpages';

        # validate inside_content_node
        $field->{'inside_content_node'} = $field->{'inside_content_node'} ? 1 : 0;

        # validate field type
        throw 'validation_error', 'Invalid field type.' unless ($field_types{$field->{'type'}});

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

# print field data for editing, expects one argument, @fields (not a ref!)
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

=xml
</document>
=cut

1;

# Copyright BitPiston 2011