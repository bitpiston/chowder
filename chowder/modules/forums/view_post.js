<![CDATA[
// Scroll to post id
function ScrollToId(event)
{
	// disable running timeout if loaded faster
	try
	{
		window.clearTimeout(ScrollTimeout);
	}
	catch (ex)
	{
	}

	var add_offset = 0;
	try
	{
		add_offset += ScrollOffset;
	}
	catch (ex)
	{
	}
	
	var id = "]]>p<xsl:value-of select="/oyster/forums/@post_id" /><![CDATA[";				
	var url = window.location.href;
	if (id != "")
	{
		var obj = document.getElementById(id);
		if (obj != null)
		{
			var top = obj.offsetTop;
			while (obj = obj.offsetParent) top += obj.offsetTop;
			top -= 7;
			top += add_offset;
			window.scrollTo(0, top);
		}
	}
}

if (window.addEventListener != null)
	window.addEventListener("load", ScrollToId, false);

// scroll after 1s if the page hasn't loaded
var ScrollTimeout = window.setTimeout("ScrollToId();", 1000);
]]>