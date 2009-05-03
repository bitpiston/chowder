	<oyster:include href="forums/_pages.xsl" />	
	<xsl:template match="/oyster/forums[@action = 'view_thread']" mode="title"><xsl:value-of select="/oyster/forums//thread[@id = /oyster/forums/@thread_id]/@title" /></xsl:template>
	<xsl:template match="/oyster/forums[@action = 'view_thread']" mode="heading"><a href="{/oyster/@base}forums/thread/{/oyster/forums/@thread_id}/"><xsl:value-of select="/oyster/forums//thread[@id = /oyster/forums/@thread_id]/@title" /></a></xsl:template>
	<xsl:template match="/oyster/forums[@action = 'view_thread']" mode="description" xml:space="preserve">
		<div class="path">Forum: <a href="{/oyster/@base}forums/">Overview</a> 
			<xsl:for-each select="/oyster/forums//forum[@id = /oyster/forums/@forum_id]/ancestor::forum">
				<span>&#8250;</span> <a href="{/oyster/@base}forums/forum/{@id}"><xsl:value-of select="@name" /></a> 
			</xsl:for-each>
			<span>&#8250;</span> <strong><a href="{/oyster/@base}forums/forum/{@forum_id}/"><xsl:value-of select="/oyster/forums//forum[@id = /oyster/forums/@forum_id]/@name" /></a></strong> <a href="{/oyster/@base}forums/rss/" title="RSS feed of all posts"><img src="{/oyster/@styles}{/oyster/@style}/images/feed.png" alt="RSS" /></a></div>
			<div class="desc"><xsl:value-of select="/oyster/forums//forum[@id = /oyster/forums/@forum_id]/@description" /></div>
	</xsl:template>
	<xsl:template match="/oyster/forums[@action = 'view_thread']" mode="content">
		<div class="all_post_actions_top">
			<xsl:if test="/oyster/forums//thread[@id = /oyster/forums/@thread_id]/@pages > 1">
				<span class="page">Page:
					<xsl:call-template name="pages">
						<xsl:with-param name="pages" select="/oyster/forums//thread[@id = /oyster/forums/@thread_id]/@pages" />
						<xsl:with-param name="url"><xsl:value-of select="/oyster/@base" />forums/thread/<xsl:value-of select="@thread_id" />/</xsl:with-param>
						<xsl:with-param name="nav" select="1" />
					</xsl:call-template>
				</span>
			</xsl:if>
			<xsl:choose>
				<xsl:when test="/oyster/forums//thread[@id = /oyster/forums/@thread_id]/@locked = 1">
					<div class="locked">Thread locked</div>
				</xsl:when>
				<xsl:otherwise>
					<div class="add post"><a href="{/oyster/@url}?a=reply">Reply</a></div>
				</xsl:otherwise>
			</xsl:choose>
		</div>
		<div class="all_posts_container">
			<xsl:for-each select="/oyster/forums//thread[@id = /oyster/forums/@thread_id]/post">
				<div id="p{@id}" class="post_container">
					<div class="post">
						<h2 class="number"><a rel="bookmark" href="{/oyster/@base}forums/post/{@id}/" title="Link to this post">#<xsl:value-of select="@number" /></a></h2>
						<div class="date"><xsl:value-of select="@ctime" /></div>
						<!-- post subject? drop it if its equal to the thread title. Default Re: for quick reply/quote and empty for new reply. -->
						<div class="body">
							<xsl:apply-templates select="body/node()" mode="xhtml" />
						</div>
						<xsl:if test="@edit_count != 0 and string-length(@edit_ctime) != 0">
							<div class="edit">
								Edited by <xsl:value-of select="@edit_user" /> at <xsl:value-of select="@edit_ctime" />
								<xsl:if test="string-length(@edit_reason) != 0">
									<br />Reason: <xsl:value-of select="@edit_reason" />
								</xsl:if>
							</div>
						</xsl:if>
						<xsl:if test="signature">
							<div class="signature">
								<xsl:apply-templates select="signature/node()" mode="xhtml" />
							</div>
						</xsl:if>
						<xsl:if test="/oyster/user/@id != 0">
							<ul class="actions"><!-- do me -->
								<xsl:if test="/oyster/forums//thread[@id = /oyster/forums/@thread_id]/@locked != 1">
									<xsl:if test="/oyster/user/permissions/@forums_create_posts = 1">
										<li class="reply"><a href="javascript:replyTo({@id})">Fast reply</a></li>
										<li class="quote"><a href="{/oyster/@url}?a=reply&amp;q={@id}">Quote</a></li>
									</xsl:if>
								</xsl:if>								
								<xsl:if test="@mypost = 1 or /oyster/user/permissions/@forums_edit_posts = 2">
									<li class="edit"><a href="{/oyster/@base}forums/post/{@id}/?a=edit">Edit</a></li>
								</xsl:if>
								<xsl:if test="@mypost = 1 or /oyster/user/permissions/@forums_delete_posts = 2">
									<li class="delete"><a href="{/oyster/@base}forums/post/{@id}/?a=delete">Delete</a></li>
								</xsl:if>
							</ul>
						</xsl:if>
					</div>
					<div class="author">
						<div class="name"><a href="{/oyster/@base}user/{@author_name}/"><xsl:value-of select="@author_name" /></a></div>
						<div class="title"><xsl:value-of select="@author_title" /></div>
						<img class="avatar" src="{@author_avatar}" alt="Avatar" />
						<div class="posts"><a href=""><xsl:value-of select="@author_posts" /></a> posts</div>
						<div class="age"><xsl:value-of select="@author_registered" /></div>
						<div class="location"><xsl:value-of select="@author_location" /></div>
					</div>
				</div>	
				<hr />
			</xsl:for-each>
		</div>
		<div class="all_post_actions_bottom">
			<xsl:if test="/oyster/forums//thread[@id = /oyster/forums/@thread_id]/@pages > 1">
				<span class="page">Page:
					<xsl:call-template name="pages">
						<xsl:with-param name="pages" select="/oyster/forums//thread[@id = /oyster/forums/@thread_id]/@pages" />
						<xsl:with-param name="url"><xsl:value-of select="/oyster/@base" />forums/thread/<xsl:value-of select="@thread_id" />/</xsl:with-param>
						<xsl:with-param name="nav" select="1" />
					</xsl:call-template>
				</span>
			</xsl:if>
			<xsl:choose>
				<xsl:when test="/oyster/forums//thread[@id = /oyster/forums/@thread_id]/@locked = 1">
					<div class="locked">Thread locked</div>
				</xsl:when>
				<xsl:otherwise>
					<div class="add post"><a href="{/oyster/@url}?a=reply">Reply</a></div>
				</xsl:otherwise>
			</xsl:choose>
		</div>
		<xsl:if test="/oyster/user/@id != 0">
			<div class="advanced_options posts">
				<strong>Options for this topic:</strong><br /><!-- do me -->
				<dl>
					<dt><a href="{/oyster/@url}?a=ignore&amp;s=1">Ignore this thread</a> | <a href="{/oyster/@url}?a=hide&amp;s=0">Reset ignore state</a></dt>
					<dd>Do not list this thread in the unread threads search. You are currently not ignoring this thread.</dd>
					<dt><a href="{/oyster/@url}?a=hide&amp;s=1">Hide this thread</a> | <a href="{/oyster/@url}?a=hide&amp;s=0">Reset hide state</a></dt>
					<dd>Hidden threads are not displayed in the threads list. This thread is currently not hidden.</dd>
				</dl>
				<ul>
					<li class="notify"><a href="{/oyster/@url}?a=watch&amp;s=1">Watch thread</a> (e-mail notification)</li>
					<!--
					<li class="bookmark"><a href="">Add bookmark</a> | <a href="">Show all</a></li>
					<xsl:if test="/oyster/user/permissions/@forums_lock = 1">
						<li class="close"><a href="">Lock thread</a></li>
					</xsl:if>
					<xsl:if test="/oyster/user/permissions/@forums_move = 1">
						<li class="move"><a href="{/oyster/@url}?a=move">Move thread</a></li>
					</xsl:if>
					-->				
					<xsl:if test="@mypost = 1 or /oyster/user/permissions/@forums_create_threads = 1">
						<li class="edit"><a href="{/oyster/@url}?a=edit">Edit thread</a></li>
					</xsl:if>
					<xsl:if test="/oyster/user/permissions/@forums_split = 1">
						<li class="split"><a href="{/oyster/@url}?a=split">Split thread</a></li>
					</xsl:if>
					<xsl:if test="/oyster/user/permissions/@forums_delete_threads = 2">
						<li class="delete"><a href="{/oyster/@url}?a=delete">Delete thread</a></li>
					</xsl:if>
				</ul>
			</div>
		</xsl:if>
		<div class="online_forum_data">
			<p><strong>User count</strong> 1 reading this thread: <a href="">username</a></p>
		</div>
	</xsl:template>
	
	