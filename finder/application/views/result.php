<?php if (!$ajax) { ?>
<!DOCTYPE html>
<meta charset='utf-8' />
<link rel='stylesheet' href='../static/css/common.css' type='text/css' />
<link rel='stylesheet' href='../static/css/result.css' type='text/css' />
<title>Search Result - Globalshake</title>
<header>
<h1><a href='./'><img src='../static/img/globalshake-s.png' alt='Globalshake' /></a></h1>
<div class='form small'>
	<form action='search' method='GET' id='msearch'>
	<input id='i_search' type='text' name='q' />
	<input type='submit' value='Search' />
	</form>
</div>
</header>
<div id='ajaxtarget'>
<?php } ?>
<dl id='result'>
<?php
$cnt=0;
if ($result) {
foreach ($result as $key => $val) {
++$cnt;
$fragments = explode('/',$val->path);
$path_f = array();
foreach ($fragments as $fragment) {
	$path_f[] = rawurlencode($fragment);
}
$path = implode('/',$path_f);
?>
	<dt>
	<a href='<?php echo $vars['src_base'].$path; ?>' target='mif_link' class='medialink'>
		<?php echo $val->title; ?>
	</a>
		<?php echo $val->subtitle; ?>
	</dt>
	<dd>
		<?php if ($val->artist) echo 'by <span class="artist"><a href="?artist='.rawurlencode($val->artist).'" class="searchlink">'.$val->artist.'</a></span>'; ?>
		<span class='desc'>
			<?php if ($val->album) echo 'from <span class="album"><a href="?album='.rawurlencode($val->album).'" class="searchlink">'.$val->album.'</a></span>'; ?>
			<?php if ($val->year) echo '(<span class="year">'.$val->year.'</span>)'; ?>
		</span>
	</dd>
<?php }} ?>
</dl>
<footer>
<p>[<?php echo $search_algorithm; ?>] found <?php echo $cnt; ?> tracks in <?php echo $this->benchmark->elapsed_time(); ?>sec (memory usage: <?php echo $this->benchmark->memory_usage();?>)</p>
</footer>
<?php if (!$ajax) { ?>
</div>
<div id='player'>
<audio src='' controls>
</div>
<script src='../static/js/jquery-1.7.2.min.js'></script>
<script>
(function(){
	function getContents(uri) {
		$.ajax({
			type:'GET',
			url:uri+'&ajax=1',
			dataType:'html',
			beforeSend:function(){
				$('#ajaxtarget').html('</dt>Loading...</dt><dd></dd>');
			},
			complete:function(){
			},
			success:function(e){
				$('#ajaxtarget').html(e);
				setEvtListener();
			},
			error:function(e){
				$('#ajaxtarget').html('</dt>Error</dt><dd>'+e.status+', '+e.statusText+'</dd>');
			}
		})
	}

	function setEvtListener() {
		$('.medialink').click(function(e){
			$('#player').html("<audio src='"+$(this).attr('href')+"' autoplay controls>");
			e.preventDefault();
			return false;
		});
		$('.searchlink').click(function(e){
			e.preventDefault();
			var search_fragment = location.search.substring(1,location.search.length).split('&');
			var query = {};
			for (idx in search_fragment) {
				var keyvalue = search_fragment[idx].split('=');
				query[keyvalue[0]] = keyvalue[1];
			}
			console.dir(query);
			var uri = './search'+$(this).attr('href');
			getContents(uri);
			history.pushState(null,null,uri);
			console.log(uri);
			return false;
		});
	}
	
	$(document).ready(function(){
		$('#i_search').focus();
		$('#msearch').submit(function(e){
			var uri = './search?q='+encodeURIComponent($('#i_search').val());
			getContents(uri);
			history.pushState(null,null,uri);
			e.preventDefault();
		});
		window.addEventListener('popstate',
			function(e) {
				getContents(location.pathname+location.search);
			}, false
		);
		setEvtListener();
	});
}());
</script>
<?php } ?>
