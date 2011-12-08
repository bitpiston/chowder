<xsl:template match="/oyster/blog[@action = 'view_index']" mode="heading">
	News, Annoucements &#0038; Our Thoughts at BitPiston
</xsl:template>

<xsl:template match="/oyster/blog[@action = 'view_index']" mode="content">
	<xsl:if test="count(item) = 0">
		<p>No posts matched your criteria.</p>
	</xsl:if>
	<div class="hfeed frontpage">
		<xsl:for-each select="item">
			<!--
			<xsl:if test="not(substring(preceding-sibling::*/@ctime, 0, 11) = substring(@ctime, 0, 11))">
				<h2>
					<xsl:call-template name="date">
						<xsl:with-param name="time" select="@ctime" />
						<xsl:with-param name="date_format" select="'%B %e, %Y'" />
					</xsl:call-template>
				</h2>
			</xsl:if>
			-->
			<div class="hentry" id="entry-{@id}">
				<h2 class="entry-title"><span><a href="{/oyster/@base}blog/{@url}/" rel="bookmark"><xsl:value-of select="@title" /></a></span></h2>
				<div class="entry-content">
					<xsl:apply-templates select="post/*" mode="xhtml" />
				</div>
				<ul class="details">
					<xsl:variable name="author_id" select="@author" />
					<li class="user">Posted by <address class="vcard author"><a class="url fn" href="/about/#{@author_name}"><xsl:value-of select="@author_name" /></a></address></li>
					<li class="date"><abbr class="published" title="{@ctime}"><xsl:call-template name="date">
						<xsl:with-param name="time" select="@ctime" />
						<xsl:with-param name="date_format" select="'%B %e, %Y'" />
					</xsl:call-template></abbr></li>					
					<!--
					<xsl:if test="../@can_edit = 'all'">
						<li class="admin edit"><a href="{/oyster/@base}blog/admin/edit/{@id}" title="Edit this news item">Edit</a></li>
					</xsl:if>
					<xsl:if test="../@can_edit = 'self' and /oyster/user/@id = $author_id">
						<li class="admin edit"><a href="{/oyster/@base}blog/admin/edit/{@id}" title="Edit this news item">Edit</a></li>
					</xsl:if>
					<xsl:if test="../@can_delete = 'all'">
						<li class="admin delete"><a href="{/oyster/@base}blog/admin/delete/{@id}" title="Delete this news item">Delete</a></li>
					</xsl:if>
					<xsl:if test="../@can_delete = 'self' and /oyster/user/@id = $author_id">
						<li class="admin delete"><a href="{/oyster/@base}blog/admin/delete/{@id}" title="Delete this news item">Delete</a></li>
					</xsl:if>
					<xsl:if test="@more">
						<li class="more"><a href="{/oyster/@base}blog/{@url}/" title="Read more of this news item">Continued</a></li>
					</xsl:if>
					-->
					<li class="comments">
						<xsl:choose>
							<xsl:when test="@comments">
								<a href="{/oyster/@base}blog/{@url}/#comments" title="Read or post comments for this news item">
									<xsl:choose>
										<xsl:when test="@comments = 0">No Comments</xsl:when>
										<xsl:when test="@comments = 1">1 Comment</xsl:when>
										<xsl:otherwise><xsl:value-of select="@comments" /> Comments</xsl:otherwise>
									</xsl:choose>
								</a>
							</xsl:when>
							<xsl:otherwise>Comments Disabled</xsl:otherwise>
						</xsl:choose>
					</li>
				</ul>
			</div>
		</xsl:for-each>
		<div class="offset">
			<xsl:if test="@prev_offset">
				<a href="{/oyster/@url}?offset={@prev_offset}" class="previous">Previous Page (Newer)</a>
			</xsl:if>
			<xsl:if test="@prev_offset and count(item) &gt; 10"> | </xsl:if>
			<xsl:if test="count(item) &gt; 10">
				<a href="{/oyster/@url}?offset={@next_offset}" class="next">Next Page (Older)</a>
			</xsl:if>
		</div>
	</div>
</xsl:template>

<xsl:template match="/oyster/blog[@action = 'view_index']" mode="sidebar">
	<h2><span>Search</span></h2>
	<form id="search" method="get" action="/search/">
		<div>
			<input type="text" id="search-input" name="search-input" accesskey="f" value="Search the weblog" onfocus="if(this.value=='Search the weblog') this.value='';" onblur="if(this.value=='') this.value='Search the weblog';" size="25" />
			<input type="image" src="{/oyster/@styles}{/oyster/@style}/images/icon.search.png" id="search-submit " alt="Search" title="Search" />
		</div>
	</form>
	<h2><span>RSS Feeds</span></h2>
	<p>Stay up to date via a news reader or feed aggregator:</p>
	<ul>
		<li><a class="rss" href="/">Recent Entries</a></li>
		<li><a class="rss" href="/">Recent Comments</a></li>
	</ul>
	<h2><span>Entries by Category</span></h2>
	<ul>
		<li><a href="/blog/documentation/">Documentation</a> <span> (2)</span></li>
		<li><a href="/blog/events/">Events</a> <span> (1)</span></li>
		<li><a href="/blog/releases/">Releases</a> <span> (3)</span></li>
		<li><a href="/blog/resources/">Resources</a> <span> (3)</span></li>
	</ul>
	<h2><span>Entries by Date</span></h2>
	<ul>
		<li><a href="/blog/2007/">2007</a> <span> (6)</span>
			<ul>
				<li><a href="/blog/2007/05/">May</a> <span> (5)</span></li>
				<li><a href="/blog/2007/06/">June</a> <span> (1)</span></li>
			</ul>
		</li>
		<li><a href="/blog/2008/">2008</a> <span> (2)</span>
			<ul>
				<li><a href="/blog/2008/05/">May</a> <span> (1)</span></li>
				<li><a href="/blog/2008/06/">June</a> <span> (1)</span></li>
			</ul>
		</li>
	</ul>
</xsl:template>