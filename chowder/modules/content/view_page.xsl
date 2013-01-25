<xsl:template match="/oyster/content[@action = 'view']" mode="heading">
	<xsl:apply-templates select="@title" mode="xhtml" />
</xsl:template>

<xsl:template match="/oyster/content[@action = 'view']" mode="content">
	<xsl:apply-templates select="body/*" mode="xhtml" />
</xsl:template>

<xsl:template match="/oyster/content[@action = 'view']" mode="sidebar">
	<xsl:apply-templates select="sidebar/*" mode="xhtml" />
</xsl:template>

<xsl:template match="/oyster/content[@action = 'view']" mode="html_head">
	<xsl:if test="description">
		<meta name="description" content="{description}" />
	</xsl:if>
</xsl:template>