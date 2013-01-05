	<xsl:template name="forum">
		<xsl:param name="depth" select="0" />
		<div class="forum_header">
			<xsl:variable name="url">
				<xsl:if test="@new = 1">_new</xsl:if><!-- do me -->
			</xsl:variable>
			<xsl:choose>
				<xsl:when test="$depth = 2">
					<h3 xml:space="preserve"><a href="{/oyster/@base}forums/forum/{@id}/"><span class="icon"><img src="{/oyster/@styles}{/oyster/@style}/images/forums{$url}.png" alt="" /> </span><xsl:value-of select="@name" /></a></h3>
				</xsl:when>
				<xsl:otherwise>
					<h2 xml:space="preserve"><a href="{/oyster/@base}forums/forum/{@id}/"><span class="icon"><img src="{/oyster/@styles}{/oyster/@style}/images/forums{$url}.png" alt="" /> </span><xsl:value-of select="@name" /></a></h2>
				</xsl:otherwise>
			</xsl:choose>			 
			<!-- do me
			<ul class="forum_actions">
				<li class="add"><a href="forum;addparent=9#here">Add</a></li>
				<li class="edit"><a href="forum;editforum=9#here">Edit</a></li>
			</ul>				
			-->	
		</div>
		<div class="forum_data">
			<span class="desc"><xsl:value-of select="@description" /></span>
			<ul>
				<li class="threadcount"><xsl:value-of select="@threads" /> threads</li>

				<li class="postcount"><xsl:value-of select="@posts" /> posts</li>
				<li class="lastpost">Last post <xsl:value-of select="@last_date" /> ago in <a href="{/oyster/@base}forums/post/{@last_id}/"><xsl:value-of select="@last_title" /></a></li>
			</ul>
		</div>
	</xsl:template>