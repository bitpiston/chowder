	<xsl:template match="/oyster/forums[@action = 'create_thread']" mode="title">New Thread</xsl:template>
	<xsl:template match="/oyster/forums[@action = 'create_thread']" mode="heading">
		<xsl:choose>
			<xsl:when test="/oyster/forums//post/body/xhtml"><xsl:value-of select="/oyster/forums//post/@title" /></xsl:when>
			<xsl:otherwise>New Thread</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="/oyster/forums[@action = 'create_thread']" mode="description" xml:space="preserve">
		<div class="path">Forum: <a href="{/oyster/@base}forums/">Overview</a> 
			<xsl:for-each select="/oyster/forums//forum[@id = /oyster/forums/@forum_id]/ancestor::forum">
				<span>&#8250;</span> <a href="{/oyster/@base}forums/forum/{@id}"><xsl:value-of select="@name" /></a> 
			</xsl:for-each>
			<span>&#8250;</span> <strong><a href="{/oyster/@base}forums/forum/{@forum_id}/"><xsl:value-of select="/oyster/forums//forum[@id = /oyster/forums/@forum_id]/@name" /></a></strong> <a href="{/oyster/@base}forums/rss/" title="RSS feed of all posts"><img src="{/oyster/@styles}{/oyster/@style}/images/feed.png" alt="RSS" /></a></div>
			<div class="desc"><xsl:value-of select="/oyster/forums//forum[@id = /oyster/forums/@forum_id]/@description" /></div>
	</xsl:template>
	<xsl:template match="/oyster/forums[@action = 'create_thread']" mode="content">
		<xsl:if test="/oyster/forums//error">
			<div class="errors">
				<xsl:for-each select="/oyster/forums//error">
					<div class="error"><span><strong>Error: </strong> <xsl:value-of select="text()" /></span></div>
				</xsl:for-each>
			</div>
		</xsl:if>
		<xsl:if test="/oyster/forums//confirmation">
			<div class="confirmation"><span><strong>Confirmation: </strong> <xsl:value-of select="/oyster/forums//confirmation/text()" /></span></div>
			<p>If you have not been redirected to your new thread please <a href="{/oyster/@base}forums/thread/{/oyster/forums//post/@id}/">click here to go there now</a>.</p><br />
		</xsl:if>
		<xsl:if test="not(/oyster/forums//confirmation)">
			<form class="compose_container" id="posteditor_form" action="{/oyster/@url}?a=create" method="post">
				<xsl:if test="/oyster/forums//post/body/xhtml">
					<div class="preview">
						<strong>Preview post:</strong><br />
						<div class="all_posts_container">
							<div class="post_container">
								<div class="post">
									<h2 class="number">#1</h2>
									<div class="date"><xsl:value-of select="/oyster/forums//post/@ctime" /></div>
									<div class="body">
										<xsl:apply-templates select="/oyster/forums//post/body/xhtml/node()" mode="xhtml" />
									</div>
									<xsl:if test="/oyster/forums//post/signature/node()">
										<div class="signature">
											<xsl:apply-templates select="/oyster/forums//post/signature/node()" mode="xhtml" />
										</div>
									</xsl:if>
								</div>
								<div class="author">
									<div class="name"><a href="{/oyster/@base}user/{/oyster/forums//post/@author_name}"><xsl:value-of select="/oyster/forums//post/@author_name" /></a></div>
									<div class="title"><xsl:value-of select="/oyster/forums//post/@author_title" /></div>
									<img class="avatar" src="{/oyster/forums//post/@author_avatar}" alt="Avatar" />
									<div class="posts"><a href=""><xsl:value-of select="/oyster/forums//post/@author_posts + 1" /></a> posts</div>
									<div class="age"><xsl:value-of select="/oyster/forums//post/@author_registered" /></div>
									<div class="location"><xsl:value-of select="/oyster/forums//post/@author_location" /></div>
								</div>
							</div>
						</div>
					</div>
				</xsl:if>
				<strong>Compose post:</strong><br />
				<div class="subject">
					<label for="thread_subject">Subject:</label>
					<input type="text" name="subject" id="thread_subject" maxlength="{/oyster/forums/@subject_length}" value="{/oyster/forums//post/@title}" />
				</div>
				<!-- Formating editor, smiley inserter and special characters -->
				<label for="thread_body">Message:</label><br />
				<textarea id="thread_body" name="body" rows="10" cols="40"><xsl:value-of select="/oyster/forums//post/body/raw" /></textarea>
				<div class="editor_controls">
					<small>Text length: <span id="textlength">?</span> characters (Maximum: <xsl:value-of select="/oyster/forums/@post_length" />)</small>
				</div>
				<div class="editor_options_container" id="posteditorOptions">
					<div class="editor_options2">
						<input type="checkbox" name="disable_signature" id="disable_signature" value="1">
							<xsl:if test="/oyster/forums//post/@signature = 1"><xsl:attribute name="checked">checked</xsl:attribute></xsl:if>
						</input>
						<label for="disable_signature"> Disable signature</label><br />
						<input type="checkbox" name="disable_smiles" id="disable_smiles" value="1">
							<xsl:if test="/oyster/forums//post/@smiles = 1"><xsl:attribute name="checked">checked</xsl:attribute></xsl:if>
						</input>
						<label for="disable_smiles"> Disable smiles</label><br />
						<input type="checkbox" name="disable_bbcode" id="disable_bbcode" value="1">
							<xsl:if test="/oyster/forums//post/@bbcode = 1"><xsl:attribute name="checked">checked</xsl:attribute></xsl:if>
						</input>
						<label for="disable_bbcode"> Disable <abbr title="Bulletin Board Code">bbCode</abbr></label>
					</div>				
					<div class="editor_options">
						<input type="hidden" name="watched" id="watched" value="1" />
						<input type="checkbox" name="enable_notification" id="enable_notification" value="1">
							<xsl:if test="/oyster/forums//post/@notify = 1"><xsl:attribute name="checked">checked</xsl:attribute></xsl:if>
						</input>
						<label for="enable_notification"> Notify me of replies by email</label><br />
						<xsl:if test="/oyster/user/permissions/@forums_sticky = 1">
							<input type="checkbox" name="sticky" id="sticky" value="1">
								<xsl:if test="/oyster/forums//post/@sticky = 1"><xsl:attribute name="checked">checked</xsl:attribute></xsl:if>
							</input>
							<label for="sticky"> Sticky thread</label><br />
						</xsl:if>
						<xsl:if test="/oyster/user/permissions/@forums_lock = 1">
							<input type="checkbox" name="locked" id="locked" value="1">
								<xsl:if test="/oyster/forums//post/@locked = 1"><xsl:attribute name="checked">checked</xsl:attribute></xsl:if>
							</input>
							<label for="locked"> Locked thread</label>
						</xsl:if>
					</div>				
					<!--
					<div class="editor_attach">
						<label for="attachfile">Attach file <small>(maximum: 500 kB)</small>:</label>
						<input type="file" id="attachfile" name="AttachFile" size="65" />
					</div>
					-->
				</div>
				<div class="submit_container">
					<input type="submit" name="save" id="save" value="Post thread" />
					<input type="submit" name="preview" id="preview" value="Preview" />
				</div>
			</form>
		</xsl:if>
	</xsl:template>
	
	