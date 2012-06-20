<!DOCTYPE html>
<meta charset='utf-8' />
<link rel='stylesheet' href='../static/css/common.css' type='text/css' />
<link rel='stylesheet' href='../static/css/style.css' type='text/css' />
<title>Globalshake</title>
<div id='center'>
<header>
<h1><img src='../static/img/globalshake.png' alt='Globalshake' /></h1>
</header>
<div class='form large'>
	<form action='search' method='GET'>
	<input id='i_search' type='text' name='q' />
	<input type='submit' value='Search' />
	</form>
</div>
<footer>
<p><?php print_r($tracks); ?> songs in library</p>
</footer>
<script src='../static/js/jquery-1.7.2.min.js'></script>
<script>
	$(document).ready(function(){
		$('#i_search').focus();
	});
</script>
</div>
