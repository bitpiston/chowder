	<xsl:template name="forum">
		<xsl:param name="depth" select="0" />
		<!-- do me
		<xsl:if test="">
			<xsl:attribute name="class">newposts</xsl:attribute>
		</xsl:if>
		-->
		<div class="forum_icon"> <!-- ditch me for css background -->
			<a href="{/oyster/@base}forums/forum/{@id}/"><img src="{/oyster/@styles}{/oyster/@style}/images/comments.png" alt="" /></a>
		</div>
		<div class="forum_header">
			<xsl:choose>
				<xsl:when test="$depth = 2">
					<h3 xml:space="preserve"><a href="{/oyster/@base}forums/forum/{@id}/"><xsl:value-of select="@name" /></a> <em>(New posts)</em></h3><!-- css bg replace span text: <img src="./layout/images/new.png" alt="" title="Forum" /> -->
				</xsl:when>
				<xsl:otherwise>
					<h2 xml:space="preserve"><a href="{/oyster/@base}forums/forum/{@id}/"><xsl:value-of select="@name" /></a> <em>(New posts)</em></h2><!-- css bg replace span text: <img src="./layout/images/new.png" alt="" title="Forum" /> -->
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