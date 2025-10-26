<!DOCTYPE html>
<html>
<head>
	<title>Activity/Transponder changes</title>
	<meta name="viewport" content="width=device-width,initial-scale=1">
	<style>
		tr:nth-child(even) {
			background-color: #DBF0F0;
		}
		table {
			border-collapse: collapse;
		}
		td {
			padding: 1px 10px;
		}
	</style>
</head>
<body>
	<h2>Activity collar ID and Transponder ID changes</h2>
	<table><tr><th>Cow</th><th>Activity collar</th><th>Transponder</th><th>Time</th></tr>
<?php
	function changed($old, $new) {
		if($new == $old) {
			return;
		}
		if(strlen($new) == 0) {
			$new = '(none)';
		}
		if(strlen($old) == 0) {
			$old = '(none)';
		}
		return "${old} &rarr; ${new}";
	}
	$db = new SQLite3('data.db');
	$sql = 'SELECT * FROM events ORDER BY timestamp DESC LIMIT 200';
	$result = $db->query($sql);
	while($res = $result->fetchArray(SQLITE3_ASSOC)) {
		$number = $res['number'];
		$act = changed($res['oldactivityid'], $res['newactivityid']);
		$tran = changed($res['oldtransponderid'], $res['newtransponderid']);
		$time = new DateTime($res['timestamp'])->format('M j, Y  g A');
?>
<tr><td><?=$number?></td><td><?=$act?></td><td><?=$tran?></td><td><?=$time?></td></tr>
<?php
	}
?>
	</table>
</body>
</html>
