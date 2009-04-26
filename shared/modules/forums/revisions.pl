package forums::revisions;

$revision[1]{'up'}{'shared'} = sub {
    
    # Register module
    module::register('forums');
};

$revision[1]{'up'}{'site'} = sub {
    
    # Enable module
    module::enable('forums');
    
    # Create config table and populate initial settings
    $DB->query(qq~CREATE TABLE IF NOT EXISTS `${MODULE_DB_PREFIX}config` ( `name` tinytext NOT NULL, `value` tinytext NOT NULL ) ENGINE=MyISAM DEFAULT CHARSET=latin1~);
    $DB->query(qq~INSERT INTO `${MODULE_DB_PREFIX}config` (`name`, `value`) VALUES
        ('show_online_users', '1'),
        ('threads_per_page', '30'),
        ('posts_per_page', '15'),
        ('hot_posts_threshold', '50'),
        ('hot_views_threshold', '500'),
        ('max_post_length', '10000'),
        ('min_subject_length', '3'),
        ('max_subject_length', '100'),
        ('read_only', '0')~);

    # Create default forum table
    $DB->query(qq~CREATE TABLE IF NOT EXISTS `${DB_PREFIX}forums` (
        `id` int(11) NOT NULL auto_increment,
        `name` text NOT NULL,
        `parent_id` int(11) NOT NULL,
        `description` text NOT NULL,
        UNIQUE KEY `id` (`id`)
        ) ENGINE=MyISAM  DEFAULT CHARSET=latin1~);
    $DB->query(qq~INSERT INTO `${DB_PREFIX}forums` (`id`, `name`, `parent_id`, `description`) VALUES
        (1, 'Placeholder forum', 0, 'The placeholder forum.')~);
    
    # Create default thread table
    $DB->query(qq~CREATE TABLE IF NOT EXISTS `${MODULE_DB_PREFIX}threads` (
        `id` int(11) NOT NULL auto_increment,
        `title` text NOT NULL,
        `forum_id` int(11) NOT NULL,
        `author_id` int(11) NOT NULL,
        `author_name` varchar(32) NOT NULL,
        `date` int(11) NOT NULL,
        `lastpost_date` int(11) NOT NULL,
        `lastpost_user` varchar(32) NOT NULL,
        `views` int(11) NOT NULL,
        `replies` int(11) NOT NULL,
        `sticky` tinyint(1) NOT NULL DEFAULT '0',
        PRIMARY KEY  (`id`)
        ) ENGINE=MyISAM  DEFAULT CHARSET=latin1~);
    $DB->query(qq~INSERT INTO `${MODULE_DB_PREFIX}threads` (`id`, `title`, `forum_id`, `author_id`, `author_name`, `date`, `lastpost_date`, `lastpost_user`, `views`, `replies`) VALUES
        (1, 'Frist psot!', 1, 1, 'test', 1152166974, 1154203367, 'test', 0, 0, 0)~);
    
    # Create default posts table
    $DB->query(qq~CREATE TABLE IF NOT EXISTS `${MODULE_DB_PREFIX}posts` (
        `id` int(11) NOT NULL auto_increment,
        `title` text NOT NULL,
        `thread_id` int(11) NOT NULL,
        `author_id` int(11) NOT NULL,
        `author_name` varchar(32) NOT NULL,
        `body` longtext NOT NULL,
        `date` int(11) NOT NULL,
        `edit_user` varchar(32) NOT NULL,
        `edit_reason` text NOT NULL,
        `edit_date` int(11) NOT NULL,
        `edit_count` int(11) NOT NULL,
        `replyto` int(11) NOT NULL,
        PRIMARY KEY  (`id`)
        ) ENGINE=MyISAM  DEFAULT CHARSET=latin1~);
    $DB->query(qq~INSERT INTO `${MODULE_DB_PREFIX}posts` (`id`, `title`, `thread_id`, `author_id`, `author_name`, `body`, `date`, `edit_user`, `edit_reason`, `edit_date`, `edit_count`, `replyto`) VALUES
        (1, 'Frist psot!!!!!', 1, 1, 'test', 'Hello world', 1152166974, '', '', '', 0, 0)~);
    
    # Add the forum permissions
    user::add_permission('forums_admin');
    user::add_permission('forums_admin_config');
    user::add_permission('forums_view');
    user::add_permission('forums_create_forums');
    user::add_permission('forums_edit_forums');
    user::add_permission('forums_delete_forums');
    user::add_permission('forums_create_threads');
    user::add_permission('forums_delete_threads');
    user::add_permission('forums_create_posts');
    user::add_permission('forums_edit_posts');
    user::add_permission('forums_delete_posts');
    user::add_permission('forums_move');
    user::add_permission('forums_merge');
    user::add_permission('forums_split');
    user::add_permission('forums_sticky');
    user::add_permission('forums_lock');
    
    # Register URLs
    url::register('url' => 'forums',                'module' => 'forums', 'function' => 'view_index',    'title' => 'Forums', 'show_nav_link' => 1);
    url::register('url' => 'forums/forum/(\d+)',    'module' => 'forums', 'function' => 'view_forum',    'regex' => 1);
    url::register('url' => 'forums/thread/(\d+)',   'module' => 'forums', 'function' => 'view_thread',   'regex' => 1);
    url::register('url' => 'forums/post/(\d+)',     'module' => 'forums', 'function' => 'view_post',     'regex' => 1);
    url::register('url' => 'admin/forums',          'module' => 'forums', 'function' => 'admin',         'title' => 'Forum Administration');
    url::register('url' => 'admin/forums/config',   'module' => 'forums', 'function' => 'admin_config',  'title' => 'Edit Forum Configration');
};

1;
