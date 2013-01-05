<xsl:template match="/oyster/contact" mode="html_head">
	<script src="//ajax.googleapis.com/ajax/libs/jquery/1.7/jquery.min.js" />
	<script><![CDATA[
		!window.jQuery && document.write(unescape('%3Cscript src="{/oyster/@styles}jquery-1.7.min.js"%3E%3C/script%3E'))
	]]></script>
	<script type="text/javascript" src="{/oyster/@styles}validate.min.js" /> 
		<script type="text/javascript"><![CDATA[
			$(document).ready(function(){
				// Toggle the input labels
				var textboxes = $('label + input, label + textarea');
				textboxes.each(function(index, input){
					var label = $(input).prev("label");
					if( index == 0 ){
					  	setInterval(function(){
					     	textboxes.each(function(index,inputX){
					      		if ( inputX.value!="" ) {
					        		$(inputX).prev("label").addClass('has-text');
					      		}
					    	});
					 	}, 100);
					}			 	
				 	$(this).focus(function () {
				  		$(this).prev("label").addClass("focus");
				 	});
				 	$(this).keypress(function () {
				  		$(this).prev("label").addClass("has-text").removeClass("focus");
				 	});
				 	$(this).blur(function () {
				  		if($(this).val() == "") {
				  			$(this).prev("label").removeClass("has-text").removeClass("focus");
				  		}
				 	});
					if($(this).val() != "") {
						$(this).prev("label").addClass("has-text").removeClass("focus");
					}
				});
				// validate signup form on keyup and submit
				$("#contact").validate({
					rules: {
						contact_author: {
							required: true
						},
						contact_email: {
							required: true,
							email: true
						},
						contact_subject: {
							required: true
						},
						contact_message: {
							required: true
						},
					},
					messages: {
						contact_author: "Please enter your name.",
						contact_email: "Please enter a valid email address.",
						contact_subject: "Please enter a subject for the message.",
						contact_message: "Please enter a message to send.",
					}
				});
			});
		]]></script>
</xsl:template>

<xsl:template match="/oyster/contact" mode="heading">
	Contact BitPiston
</xsl:template>

<xsl:template match="/oyster/contact[@action = 'view']" mode="content">
	<p>You can get in touch with BitPiston using the form below or via email or phone.</p>
	<form class="rows" id="contact" method="post" action="/contact/">
		<div>
			<label for="contact_author">Name</label>
			<input type="text" id="contact_author" name="contact_author" value="{/oyster/contact/name}" size="45" />
		</div>
		<div>
			<label for="contact_email">Email</label>
			<input type="text" id="contact_email" name="contact_email" value="{/oyster/contact/email}" size="45" />
		</div>
		<div>
			<label for="contact_subject">Subject</label>
			<input type="text" id="contact_subject" name="contact_subject" value="{/oyster/contact/subject}" size="70" /> 
		</div>
		<div class="textarea">
			<label for="contact_message">Message</label>
			<textarea id="contact_message" name="contact_message" cols="60" rows="15">
				<xsl:value-of select="/oyster/contact/message" />
			</textarea>
		</div>
		<div class="submit">
			<input type="checkbox" id="contact_cc" name="contact_cc" value="1">
				<xsl:if test="/oyster/contact/cc = 1">	
					<xsl:attribute name="checked">checked</xsl:attribute>
				</xsl:if>
			</input>
			<label for="contact_cc">Send me a copy</label><br />
			<input type="submit" id="submit" name="Submit" value="Send email" />
		</div>
		<input type="hidden" id="contact_ts" name="contact_ts" value="{/oyster/contact/@time}" />
	</form>
</xsl:template>

<xsl:template match="/oyster/contact[@action = 'confirmation']" mode="content">
	<p>Your message to BitPiston has been sent via e-mail. We will get back to you as soon as possible!</p>
</xsl:template>

<xsl:template match="/oyster/contact" mode="sidebar">
	<!--
	<h2><span>Client Worksheet</span></h2>
	<p>If you are making a service enquiry and would like a quote or a proposal please complete our client worksheet to give us a clear idea of what you require.</p>
	<p><a class="down" href="/contact/worksheet.pdf">Download client worksheet</a> (PDF)</p>
	-->
	<h2><span>Office Address</span></h2>
	<address class="vcard">
		<div class="fn org"><a class="url" href="http://bitpiston.com">BitPiston Studios Ltd.</a></div>
		<div class="adr">
			<div class="street-address">9&#8211;1401 Fort Street</div>
			<span class="locality">Victoria</span>, 
			<span class="region"><abbr title="Biritish Columbia">B.C.</abbr></span> 
			<span class="postal-code">V8S 1Y9</span>
			<span class="country-name">Canada</span>
		</div>
		<div> 
			<a class="email" href="mailto:contact@bitpiston.com">contact@bitpiston.com</a> 
		</div>
		<div class="tel main">
			<span class="value"><a href="tel:-1-778-678-2248">+1 (778) 678-2248</a></span>
		</div>
	</address>
	<p><a class="down" href="http://bitpiston.com/files/BitPiston.vcf">Download vCard</a></p>
</xsl:template>
