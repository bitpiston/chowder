
package blog::revisions;

# ----------------------------------------------------------------------------
# Revision 1
# ----------------------------------------------------------------------------

$revision[1]{'up'}{'shared'} = sub {

    # Register the module
    module::register('blog');

    # Add permissions
    user::add_permission('blog_submit');
    user::add_permission('blog_delete');
    user::add_permission('blog_edit');
    user::add_permission('blog_admin');
    user::add_permission('blog_admin_categories');
    user::add_permission('blog_admin_publish');
    user::add_permission('blog_admin_labels');
    user::add_permission('blog_admin_config');

};

$revision[1]{'up'}{'site'} = sub {

    # Enable the module
    module::enable('blog');

};

1;
