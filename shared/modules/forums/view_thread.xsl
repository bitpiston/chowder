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
			<span class="add post"><a href="">Reply</a></span>
		</div>
		<div class="all_posts_container">
			<xsl:for-each select="/oyster/forums//thread[@id = /oyster/forums/@thread_id]/post">
				<div id="p{@id}" class="post_container">
					<div class="post">
						<h2 class="number"><a rel="bookmark" href="{/oyster/@base}forums/post/{@id}/" title="Link to this post">#<xsl:value-of select="@number" /></a></h2>
						<div class="date"><xsl:value-of select="@ctime" /></div>
						<div class="body">
							<xsl:apply-templates select="body/node()" mode="xhtml" />
						</div>
						<xsl:if test="signature">
							<div class="signature">
								<xsl:apply-templates select="signature/node()" mode="xhtml" />
							</div>
						</xsl:if>
						<ul class="actions"><!-- do me -->
							<li class="reply"><a href="javascript:replyTo({@id})">Fast reply</a></li>
							<li class="quote"><a href="forum.php?req=post&amp;thread=744&amp;quote=11099">Quote</a></li>
							<li class="edit"><a href="forum.php?req=post&amp;id=11099&amp;page=2">Edit</a></li>
							<li class="delete"><a href="javascript:UnbGoDelete(&quot;forum.php?req=post&amp;id=11099&amp;page=2&amp;delete=yes&amp;key=AD1A7B18&quot;)">Delete</a></li>
						</ul>
					</div>
					<div class="author">
						<div class="name"><a href="{/oyster/@base}user/{/oyster/forums//post/@author_name}"><xsl:value-of select="@author_name" /></a></div>
						<div class="title"><xsl:value-of select="@author_title" />Administrator</div>
						<img class="avatar" src="http://janpingel.com/misc/forums/avatars/random/avatar.jpeg" alt="Avatar" /><!-- do me -->
						<div class="posts"><a href="search;nodef=1;Query=49;ResultView=2;InUser=1;Sort=2">39</a> posts</div><!-- do me -->
						<div class="age">Jul 2006</div><!-- do me -->
						<div class="location">Canada</div><!-- do me -->
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
			<span class="add post"><a href="">Reply</a></span>
		</div>
		<div class="online_forum_data">
			<p><strong>User count</strong> 1 reading this thread: <a href="">username</a></p>
		</div>
	</xsl:template>
	
	