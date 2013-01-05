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
		<xsl:variable name="page" select="/oyster/forums/@page" />
		<xsl:if test="$remaining != 0">
			<xsl:if test="$nav != 0">
				<xsl:if test="$current = 1 and $current != $page">
					<a class="prev" href="{$url}?p={/oyster/forums/@page - 1}">previous</a>
				</xsl:if>
				<xsl:choose>
					<xsl:when test="$page = $current" xml:space="preserve">
						<strong class="selected"><xsl:value-of select="$current" /></strong>
					</xsl:when>
					<xsl:when test="not($current &gt;= $page + 3) and not($current &lt;= $page - 3)" xml:space="preserve">
						<a href="{$url}?p={$current}"><xsl:value-of select="$current" /></a>
					</xsl:when>
					<xsl:otherwise xml:space="preserve">
						<xsl:if test="($remaining = 3 and $current &gt; 4 and $page != 1 and $current != ($page + 3)) or ($remaining &gt; 3 and $current = 4)"> &#8230;</xsl:if>
						<xsl:if test="not($current &gt; 3) or $remaining &lt;= 3">
							<a href="{$url}?p={$current}"><xsl:value-of select="$current" /></a>
						</xsl:if>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:if test="$remaining = 1 and $current != $page">
					<a class="next" href="{$url}?p={/oyster/forums/@page + 1}">next</a>
				</xsl:if>			
			</xsl:if>
			<xsl:if test="$nav != 1" xml:space="preserve">
				<xsl:if test="$remaining = 3 and $current &gt; 4"> &#8230;</xsl:if>
				<xsl:if test="not($current &gt; 3) or $remaining &lt;= 3">
					<a href="{$url}?p={$current}"><xsl:value-of select="$current" /></a>
				</xsl:if>
			</xsl:if>
			<xsl:call-template name="pages-magic">
				<xsl:with-param name="current" select="$current + 1" />
				<xsl:with-param name="remaining" select="$remaining - 1" />
				<xsl:with-param name="url" select="$url" />
				<xsl:with-param name="nav" select="$nav" />
			</xsl:call-template>
		</xsl:if>
	</xsl:template>