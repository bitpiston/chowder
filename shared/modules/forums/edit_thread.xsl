	<xsl:template match="/oyster/forums[@action = 'edit_thread']" mode="title">Edit Topic</xsl:template>
	<xsl:template match="/oyster/forums[@action = 'edit_thread']" mode="heading"><xsl:value-of select="/oyster/forums//thread/@title" /></xsl:template>
	<xsl:template match="/oyster/forums[@action = 'edit_thread']" mode="description" xml:space="preserve">
		<div class="path">Forum: <a href="{/oyster/@base}forums/">Overview</a> 
			<xsl:for-each select="/oyster/forums//forum[@id = /oyster/forums/@forum_id and not(ancestor::parents)]/ancestor::forum">
				<span>&#8250;</span> <a href="{/oyster/@base}forums/forum/{@id}"><xsl:value-of select="@name" /></a> 
			</xsl:for-each>
			<span>&#8250;</span> <strong><a href="{/oyster/@base}forums/forum/{@forum_id}/"><xsl:value-of select="/oyster/forums//forum[@id = /oyster/forums/@forum_id]/@name" /></a></strong> <a href="{/oyster/@base}forums/rss/" title="RSS feed of all posts"><img src="{/oyster/@styles}{/oyster/@style}/images/feed.png" alt="RSS" /></a></div>
			<div class="desc"><xsl:value-of select="/oyster/forums//forum[@id = /oyster/forums/@forum_id]/@description" /></div>
	</xsl:template>
	<xsl:template name="generate-string">
		<xsl:param name="string" select="''" />
		<xsl:param name="count" select="0" />
		<xsl:if test="$count > 0">
		   <xsl:value-of select="$string" />
		   <xsl:call-template name="generate-string">
		     <xsl:with-param name="string" select="$string" />
		     <xsl:with-param name="count" select="$count - 1" />
		   </xsl:call-template>		
		</xsl:if>
	</xsl:template>	
	<xsl:template name="options">
		<xsl:param name="depth" select="0" />
		<option value="{@id}">
			<xsl:if test="@id = /oyster/forums/@forum_id">
				<xsl:attribute name="selected">selected</xsl:attribute>
			</xsl:if>
			<xsl:call-template name='generate-string'>
			  <xsl:with-param name='string'>&#160; &#160; </xsl:with-param>
			  <xsl:with-param name='count' select='$depth'/>
			</xsl:call-template>
			<xsl:value-of select="@name" />
		</option>
		<xsl:for-each select="forum">
			<xsl:call-template name="options">
				<xsl:with-param name="depth" select="$depth + 1" />
			</xsl:call-template>
		</xsl:for-each>
	</xsl:template>
	<xsl:template match="/oyster/forums[@action = 'edit_thread']" mode="content">
		<xsl:if test="/oyster/forums//error">
			<div class="errors">
				<xsl:for-each select="/oyster/forums//error">
					<div class="error"><span><strong>Error: </strong> <xsl:value-of select="text()" /></span></div>
				</xsl:for-each>
			</div>
		</xsl:if>
		<xsl:if test="/oyster/forums//confirmation">
			<div class="confirmation"><span><strong>Confirmation: </strong> <xsl:value-of select="/oyster/forums//confirmation/text()" /></span></div>
			<p>If you have not been redirected to the topic please <a href="{/oyster/@base}forums/thread/{/oyster/forums//thread/@id}/">click here to go there now</a>.</p><br />
		</xsl:if>
		<xsl:if test="not(/oyster/forums//confirmation)">
			<form class="compose_container" id="posteditor_form" action="{/oyster/@url}?a=edit" method="post">
				<strong>Edit thread:</strong><br />
				<div class="subject">
					<label for="thread_subject">Subject:</label>
					<input type="text" name="subject" id="thread_subject" maxlength="{/oyster/forums/@subject_length}" value="{/oyster/forums//thread/@title}" />
				</div>
				<div class="editor_options_container" id="posteditorOptions">
					<div class="editor_options">
						<xsl:if test="/oyster/user/permissions/@forums_sticky = 1">
							<input type="checkbox" name="sticky" id="sticky" value="1">
								<xsl:if test="/oyster/forums//thread/@sticky = 1"><xsl:attribute name="checked">checked</xsl:attribute></xsl:if>
							</input>
							<label for="sticky"> Sticky topic</label><br />
						</xsl:if>
						<xsl:if test="/oyster/user/permissions/@forums_lock = 1">
							<input type="checkbox" name="locked" id="locked" value="1">
								<xsl:if test="/oyster/forums//thread/@locked = 1"><xsl:attribute name="checked">checked</xsl:attribute></xsl:if>
							</input>
							<label for="locked"> Lock topic</label>
						</xsl:if>
					</div>
				</div>
				<xsl:if test="/oyster/user/permissions/@forums_move = 1">
					<strong>Move topic:</strong><br />
					<div class="parent">
						<label for="move_to">Parent forum:</label>
						<select name="move_to" id="move_to">
							<xsl:for-each select="/oyster/forums//thread/parents/forum">
								<xsl:call-template name="options">
								</xsl:call-template>
							</xsl:for-each>
						</select>
					</div>
					<div class="editor_options_container">
						<div class="editor_options">
							<input type="checkbox" name="moved_note" id="moved_note" value="1" checked="checked" />
							<label for="moved_note"> Moved note</label>
						</div>
					</div>
				</xsl:if>
				<div class="submit_container">
					<input type="submit" name="save" id="save" value="Save changes" />
					<input type="reset" name="cancel" id="cancel" value="Cancel" onclick="history.back()" />
				</div>
			</form>
		</xsl:if>
	</xsl:template>
	