<xsl:template match="/oyster/content[@action = 'admin_config']" mode="heading">
	Content Configuration
</xsl:template>

<xsl:template match="/oyster/content[@action = 'admin_config']" mode="description">
	These options control various aspects of your content module.
</xsl:template>

<xsl:template match="/oyster/content[@action = 'admin_config']" mode="content">
	<form id="content_admin_config" method="post" action="{/oyster/@url}">
		<dl>
			<dt><label for="num_revisions">Number of Page Revisions to Save:</label></dt>
			<dd class="small">Whenever a content page is edited, the previous revision is saved.  This option determines how many revisions to save in the page history.</dd>
			<dd><input type="text" name="num_revisions" id="num_revisions" value="{@num_revisions}" class="small" /></dd>
			<dt><label for="subpage_depth">Sub-page Depth:</label></dt>
			<dd class="small">TODO: is this option necessary anymore with global url handling any unrestricted parent types?  Should this be moved to a site setting?</dd>
			<dd><input type="text" name="subpage_depth" id="subpage_depth" value="{@subpage_depth}" class="small" /></dd>
			<dt><input type="submit" value="Save" /></dt>
		</dl>
	</form>
</xsl:template>
