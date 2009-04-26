	<oyster:include href="forums/_forum.xsl" />
	<oyster:include href="forums/_pages.xsl" />
	
	<xsl:template match="/oyster/forums[@action = 'view_forum']" mode="title"><xsl:value-of select="/oyster/forums//forum[@id = /oyster/forums/@forum_id]/@name" /></xsl:template>
	<xsl:template match="/oyster/forums[@action = 'view_forum']" mode="heading"><a href="{/oyster/@base}forums/forum/{/oyster/forums/@forum_id}/"><xsl:value-of select="/oyster/forums//forum[@id = /oyster/forums/@forum_id]/@name" /></a></xsl:template>
	<xsl:template match="/oyster/forums[@action = 'view_forum']" mode="description" xml:space="preserve">
		<div class="path">Forum: <a href="{/oyster/@base}forums/">Overview</a> 
			<xsl:for-each select="/oyster/forums//forum[@id = /oyster/forums/@forum_id]/ancestor::forum">
				<span>&#8250;</span> <a href="{/oyster/@base}forums/forum/{@id}"><xsl:value-of select="@name" /></a> 
			</xsl:for-each>
			<span>&#8250;</span> <strong><a href="{/oyster/@base}forums/forum/{@forum_id}/"><xsl:value-of select="/oyster/forums//forum[@id = /oyster/forums/@forum_id]/@name" /></a></strong> <a href="{/oyster/@base}forums/rss/" title="RSS feed of all posts"><img src="{/oyster/@styles}{/oyster/@style}/images/feed.png" alt="RSS" /></a></div>
			<div class="desc"><xsl:value-of select="/oyster/forums//forum[@id = /oyster/forums/@forum_id]/@description" /></div>
	</xsl:template>

	<xsl:template match="/oyster/forums[@action = 'view_forum']" mode="content">
		
		
		<xsl:if test="/oyster/forums//forum[@id = /oyster/forums/@forum_id]/forum">
			<h2>Subforums</h2>
			<div class="all_forums_container">
				<xsl:for-each select="/oyster/forums//forum[@id = /oyster/forums/@forum_id]/forum">
					<div class="forum_container">
					 	<xsl:call-template name="forum">
							<xsl:with-param name="depth" select="2" />
						</xsl:call-template>
					</div>
					<hr />
				</xsl:for-each>
			</div>
		</xsl:if>
		
		
		<xsl:if test="count(/oyster/forums//forum[@id = /oyster/forums/@forum_id]/thread)">
			<xsl:if test="/oyster/forums//forum[@id = /oyster/forums/@forum_id]/forum"><h2 class="topics">Topics</h2></xsl:if>
			<div class="all_thread_actions_top">
				<xsl:if test="/oyster/user/permissions/@forums_create_threads = 1">
					<span class="add thread"><a href="{/oyster/@url}?a=create">New thread</a></span>
				</xsl:if>
				<xsl:if test="/oyster/forums//forum[@id = /oyster/forums/@forum_id]/@pages > 1">
					<span class="page">Page:
						<xsl:call-template name="pages">
							<xsl:with-param name="pages" select="/oyster/forums//forum[@id = /oyster/forums/@forum_id]/@pages" />
							<xsl:with-param name="url"><xsl:value-of select="/oyster/@base" />forums/forum/<xsl:value-of select="@forum_id" />/</xsl:with-param>
							<xsl:with-param name="nav" select="1" />
						</xsl:call-template>
					</span>
				</xsl:if>				
			</div>
			<div class="all_threads_container">
				<xsl:for-each select="/oyster/forums//forum[@id = /oyster/forums/@forum_id]/thread">
					<div class="thread_container">			
						<div class="thread_icon">
							<!-- do me -->
							<a href="thread/2"><img src="{/oyster/@styles}{/oyster/@style}/images/thread.png" alt="" title="Important thread (Own posts)" /></a>
						</div>
						<div class="thread_header">
							<h3 xml:space="preserve"><a href="{/oyster/@base}forums/thread/{@id}/"><xsl:value-of select="@title" /></a> <xsl:if test="@sticky = 1"><em>(Important)</em></xsl:if></h3>			
							<xsl:if test="@pages > 1">
								<span class="page"><small>Page:</small> 
									<xsl:call-template name="pages">
										<xsl:with-param name="pages" select="@pages" />
										<xsl:with-param name="url"><xsl:value-of select="/oyster/@base" />forums/thread/<xsl:value-of select="@id" />/</xsl:with-param>
									</xsl:call-template>
								</span>
							</xsl:if>
						</div>
						<div class="thread_data">
							<!-- Edit/Delete/Move icons behind post title? 
							<xsl:if test="(/oyster/user/permissions/@forums_edit_posts = 1 and @mine = 1) or /oyster/user/permissions/@forums_edit_posts = 2">
								<span class="admin edit"><a href="{/oyster/@base}forums/thread/{@id}/?a=edit" class="admin">Edit thread</a></span>
							</xsl:if>
							-->
							<ul>
								<li class="viewcount"><xsl:value-of select="@views" /> views</li>
								<li class="replycount"><xsl:value-of select="@replies" /> replies</li>

								<li class="topicstart">Topic started by <a href="{/oyster/@base}user/{@author_name}/"><xsl:value-of select="@author_name" /></a></li>
								<li class="lastpost">Last post <a href="{/oyster/@base}forums/post/{@last_id}/"><xsl:value-of select="@last_date" /> ago</a> by <a href="{/oyster/@base}user/{@last_author}/"><xsl:value-of select="@last_author" /></a></li>
							</ul>				
						</div>
					</div>
					<hr />
				</xsl:for-each>
			</div>
			<div class="all_thread_actions_bottom">
				<xsl:if test="/oyster/forums//forum[@id = /oyster/forums/@forum_id]/@pages > 1">
					<span class="page">Page: 
						<xsl:call-template name="pages">
							<xsl:with-param name="pages" select="/oyster/forums//forum[@id = /oyster/forums/@forum_id]/@pages" />
							<xsl:with-param name="url"><xsl:value-of select="/oyster/@base" />forums/forum/<xsl:value-of select="@forum_id" />/</xsl:with-param>
							<xsl:with-param name="nav" select="1" />
						</xsl:call-template>
					</span>
				</xsl:if>
				<xsl:if test="/oyster/user/permissions/@forums_create_threads = 1">
					<span class="add thread"><a href="{/oyster/@url}?a=create">New thread</a></span>
				</xsl:if>
			</div>
		</xsl:if>
		<div class="online_forum_data">
			<p><strong>User count</strong> user browsing this forum: <a href="">user</a></p>
		</div>
		<ul class="icons_legend">
			<li><img src="{/oyster/@styles}{/oyster/@style}/images/thread.png" alt="" /> Thread</li>
			<li><img src="{/oyster/@styles}{/oyster/@style}/images/thread_new_hot.png" alt="" /> Popular thread</li>
			<li><img src="{/oyster/@styles}{/oyster/@style}/images/thread_new_important.png" alt="" /> Important thread</li>
			<li><img src="{/oyster/@styles}{/oyster/@style}/images/thread_own.png" alt="" /> Own posts</li>
		</ul>
	</xsl:template>
