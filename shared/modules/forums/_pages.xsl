	<xsl:template name="pages">
		<xsl:param name="pages" select="0" />
		<xsl:param name="url" select="0" />
		<xsl:param name="nav" select="0" />	
		<xsl:if test="$pages &gt; 1">
	  	  	<xsl:call-template name="pages-magic">
				<xsl:with-param name="current" select="1" />
				<xsl:with-param name="remaining" select="$pages" />
				<xsl:with-param name="url" select="$url" />
				<xsl:with-param name="nav" select="$nav" />
			</xsl:call-template>
		</xsl:if>
	</xsl:template>
	<xsl:template name="pages-magic">
		<xsl:param name="current" select="0" />
		<xsl:param name="remaining" select="0" />
		<xsl:param name="url" select="0" />
		<xsl:param name="nav" select="0" />
		<xsl:if test="$current = 1 and $nav = 1 and not($current = /oyster/forums/@page)">
			<a class="prev" href="{$url}?p={/oyster/forums/@page - 1}">previous</a>
		</xsl:if>
		<xsl:if test="not($remaining = 0)">
			<xsl:if test="$remaining = 3 and $current &gt; 4"> &#8230;</xsl:if>
			<xsl:if test="not($current &gt; 3) or $remaining &lt;= 3">
				<xsl:choose>
					<xsl:when test="/oyster/forums/@page = $current and $nav = 1">
						<strong class="selected"><xsl:value-of select="$current" /></strong>
					</xsl:when>
					<xsl:otherwise>
						<a href="{$url}?p={$current}"><xsl:value-of select="$current" /></a>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:if>
			<xsl:call-template name="pages-magic">
				<xsl:with-param name="current" select="$current + 1" />
				<xsl:with-param name="remaining" select="$remaining - 1" />
				<xsl:with-param name="url" select="$url" />
				<xsl:with-param name="nav" select="$nav" />
			</xsl:call-template>
		</xsl:if>
		<xsl:if test="$remaining = 1 and $nav = 1 and not($current = /oyster/forums/@page)">
			<a class="next" href="{$url}?p={/oyster/forums/@page + 1}">next</a>
		</xsl:if>
	</xsl:template>
	