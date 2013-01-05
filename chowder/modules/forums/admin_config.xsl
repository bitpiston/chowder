<xsl:template match="/oyster/forums[@action = 'admin_config']" mode="heading">
	Forums Configuration
</xsl:template>

<xsl:template match="/oyster/forums[@action = 'admin_config']" mode="description">
	These options control various aspects of your forums module.
</xsl:template>

<xsl:template match="/oyster/forums[@action = 'admin_config']" mode="content">
	<form id="user_admin_config" method="post" action="{/oyster/@url}">
		<div>
			<dl>
				<!-- Read Only -->
				<dt><label for="read_only">Read-only:</label></dt>
				<dd class="small">Sets forums to read-only and displays a maintenance message.</dd>
				<dd>
					<select id="read_only" name="read_only">
						<xsl:choose>
							<xsl:when test="@read_only= '1'">
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
				<!-- Read Only -->
				<dt><label for="show_online_users">Show online users:</label></dt>
				<dd class="small">Displays users currently browsing the forums and threads.</dd>
				<dd>
					<select id="show_online_users" name="show_online_users">
						<xsl:choose>
							<xsl:when test="@show_online_users= '1'">
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
				<!-- Threads per page -->
				<dt><label for="threads_per_page">Threads per page:</label></dt>
				<dd class="small">The default name that will be given to users when they are not logged in.</dd>
				<dd><input type="text" name="threads_per_page" id="threads_per_page" value="{@threads_per_page}" size="15" /></dd>
				<!-- Posts per page -->
				<dt><label for="posts_per_page">Posts per page:</label></dt>
				<dd class="small">The default name that will be given to users when they are not logged in.</dd>
				<dd><input type="text" name="posts_per_page" id="posts_per_page" value="{@posts_per_page}" size="15" /></dd>
				<!-- Hot posts threshold -->
				<dt><label for="hot_posts_threshold">Hot posts threshold:</label></dt>
				<dd class="small">The default name that will be given to users when they are not logged in.</dd>
				<dd><input type="text" name="hot_posts_threshold" id="hot_posts_threshold" value="{@hot_posts_threshold}" size="15" /></dd>
				<!-- Hot views threshold -->
				<dt><label for="hot_views_threshold">Hot views threshold:</label></dt>
				<dd class="small">The default name that will be given to users when they are not logged in.</dd>
				<dd><input type="text" name="hot_views_threshold" id="hot_views_threshold" value="{@hot_views_threshold}" size="15" /></dd>
				<!-- Max post length -->
				<dt><label for="max_post_length">Max post length:</label></dt>
				<dd class="small">The default name that will be given to users when they are not logged in.</dd>
				<dd><input type="text" name="max_post_length" id="max_post_length" value="{@max_post_length}" size="15" /></dd>
				<!-- Min subject length -->
				<dt><label for="min_subject_length">Min subject length:</label></dt>
				<dd class="small">The default name that will be given to users when they are not logged in.</dd>
				<dd><input type="text" name="min_subject_length" id="min_subject_length" value="{@min_subject_length}" size="15" /></dd>
				<!-- Max subject length -->
				<dt><label for="max_subject_length">Max subject length:</label></dt>
				<dd class="small">The default name that will be given to users when they are not logged in.</dd>
				<dd><input type="text" name="max_subject_length" id="max_subject_length" value="{@max_subject_length}" size="15" /></dd>
			</dl>
			<input type="submit" value="Save" />
		</div>
	</form>
</xsl:template>
