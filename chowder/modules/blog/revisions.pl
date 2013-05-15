
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
    
    # Create config table and populate initial settings
    $DB->query(qq~CREATE TABLE `${MODULE_DB_PREFIX}config` (
          `name` tinytext NOT NULL,
          `value` tinytext NOT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8;~);
    $DB->query(qq~INSERT INTO `${MODULE_DB_PREFIX}config` (`name`, `value`)
        VALUES
        	('default_category','1'),
        	('enable_comments_default','0');~);
            
    # Create categories table
    $DB->query(qq~CREATE TABLE `${MODULE_DB_PREFIX}categories` (
          `id` smallint(6) NOT NULL AUTO_INCREMENT,
          `parent_id` smallint(6) NOT NULL DEFAULT '0',
          `name` tinytext NOT NULL,
          `description` tinytext NOT NULL,
          `url` tinytext NOT NULL,
          `show_nav_link` tinyint(1) NOT NULL DEFAULT '0',
          `nav_priority` smallint(6) NOT NULL DEFAULT '0',
          UNIQUE KEY `id` (`id`)
        ) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;~);
                    
    # Create labels table
    $DB->query(qq~CREATE TABLE `${MODULE_DB_PREFIX}labels` (
          `id` smallint(6) NOT NULL AUTO_INCREMENT,
          `name` tinytext NOT NULL,
          UNIQUE KEY `id` (`id`)
        ) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8;~);
    
    # Create posts table
    $DB->query(qq~CREATE TABLE `${MODULE_DB_PREFIX}posts` (
          `id` int(11) NOT NULL AUTO_INCREMENT,
          `published` tinyint(1) NOT NULL DEFAULT '0',
          `title` tinytext NOT NULL,
          `url` tinytext NOT NULL,
          `url_hash` varchar(10) NOT NULL DEFAULT '',
          `ctime` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
          `cdate` date NOT NULL DEFAULT '0000-00-00',
          `author_id` int(11) NOT NULL DEFAULT '0',
          `author_name` varchar(30) NOT NULL DEFAULT '',
          `post_original` text NOT NULL,
          `post` text NOT NULL,
          `more_original` text NOT NULL,
          `more` text NOT NULL,
          `translation_mode` tinytext NOT NULL,
          `comments_node` int(11) NOT NULL DEFAULT '0',
          `comments` smallint(6) NOT NULL DEFAULT '0',
          `enable_comments` tinyint(1) NOT NULL DEFAULT '0',
          `labels` tinytext NOT NULL,
          UNIQUE KEY `id` (`id`),
          KEY `author_id` (`author_id`),
          KEY `published` (`published`),
          KEY `cdate` (`cdate`),
          KEY `url_hash` (`url_hash`)
        ) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;~);

};

1;
