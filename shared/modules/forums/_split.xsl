	<xsl:template name="split">
		<xsl:param name="to-be-split" />
		<xsl:param name="delimiter" />
		<xsl:choose>
			<xsl:when test="contains($to-be-split,$delimiter)">
			    <a href=""><xsl:value-of select="substring-before($to-be-split,$delimiter)" /></a>, 
				<xsl:call-template name="split">
				    <xsl:with-param name="to-be-split" select="substring-after($to-be-split,$delimiter)" />
					<xsl:with-param name="delimiter" select="','" />
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<a href=""><xsl:value-of select="$to-be-split" /></a>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>