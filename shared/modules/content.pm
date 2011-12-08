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
    
    #print oyster::dump(%oyster::REQUEST);
    #print $url_hash;
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
</document>
=cut

1;

# Copyright BitPiston 2011