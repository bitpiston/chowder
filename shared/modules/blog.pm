=xml
<document title="Blog Module">
    <synopsis>
        Publishes blog posts and supports comments. 
    </synopsis>
    <warning>
        Work in progress.
    </warning>
=cut

package blog;

# import libraries
use oyster 'module';
use exceptions;

# import modules
use user;
#use comments;

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

    # prepare queries
    our $query_fetch_post = $DB->prepare("SELECT id, title, url, ctime, author_id, author_name, post, more, enable_comments, comments, comments_node, published, labels FROM ${module_db_prefix}posts WHERE cdate = ? and url_hash = ? LIMIT 1");

    # reserved urls
    #our @reserved_urls = ('submit', 'admin');

    # load and cache categories
    #our (%categories, %categories_by_parent_id, %categories_by_url, @navigation);
    #module::sims::categories::load('news', 'where_table' => 'posts');

    # load and save labels
    #our %labels;
    #module::sims::labels::load('news');
}

=xml
    <function name="view_index">
        <synopsis>
            Retrieve and print the index of latest posts.
        </synopsis>
    </function>
=cut

sub view_index {
    my $url = shift;
    my ($extra_attrs, $where);

    # archive (note: if a match occures, this REMOVES the date portion from $url so that it can be identified as a category)
    my ($year, $month, $day);
    if ($url =~ m!^(\d{4})/(\d{2})/(\d{2})(?:/(.+))?$!) { # view by day
        ($year, $month, $day, $url) = ($1, $2, $3, $4);
        $where .= " and cdate = '${year}-${month}-${day}'";
        $extra_attrs .= " archive=\"true\" year=\"$year\" month=\"$month\" day=\"$day\"";
    } elsif ($url =~ m!^(\d{4})/(\d{2})(?:/(.+))?$!) {    # view by month
        ($year, $month, $url) = ($1, $2, $3);
        my $days_in_month = datetime::days_in_month($year, $month);
        $where .= " and cdate BETWEEN '${year}-${month}-01' AND '${year}-${month}-${days_in_month}'";
        $extra_attrs .= " archive=\"true\" year=\"$year\" month=\"$month\"";
    } elsif ($url =~ m!^(\d{4})(?:/(.+))?$!) {            # view by year
        ($year, $url) = ($1, $2);
        $where .= " and cdate BETWEEN '${year}-01-01' AND '${year}-12-31'";
        $extra_attrs .= " archive=\"true\" year=\"$year\"";
    }
    
    # view a particular category
    my ($cat_id, $cat);
    $cat_id = $categories_by_url{$url} ? $categories_by_url{$url} : $CONFIG{'default_category'} ;
    $cat = $categories{$cat_id};
    $where .= $cat->{'where'} ? " and $cat->{where}" : '' ;
    $extra_attrs .= " cat_id=\"$cat_id\" category=\"$cat->{name}\" description=\"$cat->{description}\"";
    $REQUEST{'news_view_category'} = $cat_id;

    # figure limit sql and next/prev links
    my ($num_posts, $limit_sql, $offset);
    $num_posts = 10;
    $limit_sql = $num_posts;
    if ($INPUT{'offset'} and $INPUT{'offset'} !~ /[^0-9]/) {
       $offset = $INPUT{'offset'};
       $limit_sql = "$offset, $num_posts";
    } else {
       $offset = 0;
    }
    $extra_attrs .= ' prev_offset="' . ($offset - $num_posts) . '"' if $offset > 0;
    $extra_attrs .= ' next_offset="' . ($offset + $num_posts) . '"';

    # display the selected news posts
    style::include_template('view_index');
    print "\t<blog action=\"view_index\"$extra_attrs>\n";
    #module::sims::categories::print_categories_lite('news');
    #module::sims::labels::print_labels('news');
    my $query = $DB->prepare("SELECT id, title, url, ctime, author_id, author_name, post, LENGTH(more), enable_comments, comments, labels FROM ${module_db_prefix}posts WHERE published = '1'$where ORDER BY id DESC LIMIT $limit_sql");
    $query->execute();
    while (my $post = $query->fetchrow_arrayref()) {
       my ($id, $title, $url, $ctime, $author_id, $author_name, $snippet, $more_len, $enable_comments, $comments, $labels) = @{$post};
       my ($year, $month, $day) = ($ctime =~ /^(\d{4})-(\d{2})-(\d{2})/);
       my $item_attrs;
       $item_attrs .= " enable_comments=\"$enable_comments\" comments=\"$comments\"" if $enable_comments;
       $item_attrs .= ' more="true"' if $more_len;
       print "\t\t<item id=\"$id\" title=\"$title\" url=\"$year/$month/$day/$url\" ctime=\"$ctime\" author_id=\"$author_id\" author_name=\"$author_name\"$item_attrs>\n";
       print "\t\t\t<labels>\n";
       my @labels = split(/,/, $labels);
       for my $label_id (@labels) {
           print "\t\t\t\t<label id=\"$label_id\" />\n";
       }
       print "\t\t\t</labels>\n";
       print "\t\t\t<post>$snippet</post>\n";
       print "\t\t</item>\n";
    }
    print "\t</blog>\n";
    
    #print oyster::dump(%oyster::REQUEST);
    #print $url_hash;
}

=xml
    <function name="view_post">
        <synopsis>
            Retrieve and print the post and comments.
        </synopsis>
    </function>
=cut

sub view_post {
    my ($year, $month, $day, $post_url) = @_;

    # fetch and validate the post
    $query_fetch_post->execute("$year-$month-$day", hash::fast($post_url));
    throw 'request_404' unless $query_fetch_post->rows();
    my $post = $query_fetch_post->fetchrow_arrayref();

    # query string actions
    #if ($INPUT{'a'} eq 'edit') {
    #    edit($post->[0]);
    #    return;
    #} elsif ($INPUT{'a'} eq 'delete') {
    #    admin_delete($post->[0]);
    #    return;
    #}

    # display the post
    #style::include_template('view_post');
    my ($id, $title, $url, $ctime, $author_id, $author_name, $post, $more, $enable_comments, $comments, $comments_node, $published, $labels) = @{$post};
    #permission_error unless ($published or $user::permissions{'news_admin_publish'});
    #user::print_module_permissions('weblog');
    #user::require_permission('weblog_view');
    print "\t<blog action=\"view_post\">\n";
    #module::sims::categories::print_categories_lite('news');
    #module::sims::labels::print_labels('news');
    my $item_attrs;
    $item_attrs .= " enable_comments=\"$enable_comments\" comments=\"$comments\"" if $enable_comments;
    print "\t\t<item title=\"$title\" url=\"$year/$month/$day/$url\" ctime=\"$ctime\" author_id=\"$author_id\" author_name=\"$author_name\"$item_attrs>\n";
    print "\t\t\t<labels>\n";
    my @labels = split(/,/, $labels);
    for my $label_id (@labels) {
        print "\t\t\t\t<label id=\"$label_id\" />\n";
    }
    print "\t\t\t</labels>\n";
    print "\t\t\t<post>$post</post>\n";
    print "\t\t\t<more>$more</more>\n" if $more;
    print "\t\t</item>\n";
    #module::comments::node_print($comments_node, 'posts', $id) if $enable_comments;
    print "\t</blog>\n";

    #print oyster::dump(%oyster::REQUEST);
    #print $url_hash;
}

=xml
</document>
=cut

1;

# Copyright BitPiston 2011