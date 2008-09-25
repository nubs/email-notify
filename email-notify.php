#!/usr/bin/php
<?php
function hypermail_nextid($dir = "/home/anubis/html/email")
{
	exec("ls -r $dir/*html", $ids);
	foreach($ids as $id)
		if(preg_match("/(\d{4,}).html$/", $id, $match))
			return $match[1] + 1;
}

$emailfile = '/home/anubis/projects/email-notify/temp.msg';
copy("php://stdin", $emailfile);
exec("/usr/local/bin/hypermail -u -m $emailfile -d /home/anubis/html/email -l Inbox");

foreach(file($emailfile) as $line)
{
	if(!trim($line))
		$headers_over = true;

	if(!@$headers_over)
	{
		//TODO: Long subjects, etc wrap to next line with tabs at beginning of line - lets change this to concatenate.
		if(substr($line, 0, 5) == 'From:' && (preg_match('/<([^:<]+@[^>]+)>/', $line, $matches) || preg_match('/([^:<]+@[^>]+)/', $line, $matches)))
			$from = '<b><' . trim($matches[1]) . '></b>';
		if(substr($line, 0, 8) == 'Subject:')
			$subject = trim(substr($line, 8));
	}
}

$to = 'nubs';
$info = array('<c: 13>email</c>', @$from, '<c: 09>' . @$subject . '</c>', sprintf("http://10.68.4.136/email/%04d.html", hypermail_nextid()));

file("http://anubis.homelinux.com:8080/drbplugin_trigger.php?channel=" . urlencode($to) . "&str=" . urlencode(implode(" :: ", $info)));
?>
