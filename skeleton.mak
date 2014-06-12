<%namespace name="searchBar" file="searchBar.mak" inheritable="True" />
<%namespace name="register" file="register.mak" inheritable="True" />
<%namespace name="v" file="version.mak" inheritable="True" />
<%namespace name="objectSquare" file="objectSquare.mak" inheritable="True" />
<%namespace name="objectSquareContainer" file="objectSquareContainer.mak" inheritable="True" />
<%namespace name="signUp" file="signUp.mak" inheritable="True" />

<!doctype html>
<html itemscope itemtype="http://schema.org/Product">
<head>
	<meta charset="utf-8">
	<meta name="p:domain_verify" content="8547f04cb106bd5bd6d9e466e7e1993c" />
	<link rel="icon" type="image/png" href="../static/images/Icons/infiknoFab.png" />
	<!-- Loading Bootstrap -->
    <link href="/static/flatUi/css/bootstrap.css" rel="stylesheet">
    <!-- Loading Flat UI -->
    <link href="/static/flatUi/css/flat-ui.css" rel="stylesheet">
    <!--[if lt IE 9]>
      <script src="/static/flatUi/js/html5shiv.js"></script>
    <![endif]-->
    
	<link rel="stylesheet" href="/static/button.css?v=${v.v()}">
	<link rel="stylesheet" href="/static/skeleton.css?v=${v.v()}">
	<link rel="stylesheet" href="/static/helpers.css?v=${v.v()}">
	<link rel="stylesheet" href="/static/navigation.css?v=${v.v()}">
	<link rel="stylesheet" href="/static/filter.css?v=${v.v()}">
	<link rel="stylesheet" href="/static/search.css?v=${v.v()}">
	<link rel="stylesheet" href="/static/screenshots.css?v=${v.v()}">
	<link rel="stylesheet" href="../static/objectPage.css?v=${v.v()}">
	<link rel="stylesheet" href="../static/searchBar.css?v=${v.v()}">
	<link rel="stylesheet" href="../static/signUp.css?v=${v.v()}">
	<link rel="stylesheet" href="../static/objectSquare.css?v=${v.v()}">
	<link rel="stylesheet" href="../static/globalColors.css?v=${v.v()}">
	
	<!-- start Mixpanel --><script type="text/javascript">(function(e,b){if(!b.__SV){var a,f,i,g;window.mixpanel=b;a=e.createElement("script");a.type="text/javascript";a.async=!0;a.src=("https:"===e.location.protocol?"https:":"http:")+'//cdn.mxpnl.com/libs/mixpanel-2.2.min.js';f=e.getElementsByTagName("script")[0];f.parentNode.insertBefore(a,f);b._i=[];b.init=function(a,e,d){function f(b,h){var a=h.split(".");2==a.length&&(b=b[a[0]],h=a[1]);b[h]=function(){b.push([h].concat(Array.prototype.slice.call(arguments,0)))}}var c=b;"undefined"!==
	typeof d?c=b[d]=[]:d="mixpanel";c.people=c.people||[];c.toString=function(b){var a="mixpanel";"mixpanel"!==d&&(a+="."+d);b||(a+=" (stub)");return a};c.people.toString=function(){return c.toString(1)+".people (stub)"};i="disable track track_pageview track_links track_forms register register_once alias unregister identify name_tag set_config people.set people.set_once people.increment people.append people.track_charge people.clear_charges people.delete_user".split(" ");for(g=0;g<i.length;g++)f(c,i[g]);
	b._i.push([a,e,d])};b.__SV=1.2}})(document,window.mixpanel||[]);
	mixpanel.init("ee7b279bd12460c6994a778229d5475b");

	</script><!-- end Mixpanel -->
	
	<script src="/static/jquery.js?v=${v.v()}"></script>
	<script src="/static/skeleton.js"></script>
	<script src="/static/objectSquare.js?v=${v.v()}"></script>
	<script src="/static/searchBar.js?v=${v.v()}"></script>
	
	
	%if user:
		<script>mixpanel.identify('${user['email']}');
				mixpanel.people.set({email: '${user['email']}'});
				mixpanel.track('Loaded '+ window.location.pathname, {'referrer': document.referrer});</script>
	%else:
		<script>mixpanel.track('Loaded ' + window.location.pathname, {'referrer': document.referrer});</script>
	%endif
	<title>Rumor2Release</title>
	<meta property="og:title" content="Rumor2Release" />
	<meta property="og:type" content="product" />
	<meta property="og:url" content="http://rumor2release.com" />
	<meta property="og:image" content="http://rumor2release.com/static/images/Icons/masterLogo.png" />
	<meta property="og:site_name" content="rumor2release.com" />
	<meta property="fb:admins" content="1084381295" />
	<meta property="og:description" content="The easiest way to keep track of your favorite digital entertainment" />

	<script type="text/javascript">

	  var _gaq = _gaq || [];
	  _gaq.push(['_setAccount', 'UA-36358352-1']);
	  _gaq.push(['_setDomainName', 'rumor2release.com']);
	  _gaq.push(['_trackPageview']);
	
	  (function() {
	    var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
	    ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
	    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
	  })();
	
	</script>
	
	${next.head()}

