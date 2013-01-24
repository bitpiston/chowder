<oyster:import href="content/view_page.xsl" />

<xsl:template match="/oyster/content[@action = 'create' or @action = 'edit']" mode="html_head">
    <link rel="stylesheet" href="{/oyster/@styles}codemirror.css" />
	<script src="{/oyster/@styles}codemirror.min.js" />
    <script src="{/oyster/@styles}codemirror-xml.min.js" />
    <style>
        .CodeMirror {
            width: 900px;
            border: 1px solid #999;
            background: #fff;
        }
        .CodeMirror-scroll {
            height: 600px; overflow: hidden;
        }
    </style>
</xsl:template>


<xsl:template match="/oyster/content[@action = 'create' or @action = 'edit' or @action = 'create_select_template']" mode="heading">
	<xsl:choose>
		<xsl:when test="@action = 'create' or @action = 'create_select_template'">Create </xsl:when>
		<xsl:when test="@action = 'edit'">Edit </xsl:when>
	</xsl:choose>
	a Content page
</xsl:template>

<xsl:template match="/oyster/content[@action = 'create' or @action = 'edit' or @action = 'create_select_template']" mode="description">
	Content pages are free-form pages where you can use your own xhtml or bbcode to create content.  <a href="#">Click here</a> to learn more about advanced features content pages have.
</xsl:template>

<xsl:template match="/oyster/content[@action = 'create_select_template']" mode="content">
	<form id="content_create" method="get" action="{/oyster/@url}">
		<input type="hidden" name="a" value="create" />
		<input type="hidden" name="parent" value="{@parent}" />
		<dl>
			<dt><label for="template">Select a Template</label></dt>
			<dd><select id="template" name="template">
				<xsl:for-each select="template">
					<option value="{@id}"><xsl:value-of select="@name" /></option>
				</xsl:for-each>
			</select></dd>
			<dt><input type="submit" /></dt>
		</dl>
	</form>
</xsl:template>

