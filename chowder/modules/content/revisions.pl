
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
    user::add_permission('content_templates');
    user::add_permission('content_revisions');
};

$revision[1]{'up'}{'site'} = sub {

    # Enable the module
    module::enable('content');
    
    # Admin urls
    url::register('url' => 'admin/content',                'module' => 'content', 'function' => 'admin',                   'title' => 'Content Administration');
    url::register('url' => 'admin/content/templates',      'module' => 'content', 'function' => 'admin_templates',         'title' => 'Manage Content Templates');
    url::register('url' => 'admin/content/templates/edit', 'module' => 'content', 'function' => 'admin_edit_template',     'title' => 'Edit Content Templates');
    url::register('url' => 'admin/content/config',         'module' => 'content', 'function' => 'admin_config',            'title' => 'Content Configuration');
    url::register('url' => 'admin/content/create',         'module' => 'content', 'function' => 'create_page',             'title' => 'Create a Content Page');
    
};

1;