</head>

<body>

<%doc>
<div id='feedBack'>
	<div id='tab'>Your thoughts?</div>
	<div id='check'><div id='checkInner'>&#x2713;</div></div>
	<table>
		<tr><td colspan="2" style='text-align:center;'>  We would love to hear from you anytime about anything!</td></tr>
		<tr><td>Email:</td><td><input type='text' name='email' style='width:264px;'
			%if user and 'email' in user:
			value=${user['email']}
			%endif
			 /></td></tr>
		<tr><td>Comment:</td>
			<td><textarea name="comment" rows='4' cols='40' style='font-family: inherit;padding:4px;margin-bottom:5px;width:264px;' ></textarea></td></tr>
		<tr><td></td><td><input id='giveFeedBack' type='submit' name='feedback.submitted' value='Submit' class='btn' onclick='giveFeedBack()'/></td></tr>
	</table>
	
</div>
</%doc>

<div id="toolbar">
	%if user and 'email' in user:
	<div id="floatRight">
		<a href='/manage' style='padding:9px 27px;margin-right:5px;' class='btn
		%if path and path == 'manage':
			active
		%endif
		'>Manage</a>
		<a href='/newsFeed' style='padding:9px 27px;margin-right:5px;' class='btn
		%if path and path == 'newsFeed':
			active
		%endif
		'>News</a>
		<div class='dk_container dk_shown dk_theme_default' style='margin:0px;'>
			<a class='dk_toggle' style='padding:11px 55px 11px 13px;'>
				<div class='dk_label'> ${user['email']} </div>
				<span class="select-icon"></span>
			</a>
			<div class='dk_options' style='width:100%;text-align:center;'><ul class='dk_options_inner'>
				<li><a href="settings">User Settings</a></li>
				<li><a href="track?type=games&filter=515d787105beefd4587b71ce&col=companies">Blog</a></li>
				<li><a href="logout">Logout</a></li>
			</ul></div>
		</div>
	</div>
	%else:
	<div id="floatRight" class="noUser" >
		<a href='/manage' style='padding:9px 27px;margin-right:5px;' class='btn
		%if type == row:
			active
		%endif
		'>Manage</a>
		<a href='/newsFeed' style='padding:9px 27px;margin-right:5px;' class='btn
		%if type == row:
			active
		%endif
		'>News</a>
		%if 1 == 0:
			${signUp.signUp(error = error)}
			${signUp.signUp()}
		<div style='display:inline-block;vertical-align:top;padding:5px 0px 0px 8px;'>or</div>
		%endif
		 <a href='signIn' class='btn' style='padding:9px 27px;vertical-align:top;'>Sign In</a>
	</div>
	%endif
	
	<div id="left">
		<a href="/" id="logoLink" style='padding: 0px;'>
			<img src="/static/images/Icons/masterLogo.png" />
		</a>
	</div>
</div>
	
