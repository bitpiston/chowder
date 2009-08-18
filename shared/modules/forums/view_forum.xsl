	<oyster:include href="forums/_forum.xsl" />
	<oyster:include href="forums/_pages.xsl" />
	<oyster:include href="forums/_split.xsl" />
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
			<ul class="icons_legend">
				<li><img src="{/oyster/@styles}{/oyster/@style}/images/forums_new.png" alt="" /> New posts</li>		
			</ul>
		</xsl:if>
		<xsl:if test="count(/oyster/forums//forum[@id = /oyster/forums/@forum_id]/thread)">
			<xsl:if test="/oyster/forums//forum[@id = /oyster/forums/@forum_id]/forum"><h2 class="topics">Topics</h2></xsl:if>
			<div class="all_thread_actions_top">
				<xsl:if test="/oyster/forums//forum[@id = /oyster/forums/@forum_id]/@pages > 1">
					<span class="page">Page:
						<xsl:call-template name="pages">
							<xsl:with-param name="pages" select="/oyster/forums//forum[@id = /oyster/forums/@forum_id]/@pages" />
							<xsl:with-param name="url"><xsl:value-of select="/oyster/@base" />forums/forum/<xsl:value-of select="@forum_id" />/</xsl:with-param>
							<xsl:with-param name="nav" select="1" />
						</xsl:call-template>
					</span>
				</xsl:if>
				<div class="add thread"><a href="{/oyster/@url}?a=create">New topic</a></div>
			</div>
			<div class="all_threads_container">
				<xsl:for-each select="/oyster/forums//forum[@id = /oyster/forums/@forum_id]/thread">
					<div class="thread_container">		
						<div class="thread_header">
							<xsl:if test="@moved = 1">
								<xsl:attribute name="class">thread_header moved</xsl:attribute>
							</xsl:if>
							<xsl:variable name="url">
								<xsl:if test="@myposts = 1">_mine</xsl:if>
								<xsl:if test="@moved = 1">_move</xsl:if>
								<xsl:if test="not(@moved)">
									<xsl:if test="@locked != 1 and @sticky != 1">
										<xsl:if test="@hot = 1">_hot</xsl:if>
									</xsl:if>
									<xsl:if test="@locked = 1">_lock</xsl:if>
									<xsl:if test="@sticky = 1 and @locked != 1">_sticky</xsl:if>
									<xsl:if test="@new = 1 and @locked != 1">_new</xsl:if><!-- do me -->
								</xsl:if>
							</xsl:variable>
							<h3 xml:space="preserve"><xsl:if test="@moved = 1"><strong>Moved: </strong></xsl:if><a href="{/oyster/@base}forums/thread/{@id}/"><span class="icon"><img src="{/oyster/@styles}{/oyster/@style}/images/thread{$url}.png" alt="" /> </span><xsl:value-of select="@title" /></a> <xsl:if test="@sticky = 1"><em>(Important)</em></xsl:if> <xsl:if test="@locked = 1"><em>(Locked)</em></xsl:if></h3>		
							<xsl:if test="@moved = 1"><div class="forum">Forum: <a href="{/oyster/@base}forums/forum/{@moved_from_id}/"><xsl:value-of select="@moved_from_name" /></a></div></xsl:if>	
							<xsl:if test="@pages > 1 and not(@moved)">
								<span class="page"><small>Page:</small> 
									<xsl:call-template name="pages">
										<xsl:with-param name="pages" select="@pages" />
										<xsl:with-param name="url"><xsl:value-of select="/oyster/@base" />forums/thread/<xsl:value-of select="@id" />/</xsl:with-param>
									</xsl:call-template>
								</span>
							</xsl:if>
						</div>
						<xsl:if test="not(@moved)">
							<div class="thread_data">
								<!-- Edit/Delete/Move icons behind post title? 
								<xsl:if test="(/oyster/user/permissions/@forums_edit_posts = 1 and @mythread = 1) or /oyster/user/permissions/@forums_edit_posts = 2">
									<span class="admin edit"><a href="{/oyster/@base}forums/thread/{@id}/?a=edit" class="admin">Edit thread</a></span>
								</xsl:if>
								-->
								<ul>
									<li class="viewcount"><xsl:value-of select="@views" /> views</li>
									<li class="replycount"><xsl:value-of select="@replies" /> replies</li>

									<li class="topicstart">Thread started by <a href="{/oyster/@base}user/{@author_name}/"><xsl:value-of select="@author_name" /></a></li>
									<xsl:choose>
										<xsl:when test="@replies != 0">
											<li class="lastpost">Last post <a href="{/oyster/@base}forums/post/{@last_id}/"><xsl:value-of select="@last_date" /> ago</a> by <a href="{/oyster/@base}user/{@last_author}/"><xsl:value-of select="@last_author" /></a></li>
										</xsl:when>
										<xsl:otherwise>
											<li class="lastpost">Posted <xsl:value-of select="@last_date" /> ago</li>
										</xsl:otherwise>
									</xsl:choose>
								</ul>				
							</div>
						</xsl:if>
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
				<div class="add thread"><a href="{/oyster/@url}?a=create">New topic</a></div>
			</div>
		</xsl:if>
		<xsl:if test="activity-current">
			<div class="online_forum_data">
				<p>
					<strong><xsl:value-of select="activity-current/@users" /></strong> user<xsl:choose>
						<xsl:when test="activity-current/@users != 1">s are</xsl:when>
						<xsl:otherwise> is</xsl:otherwise>
					</xsl:choose> browsing this forum<xsl:if test="activity-current/@users != 0">: </xsl:if>  
					<xsl:call-template name="split">
						<xsl:with-param name="to-be-split" select="activity-current/@usernames" />
						<xsl:with-param name="delimiter" select="','" />
					</xsl:call-template>
					<xsl:if test="activity-current/@guests != 0">
						 and <strong><xsl:value-of select="activity-current/@guests" /></strong> guest<xsl:if test="activity-current/@guests != 1">s</xsl:if>.
					</xsl:if>
				</p>
			</div>
		</xsl:if>
		<ul class="icons_legend">
			<li><img src="{/oyster/@styles}{/oyster/@style}/images/thread_new.png" alt="" /> New posts</li>
			<li><img src="{/oyster/@styles}{/oyster/@style}/images/thread_mine.png" alt="" /> My posts</li>
			<li><img src="{/oyster/@styles}{/oyster/@style}/images/thread_hot.png" alt="" /> Popular topic</li>
			<li><img src="{/oyster/@styles}{/oyster/@style}/images/thread_sticky.png" alt="" /> Important topic</li>
			<li><img src="{/oyster/@styles}{/oyster/@style}/images/thread_lock.png" alt="" /> Locked topic</li>		
		</ul>
	</xsl:template>
