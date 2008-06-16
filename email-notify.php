#!/usr/bin/php
<?php
$logfile = '/home/anubis/projects/email-notify/logs/' . date('Ymd-His') . '.log';
copy("php://stdin", $logfile);
exec("/usr/local/bin/hypermail -u -m $logfile -d /home/anubis/html/out -l Inbox");
$id = ((int)file_get_contents("/home/anubis/html/out/id")) + 1;
$id_str = sprintf("%04d", $id);
file_put_contents("/home/anubis/html/out/id", $id_str);
foreach(file($logfile) as $line)
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
$info = array('<c: 13>email</c>', @$from, '<c: 09>' . @$subject . '</c>', "http://10.68.4.136/out/$id_str.html");

if(@$to && @count($info))
	file("http://anubis.homelinux.com:8080/drbplugin_trigger.php?channel=" . urlencode($to) . "&str=" . urlencode(implode(' :: ', $info)));
?>
