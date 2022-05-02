import toml
import os

const user_agent = 'Mozilla/5.0 (X11; Linux x86_64; rv:99.0) Gecko/20100101 Firefox/99.0'

const cfg = os.read_file('compass-scraper.toml') or {
	println("Could not find compass-scraper.toml!")
	exit(1)
}

doc :=  toml.parse_text(cfg) or { 
	println("Could not parse compass-scraper.toml!")
	println(err)
	exit(1)
}
cookies := doc.value('cookies').as_map().as_strings()
if cookies.keys() != ['cpsdid','cpssid_cesis_catholic_edu_au','ASP_NET_SessionId','SamlSessionIndex'] {
	println("Could not find all required cookies! (check names, then check order)")
	exit(1)
}

panel_cfg := doc.value('panel').as_map()
if panel_cfg.keys() != ['sizes','padding','margin','gap'] {
	println("Could not find all required panel configurations! (check names, then check order)")
	exit(1)
} else {
	if panel_cfg['sizes'] or {
		println("Could not find panel size array!")
		exit(1)
	}.array().len != 4 {
		println("Size entries must be 4!")
		exit(1)
	}
}

userid := doc.value('advanced.userid').default_to(-1).int()
if userid == -1 {
	println("UserId must be set!")
	exit(1)
}
user_id_str := userid.str()

url := doc.value('advanced.url').default_to("-1").string()
if url == "-1" {
	println("URL must be set!")
	exit(1)
}
origin := doc.value('advanced.origin').default_to("-1").string()
if origin == "-1" {
	println("URL origin must be set!")
	exit(1)
}
result := os.execute("curl --silent \'$url\' -X POST -H \'User-Agent: $user_agent\' -H \'Accept: */*\' -H \'Accept-Language: en-US,en;q=0.5\' -H \'Accept-Encoding: gzip, deflate, br\' -H \'Content-Type: application/json\' -H \'X-Requested-With: XMLHttpRequest\' -H \'Origin: $origin\' -H \'DNT: 1\' -H \'Connection: keep-alive\' -H \'Referer: $origin\' -H \'Cookie: cpsdid=${cookies["cpsdid"]}; cpssid_cesis.catholic.edu.au=${cookies["cpssid_cesis_catholic_edu_au"]}; ASP.NET_SessionId=${cookies["ASP_NET_SessionId"]}; SamlSessionIndex=${cookies["SamlSessionIndex"]}\' -H \'Sec-Fetch-Dest: empty\' -H \'Sec-Fetch-Mode: cors\' -H \'Sec-Fetch-Site: same-origin\' -H \'Sec-GPC: 1\' -H \'Pragma: no-cache\' -H \'Cache-Control: no-cache\' -H \'TE: trailers\' --data-raw \'{\"userId\":${user_id_str},\"homePage\":true,\"activityId\":null,\"locationId\":null,\"staffIds\":null,\"startDate\":\"2022-05-02\",\"endDate\":\"2022-05-02\",\"page\":1,\"start\":0,\"limit\":25}\' --compressed --output - ")
if result.exit_code != 0 {
	println("curl exited with an error!")
	exit(1)
}
data := result.output