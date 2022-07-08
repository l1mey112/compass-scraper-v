import os
import time
import x.json2

fn scrape_data(config ScraperConfig, offset int)([]json2.Any,time.Duration){
	formatted_date := time.now()
		.add_days(offset)
		.get_fmt_date_str(
			time.FormatDelimiter.hyphen,
			time.FormatDate.yyyymmdd
		)
	//? 2022-05-03

	mut timer := time.StopWatch{}
	timer.start()

	result := os.execute("curl --compressed --silent \'$config.url\' -X POST -H \'User-Agent: $config.user_agent\' -H \'Accept: */*\' -H \'Accept-Language: en-US,en;q=0.5\' -H \'Accept-Encoding: gzip, deflate, br\' -H \'Content-Type: application/json\' -H \'X-Requested-With: XMLHttpRequest\' -H \'Origin: $config.origin\' -H \'DNT: 1\' -H \'Connection: keep-alive\' -H \'Referer: $config.origin\' -H \'Cookie: cpsdid=${config.cookies["cpsdid"]}; cpssid_cesis.catholic.edu.au=${config.cookies["cpssid_cesis_catholic_edu_au"]}; ASP.NET_SessionId=${config.cookies["ASP_NET_SessionId"]}; SamlSessionIndex=${config.cookies["SamlSessionIndex"]}\' -H \'Sec-Fetch-Dest: empty\' -H \'Sec-Fetch-Mode: cors\' -H \'Sec-Fetch-Site: same-origin\' -H \'Sec-GPC: 1\' -H \'Pragma: no-cache\' -H \'Cache-Control: no-cache\' -H \'TE: trailers\' --data-raw \'{\"userId\":${config.user_id_str},\"homePage\":true,\"activityId\":null,\"locationId\":null,\"staffIds\":null,\"startDate\":\"${formatted_date}\",\"endDate\":\"${formatted_date}\",\"page\":1,\"start\":0,\"limit\":25}\' --output - ")

	if result.exit_code != 0 {
		cli_fatals([
			"Curl exited with a non-zero error code! (${result.exit_code})"
			result.output
		])
	}
	entries := (json2.raw_decode(result.output) or {
		cli_fatals([
			"Failed to decode data!"
			"err: $err"
			"Returned data may be garbled?"
			"data: $result.output"
		])
	}).as_map()["d"] or {
		cli_fatals([
			"Cannot find root of parsed data!"
			"Returned data may be garbled?"
			"data: $result.output"
		])
	}.arr()
	timer.stop()

	return entries, timer.elapsed()
}