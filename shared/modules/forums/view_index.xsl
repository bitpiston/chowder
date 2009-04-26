	<oyster:include href="forums/_forum.xsl" />
	
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
	</xsl:template>