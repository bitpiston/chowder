	<oyster:include href="forums/_forum.xsl" />
	<oyster:include href="forums/_split.xsl" />
	<xsl:template match="/oyster/forums[@action = 'view_index']" mode="heading">Forum Overview</xsl:template>
	<xsl:template match="/oyster/forums[@action = 'view_index']" mode="description" xml:space="preserve">
		<div class="path">Forum: <strong><a href="{/oyster/@base}forums/">Overview</a></strong> <a href="{/oyster/@base}/forums/rss/" title="RSS feed of all posts"><img src="{/oyster/@styles}{/oyster/@style}/images/feed.png" alt="RSS" /></a></div>
	</xsl:template>
	<xsl:template match="/oyster/forums[@action = 'view_index']" mode="content">
		<xsl:if test="count(forum)">
			<div class="all_forums_container">
				<xsl:for-each select="forum">
					<div class="forum_container">
					 	<xsl:call-template name="forum">
							<xsl:with-param name="depth" select="1" />
						</xsl:call-template>
						<xsl:if test="count(forum)">
							<div class="forum_category_wrapper">
								<xsl:for-each select="forum">
									<div class="forum_container">
										<xsl:call-template name="forum">
											<xsl:with-param name="depth" select="2" />
										</xsl:call-template>
									</div>
								</xsl:for-each>
							</div>
						</xsl:if>
					</div>
				</xsl:for-each>
			</div>
		</xsl:if>
		<div class="online_forum_data">
			<p>
				Currently, <strong><xsl:value-of select="activity-current/@users" /></strong> user<xsl:choose>
					<xsl:when test="activity-current/@users != 1">s are</xsl:when>
					<xsl:otherwise> is</xsl:otherwise>
				</xsl:choose> online<xsl:if test="activity-current/@users != 0">: </xsl:if> 
				<xsl:call-template name="split">
					<xsl:with-param name="to-be-split" select="activity-current/@usernames" />
					<xsl:with-param name="delimiter" select="','" />
				</xsl:call-template>
				<xsl:if test="activity-current/@guests != 0">
					 and <strong><xsl:value-of select="activity-current/@guests" /></strong> guest<xsl:if test="activity-current/@guests != 1">s</xsl:if>.
				</xsl:if>
				<br />
				Today, <strong><xsl:value-of select="activity-todays/@users" /></strong> user<xsl:choose>
					<xsl:when test="activity-todays/@users != 1">s were</xsl:when>
					<xsl:otherwise> was</xsl:otherwise>
				</xsl:choose> online<xsl:if test="activity-todays/@users != 0">: </xsl:if>  
				<xsl:call-template name="split">
					<xsl:with-param name="to-be-split" select="activity-todays/@usernames" />
					<xsl:with-param name="delimiter" select="','" />
				</xsl:call-template>
				<xsl:if test="activity-todays/@guests != 0">
					 and <strong><xsl:value-of select="activity-todays/@guests" /></strong> guest<xsl:if test="activity-todays/@guests != 1">s</xsl:if>.
				</xsl:if>
			</p>
		</div>		
		<ul class="icons_legend">
			<li><img src="{/oyster/@styles}{/oyster/@style}/images/forums_new.png" alt="" /> New posts</li>		
		</ul>
	</xsl:template>