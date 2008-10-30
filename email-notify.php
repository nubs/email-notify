#!/usr/bin/php
<?php
function hypermail_lastid($dir = "/home/anubis/html/email")
{
	exec("ls -r $dir/*html", $ids);
	foreach($ids as $id)
		if(preg_match("/(\d{4,}).html$/", $id, $match))
			return $match[1];
}

$emailfile = '/home/anubis/projects/email-notify/temp.msg';
copy("php://stdin", $emailfile);
exec("/usr/local/bin/hypermail -u -m $emailfile -d /home/anubis/html/email -l Inbox");

foreach(file($emailfile) as $line)
{
	if(!trim($line))
		$headers_over = true;

	if(@$headers_over)
		$body[] = $line;
	else
	{
		if(preg_match("/^\s+/", $line))
		{
			$header = @$prev;
			$value = trim($line);
		}
		else
		{
			preg_match("/^([^:]*):(.*)$/", $line, $matches);
			$prev = $header = strtolower(trim($matches[1]));
			$value = trim($matches[2]);
		}

		if(in_array($header, array('from', 'to', 'cc')))
		{
			$addresses = preg_split("/[,;]/", $value);
			$value = array();

			foreach($addresses as $address)
				if(preg_match("/[^<]+/", $address, $match) || preg_match("/[^<@]+@[^>]+/", $address, $match))
					$value[] = trim($match[0], " '\"");
		}

		$headers[$header] = array_merge(@(array)$headers[$header], (array)$value);
	}
}

$to = 'nubs';
$info = array('<c: 13>email</c>', '<b>' . (in_array(@$headers['from'][0], array('Spencer Rinehart', 'spencer.rinehart@dominionenterprises.com')) ? "TO: " . implode(', ', array_unique(array_merge(@(array)$headers['to'], @(array)$headers['cc']))) : implode(', ', array_unique(@(array)$headers['from']))) . '</b>', '<c: 09>' . implode(' ', @$headers['subject']) . '</c>', sprintf("http://10.67.2.17/email/%04d.html", hypermail_lastid()));

file("http://10.67.34.23/drbplugin_trigger.rb?channel=" . urlencode($to) . "&str=" . urlencode(implode(" :: ", $info)));
?>
