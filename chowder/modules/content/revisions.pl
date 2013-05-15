
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
    
    # Create config table and populate initial settings
    $DB->query(qq~CREATE TABLE `${MODULE_DB_PREFIX}config` (
          `name` tinytext NOT NULL,
          `value` tinytext NOT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8;~);
    $DB->query(qq~INSERT INTO `${MODULE_DB_PREFIX}config` (`name`, `value`)
        VALUES
        	('subpage_depth','1'),
        	('num_revisions','30');~);
            
    # Create page field history table for revisions
    $DB->query(qq~CREATE TABLE `${MODULE_DB_PREFIX}page_field_history` (
          `revision_id` bigint(20) NOT NULL DEFAULT '0',
          `page_id` tinytext NOT NULL,
          `data` tinytext NOT NULL,
          `name` tinytext NOT NULL,
          `type` tinytext NOT NULL,
          `translation_mode` tinytext NOT NULL,
          `value` text NOT NULL,
          `translated_value` text NOT NULL,
          `call_data` text NOT NULL,
          `inside_content_node` tinyint(1) NOT NULL DEFAULT '0',
          KEY `revision_id` (`revision_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8;~);
    
    # Create page fields table 
    $DB->query(qq~CREATE TABLE `${MODULE_DB_PREFIX}page_fields` (
          `page_id` int(11) NOT NULL DEFAULT '0',
          `data` text NOT NULL,
          `name` tinytext NOT NULL,
          `type` tinytext NOT NULL,
          `translation_mode` tinytext NOT NULL,
          `value` text NOT NULL,
          `translated_value` text NOT NULL,
          `call_data` text NOT NULL,
          `inside_content_node` tinyint(1) NOT NULL DEFAULT '1',
          KEY `page_id` (`page_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8;~);
    
    # Create page revisions table 
    $DB->query(qq~CREATE TABLE `${MODULE_DB_PREFIX}page_revisions` (
          `id` bigint(20) NOT NULL AUTO_INCREMENT,
          `page_id` int(11) NOT NULL DEFAULT '0',
          `mtime` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
          `title` tinytext NOT NULL,
          `author_id` int(11) NOT NULL DEFAULT '0',
          `author_name` varchar(30) NOT NULL DEFAULT '',
          UNIQUE KEY `id` (`id`),
          KEY `page_id` (`page_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8;~);
    
    # Create pages table 
    $DB->query(qq~CREATE TABLE `${MODULE_DB_PREFIX}pages` (
          `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
          `parent_id` int(11) unsigned NOT NULL DEFAULT '0',
          `title` tinytext NOT NULL,
          `ctime` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
          `mtime` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
          `author_id` int(11) unsigned NOT NULL DEFAULT '0',
          `url_hash` varchar(10) NOT NULL DEFAULT '',
          `nav_title` tinytext NOT NULL,
          `slug` tinytext NOT NULL,
          UNIQUE KEY `id` (`id`),
          KEY `parent_id` (`parent_id`,`url_hash`),
          KEY `url_hash` (`url_hash`)
        ) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;~);
    
    # Create pages table 
    $DB->query(qq~CREATE TABLE `${MODULE_DB_PREFIX}templates` (
          `id` tinyint(4) NOT NULL DEFAULT '0',
          `name` tinytext NOT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8;~);
    
};

1;
