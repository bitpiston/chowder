	<xsl:template match="/oyster/forums[@action = 'delete_post']" mode="title">Delete Post</xsl:template>
	<xsl:template match="/oyster/forums[@action = 'delete_post']" mode="heading"><xsl:value-of select="/oyster/forums//thread/@title" /></xsl:template>
	<xsl:template match="/oyster/forums[@action = 'delete_post']" mode="description" xml:space="preserve">
		<div class="path">Forum: <a href="{/oyster/@base}forums/">Overview</a> 
			<xsl:for-each select="/oyster/forums//forum[@id = /oyster/forums/@forum_id and not(ancestor::parents)]/ancestor::forum">
				<span>&#8250;</span> <a href="{/oyster/@base}forums/forum/{@id}"><xsl:value-of select="@name" /></a> 
			</xsl:for-each>
			<span>&#8250;</span> <strong><a href="{/oyster/@base}forums/forum/{@forum_id}/"><xsl:value-of select="/oyster/forums//forum[@id = /oyster/forums/@forum_id]/@name" /></a></strong> <a href="{/oyster/@base}forums/rss/" title="RSS feed of all posts"><img src="{/oyster/@styles}{/oyster/@style}/images/feed.png" alt="RSS" /></a></div>
			<div class="desc"><xsl:value-of select="/oyster/forums//forum[@id = /oyster/forums/@forum_id]/@description" /></div>
	</xsl:template>
	<xsl:template match="/oyster/forums[@action = 'delete_post']" mode="content">
		<xsl:if test="/oyster/forums//error">
			<div class="errors">
				<xsl:for-each select="/oyster/forums//error">
					<div class="error"><span><strong>Error: </strong> <xsl:value-of select="text()" /></span></div>
				</xsl:for-each>
			</div>
		</xsl:if>
		<xsl:if test="/oyster/forums//confirmation">
			<div class="confirmation"><span><strong>Confirmation: </strong> <xsl:value-of select="/oyster/forums//confirmation/text()" /></span></div>
			<p>If you have not been redirected to the parent thread please <a href="{/oyster/@base}forums/thread/{/oyster/forums/@thread_id}/">click here to go there now</a>.</p><br />
		</xsl:if>
		<xsl:if test="not(/oyster/forums//confirmation)">
			<form class="compose_container" id="posteditor_form" action="{/oyster/@url}?a=delete" method="post">
				<strong>Delete Post: <xsl:value-of select="/oyster/forums//post/@title" /></strong><br />
				<p>This action cannot be undone, are you sure you want to delete this post?</p>
				<div class="submit_container">
					<input type="submit" name="save" id="save" value="Confirm delete" />
					<input type="reset" name="cancel" id="cancel" value="Cancel" onclick="history.back()" />
				</div>
			</form>
		</xsl:if>
	</xsl:template>
	