<xsl:template match="/oyster/content[@action = 'create' or @action = 'edit']" mode="content">
    <xsl:if test="/oyster/content[@action = 'view']"><br /><hr /><br /></xsl:if>
	<form id="content_createedit" method="post" action="{/oyster/@url}?a={@action}&amp;parent={@parent}">
		<input type="hidden" id="content_createedit_handler" name="handler" value="" />
		<div>
			<!-- top submit button when previewing, so you don't have to scroll down to save  -->
			<xsl:if test="@has_validated = 1">
				<input type="submit" name="save" value="Save" /><br />
			</xsl:if>

			<!-- add fields -->
            <!--
			<fieldset id="f_addfield">
				<legend>Add a New Field</legend>
				<dl>
					<input type="hidden" name="field_1" value="1" />
					<input type="hidden" name="field_1_inside_content_node" value="1" />
					<input type="hidden" name="field_1_translation_mode" value="bbcode" />
					<dt><label for="field_1_name">Name:</label></dt>
					<dd><input type="text" name="field_1_name" id="field_1_name" value="{@name}" /></dd>
					<dt><label for="field_1_type">Type:</label></dt>
					<dd>
						<select id="field_1_type" name="field_1_type">
							<option value="text_small">
								<xsl:if test="@type = 'text_small'"><xsl:attribute name="selected">selected</xsl:attribute></xsl:if>
								Single Line Text (Small)
							</option>
							<option value="text">
								<xsl:if test="@type = 'text'"><xsl:attribute name="selected">selected</xsl:attribute></xsl:if>
								Single Line Text (Medium)
							</option>
							<option value="text_large">
								<xsl:if test="@type = 'text_large'"><xsl:attribute name="selected">selected</xsl:attribute></xsl:if>
								Single Line Text (Large)
							</option>
							<option value="text_large">
								<xsl:if test="@type = 'text_full'"><xsl:attribute name="selected">selected</xsl:attribute></xsl:if>
								Single Line Text (Full)
							</option>
							<option value="textarea_small">
								<xsl:if test="@type = 'textarea_small'"><xsl:attribute name="selected">selected</xsl:attribute></xsl:if>
								Multi-Line Text (Small)
							</option>
							<option value="textarea">
								<xsl:if test="@type = 'textarea'"><xsl:attribute name="selected">selected</xsl:attribute></xsl:if>
								Multi-Line Text (Medium)
							</option>
							<option value="textarea_large">
								<xsl:if test="@type = 'textarea_large'"><xsl:attribute name="selected">selected</xsl:attribute></xsl:if>
								Multi-Line Text (Large)
							</option>
							<option value="textarea_full">
								<xsl:if test="@type = 'textarea_full'"><xsl:attribute name="selected">selected</xsl:attribute></xsl:if>
								Multi-Line Text (Full)
							</option>
						</select>
					</dd>
				</dl>
			</fieldset>
            -->

			<!-- fields -->
			<fieldset id="f_fields">
				<legend>Edit Fields</legend>
				<dl>

					<!-- page title -->
					<dt><label for="page_title">Page Title:</label></dt>
					<dd><input class="large" type="text" name="title" id="page_title" value="{@title}" /></dd>
					
					<!-- navigation title -->
					<dt><label for="nav_title">Navigation Title:</label></dt>
					<dd><input class="large" type="text" name="nav_title" id="nav_title" value="{@nav_title}" /></dd>
                    
					<!-- url slug -->
					<dt><label for="page_slug">Slug:</label></dt>
					<dd>
						<xsl:if test="@parent_url != ''"><span style="float: left; text-align: bottom; line-height: 2.1">/<xsl:value-of select="@parent_url" />/</span></xsl:if>
						<input class="large" type="text" name="slug" id="page_slug" value="{@slug}" />
					</dd>
                                        
					<!-- show navigation link -->
					<dd>
						<input type="checkbox" name="show_nav_link" id="show_nav_link" value="1">
							<xsl:if test="@show_nav_link = 'true'">
								<xsl:attribute name="checked">checked</xsl:attribute>
							</xsl:if>
						</input>
						<label for="show_nav_link">Show a link to this page in the site navigation</label>
					</dd>

					<!-- the rest of the fields -->
					<xsl:for-each select="field">
						<xsl:variable name="field_prefix">field_<xsl:value-of select="position()" />_</xsl:variable>
						<input type="hidden" name="field_{position()}" value="1" />
						<!--<xsl:if test="not(position() = 1 and ../@has_validated = 1)">-->
							<input type="hidden" name="{$field_prefix}name" value="{@name}" />
							<input type="hidden" name="{$field_prefix}type" value="{@type}" />
							<input type="hidden" name="{$field_prefix}inside_content_node" value="{@inside_content_node}" />
							<dt><label for="{$field_prefix}value"><xsl:value-of select="@name" />:</label></dt>
							<xsl:choose>
								<xsl:when test="@type = 'textarea_small' or @type = 'textarea' or @type = 'textarea_large' or @type = 'textarea_full'">
									<dd>
                                        <!--
										<xsl:call-template name="sims_js_editbuttons">
											<xsl:with-param name="translation_mode_field_id"><xsl:value-of select="$field_prefix" />translation_mode</xsl:with-param>
											<xsl:with-param name="field_id"><xsl:value-of select="$field_prefix" />value</xsl:with-param>
										</xsl:call-template>
                                        -->
										<textarea id="{$field_prefix}value" name="{$field_prefix}value" rows="8" cols="50">
											<xsl:attribute name="class">
												<xsl:if test="@type = 'textarea_small'">small</xsl:if>
												<xsl:if test="@type = 'textarea_large'">large</xsl:if>
												<xsl:if test="@type = 'textarea_full'">full</xsl:if>
											</xsl:attribute><xsl:value-of select="value" />
										</textarea>
                                        <xsl:if test="@translation_mode = 'xhtml'">
                                    		<script>
                                                var editor = CodeMirror.fromTextArea(document.getElementById("<xsl:value-of select="$field_prefix" />value"), {
                                                    mode: {name: "xml", alignCDATA: true},
                                                    lineNumbers: true,
                                                    lineWrapping: true
                                                });
                                    		</script>
                                        </xsl:if>                            
									</dd>
									<!--<dt><label for="{$field_prefix}translation_mode">Content Type:</label></dt>-->
									<dd>
										<select id="{$field_prefix}translation_mode" name="{$field_prefix}translation_mode">
											<xsl:choose>
												<xsl:when test="@translation_mode = 'xhtml'">
													<option value="xhtml" selected="selected">XHTML</option>
													<option value="bbcode">BBcode</option>
												</xsl:when>
												<xsl:otherwise>
													<option value="xhtml">XHTML</option>
													<option value="bbcode" selected="selected">BBcode</option>
												</xsl:otherwise>
											</xsl:choose>
										</select>
									</dd>
								</xsl:when>
								<xsl:when test="@type = 'text_small' or @type = 'text' or @type = 'text_large' or @type = 'text_full'">
									<dd><input type="text" id="{$field_prefix}value" name="{$field_prefix}value" value="{value/text()}">
										<xsl:attribute name="class">
											<xsl:if test="@type = 'text_small'">small</xsl:if>
											<xsl:if test="@type = 'text_large'">large</xsl:if>
											<xsl:if test="@type = 'text_full'">full</xsl:if>
										</xsl:attribute>
									</input></dd>
								</xsl:when>
								<xsl:when test="@type = 'dropdown'">
									<xsl:for-each select="option">
										<input type="hidden" name="{$field_prefix}dropdown_option_{position()}" value="{@value}" />
									</xsl:for-each>
									<dd>
										<select id="{$field_prefix}value" name="{$field_prefix}value">
											<xsl:for-each select="option">
												<option>
													<xsl:if test="../value/text() = @value"><xsl:attribute name="selected">selected</xsl:attribute></xsl:if>
													<xsl:value-of select="@value" />
												</option>
											</xsl:for-each>
										</select>
									</dd>
								</xsl:when>
							</xsl:choose>
						<!--</xsl:if>-->
					</xsl:for-each>
				</dl>
			</fieldset>
			<!-- preview/submit -->
			<input type="submit" value="Preview" onclick="sims.ajax_submit_form('content_createedit', 'content'); return false" />
			<xsl:if test="@has_validated = 1">
				<input type="submit" name="save" value="Save" />
			</xsl:if>
		</div>
	</form>

	<!-- files -->
	<xsl:if test="@can_add_files = 'true'">
		<xsl:call-template name="file_add_ajax" />
	</xsl:if>
</xsl:template>
