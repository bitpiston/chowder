<xsl:template match="/oyster/content[@action = 'admin_templates']" mode="heading">
	Manage Templates
</xsl:template>

<xsl:template match="/oyster/content[@action = 'admin_templates']" mode="description">
	Content pages can have custom fields.  Templates provide the base fields for new pages.
</xsl:template>

<xsl:template match="/oyster/content[@action = 'admin_templates']" mode="content">
	<xsl:if test="count(template)">
		<ul>
			<xsl:for-each select="template">
				<li>
					<xsl:value-of select="@name" />
					<small>
						[ <a href="{/oyster/@url}edit/?id={@id}">Edit</a> -
						<a href="{/oyster/@url}?a=delete&amp;id={@id}">Delete</a> ]
					</small>
				</li>
			</xsl:for-each>
		</ul>
	</xsl:if>
	<h2>Create a New Template</h2>
	<form id="content_admin_templates" method="post" action="{/oyster/@url}">
		<input type="hidden" name="a" value="create" />
		<dl>
			<dt><label for="create_name">Name:</label></dt>
			<dd><input type="text" name="create_name" id="create_name" value="{@create_name}" class="small" /></dd>
			<dt><input type="submit" value="Create" /></dt>
		</dl>
	</form>
</xsl:template>