<div id="container">
	
	<div class='bottom'>
		${next.body()}
	</div>
	
	<footer align=center>
		<!--
		<div id='social' style='padding-top:5px;opacity:.8;'>
			<a href="https://twitter.com/Rumor2Release" class="twitter-follow-button" data-show-count="false">Follow @Rumor2Release</a>
			<div style='width:10px;display:inline-block;'></div>
			<script>!function(d,s,id){var js,fjs=d.getElementsByTagName(s)[0];if(!d.getElementById(id)){js=d.createElement(s);js.id=id;js.src="//platform.twitter.com/widgets.js";fjs.parentNode.insertBefore(js,fjs);}}(document,"script","twitter-wjs");</script>
			<a target='_blank' href="http://pinterest.com/Rumor2Release/" style='padding:0px;border:none;height:26px;'><img src="http://passets-cdn.pinterest.com/images/pinterest-button.png" width="76" height="26" alt="Follow Me on Pinterest" /></a>
			<iframe src="//www.facebook.com/plugins/like.php?href=http%3A%2F%2Fwww.facebook.com%2Fpages%2FRumor2Release%2F421520331247914&amp;send=false&amp;layout=standard&amp;width=450&amp;show_faces=false&amp;action=like&amp;colorscheme=light&amp;font=lucida+grande&amp;height=35&amp;appId=293603617410389" scrolling="no" frameborder="0" style="border:none; height:24px;margin:0px 10px;" allowTransparency="true"></iframe>
		</div>
		-->
		<div>
			<!--
				<a href=''>About Us</a>
			-->
			<a href='/aboutUs' >About Us</a>
		</div>
		
	</footer>
	
</div>

<div class='modalCover transitions' onclick='closeImage()'
		style='width: 100%;
			height: 100%;
			position: absolute;
			left: 0px;
			top: 0px;
			background: #000;
			z-index: 169;
			display:none;
			opacity:0;'>
</div>

<div id="cover"></div>

<script type="text/javascript" src="http://s.skimresources.com/js/36034X946528.skimlinks.js"></script>
<script src="/static/flatUi/js/jquery-ui-1.10.0.custom.min.js"></script>
<script src="/static/flatUi/js/jquery.dropkick-1.0.0.js"></script>
<script src="/static/jquery.query.js?v=${v.v()}"></script>
<script src="/static/jquery.cookie.js?v=${v.v()}"></script>
<script src="../static/flatUi/js/custom_checkbox_and_radio.js"></script>
<script src="../static/flatUi/js/custom_radio.js"></script>
<script src="../static/flatUi/js/jquery.tagsinput.js"></script>
<script src="../static/flatUi/js/bootstrap-tooltip.js"></script>
<script src="../static/flatUi/js/jquery.placeholder.js"></script>
<script src="http://vjs.zencdn.net/c/video.js"></script>
<script src="../static/flatUi/js/application.js"></script>

<script src="/static/objectPage.js?v=${v.v()}"></script>
<script src="/static/youtube.js?v=${v.v()}"></script>
<script src="/static/signUp.js?v=${v.v()}"></script>

${next.scripts()}

<!--[if lt IE 8]>
  <script src="js/icon-font-ie7.js"></script>
  <script src="js/icon-font-ie7-24.js"></script>
<![endif]-->

</body>

<script>(function(){
	var uv=document.createElement('script');
	uv.type='text/javascript';
	uv.async=true;
	uv.src='//widget.uservoice.com/oRzFBTqNd3JR7DeG3ofs7Q.js';
	var s=document.getElementsByTagName('script')[0];
	s.parentNode.insertBefore(uv,s)})()</script>

<script>
UserVoice = window.UserVoice || [];
UserVoice.push(['showTab', 'classic_widget', {
  mode: 'full',
  primary_color: '#9b0000',
  link_color: '#007dbf',
  default_mode: 'support',
  forum_id: 215825,
  tab_label: 'Feedback & Support',
  tab_color: '#9b0000',
  tab_position: 'bottom-right',
  tab_inverted: false
}]);
</script>

</html>