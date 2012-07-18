<xsl:template match="/oyster/content[@action = 'admin_templates_edit']" mode="heading">
	Modify Template - <xsl:value-of select="@name" />
</xsl:template>

<xsl:template match="/oyster/content[@action = 'admin_templates_edit']" mode="description">
	Templates allow content pages to be created with a pre-made set of fields.
</xsl:template>

<xsl:template match="/oyster/content[@action = 'admin_templates_edit']" mode="content">
	<script type="text/javascript">

		// show/hide translation mode and dropdown option divs
		function field_type_updated(field_id) {
			prefix = 'field_' + field_id

			// get field type dropdown element
			type = document.getElementById(prefix + '_type')

			// if the field is a dropdown
			if (type.value == 'dropdown') {
				document.getElementById(prefix + '_dropdown_options_group').style.display = 'block'
			} else {
				document.getElementById(prefix + '_dropdown_options_group').style.display = 'none'
			}

			// if the field is any kind of a textarea
			if (type.value.substring(0, 8) == 'textarea') {
				document.getElementById(prefix + '_translation_mode_group').style.display = 'block'
			} else {
				document.getElementById(prefix + '_translation_mode_group').style.display = 'none'
			}
		}
	</script>
	<form id="content_admin_templates_edit" method="post" action="{/oyster/@url}{/oyster/@query_string}">
		<div>
			<label for="name">Name:</label><br />
			<input type="text" name="name" id="name" value="{@name}" /><br />
			<xsl:for-each select="field">
				<xsl:variable name="field_prefix">field_<xsl:value-of select="position()" />_</xsl:variable>
				<fieldset id="edit_field_{position()}">
					<legend>
						<xsl:choose>
							<xsl:when test="position() = 1">
								Add a New Field
							</xsl:when>
							<xsl:otherwise>
								Edit <xsl:value-of select="@name" />
							</xsl:otherwise>
						</xsl:choose>
					</legend>
					<input type="hidden" name="field_{position()}" value="1" />
					<dl>
						<dt><label for="{$field_prefix}name">Name:</label></dt>
						<dd>
							<input type="text" name="{$field_prefix}name" id="{$field_prefix}name" value="{@name}" />
							<input type="hidden" name="{$field_prefix}inside_content_node" id="{$field_prefix}inside_content_node" value="1" /> <!-- this goes with the commented stuff following -->
						</dd>
						<!--
						<dt>
							<label for="{$field_prefix}inside_content_node">Inside Content Node</label><br />
							<small>(Ignore if you don't understand... need a better comment here)</small>
						</dt>
						<dd>
							<select id="{$field_prefix}inside_content_node" name="{$field_prefix}inside_content_node">
								<xsl:choose>
									<xsl:when test="@inside_content_node = '1'">
										<option value="1" selected="selected">Yes</option>
										<option value="0">No</option>
									</xsl:when>
									<xsl:otherwise>
										<option value="1">Yes</option>
										<option value="0" selected="selected">No</option>
								</xsl:otherwise>
								</xsl:choose>
							</select>
						</dd>
						-->
						<dt><label for="{$field_prefix}type">Type:</label></dt>
						<dd>
							<select id="{$field_prefix}type" name="{$field_prefix}type" onchange="field_type_updated({position()})">
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
								<option value="dropdown">
									<xsl:if test="@type = 'dropdown'"><xsl:attribute name="selected">selected</xsl:attribute></xsl:if>
									Dropdown Menu
								</option>
							</select>
						</dd>
					</dl>
					<dl id="{$field_prefix}translation_mode_group">
						<dt>
							<label for="{$field_prefix}translation_mode">Content Type:</label><br />
						</dt>
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
					</dl>
					<dl id="{$field_prefix}dropdown_options_group">
						<dt><label>Dropdown Options:</label></dt>
						<xsl:for-each select="option">
							<dd><input type="text" name="{$field_prefix}dropdown_option_{position()}" id="{$field_prefix}dropdown_option_{position()}" value="{@value}" class="small" /></dd>
						</xsl:for-each>
						<dd><input type="text" name="{$field_prefix}dropdown_option_{count(option) + 1}" id="{$field_prefix}dropdown_option_{count(option) + 1}" class="small" /></dd>
						<dd><input type="text" name="{$field_prefix}dropdown_option_{count(option) + 2}" id="{$field_prefix}dropdown_option_{count(option) + 2}" class="small" /></dd>
						<dd><input type="text" name="{$field_prefix}dropdown_option_{count(option) + 3}" id="{$field_prefix}dropdown_option_{count(option) + 3}" class="small" /></dd>
					</dl>
					<script type="text/javascript">
						field_type_updated(<xsl:value-of select="position()" />)
					</script>
				</fieldset>
			</xsl:for-each>
			<input type="submit" value="Save" />
		</div>
	</form>
</xsl:template>

