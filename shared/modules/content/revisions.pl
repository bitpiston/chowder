
package content::revisions;

# ----------------------------------------------------------------------------
# Revision 1
# ----------------------------------------------------------------------------

$revision[1]{'up'}{'shared'} = sub {

    # Register the module
    module::register('content');

    # Add permissions
    user::add_permission('content_create');
    user::add_permission('content_edit');
    user::add_permission('content_delete');
    user::add_permission('content_admin');
    user::add_permission('content_admin_config');
};

$revision[1]{'up'}{'site'} = sub {

    # Enable the module
    module::enable('content');

};

1;
