import os
import x.json2
import term
import time

import toml

const user_agent = 'Mozilla/5.0 Gecko/20100101 Firefox/99.0'

const (
	horizontal = "│"
	vertical = "―"
)

const cfg = os.read_file('scraper-conf.toml') or {
	println("Could not find scraper-conf.toml!")
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

// get data
// data := os.execute(os.read_file("curl.v.txt")?).output

formatted_date := time.now().get_fmt_date_str(time.FormatDelimiter.hyphen,time.FormatDate.yyyymmdd)
//? 2022-05-03

mut timer := time.StopWatch{}
timer.start()
result := os.execute("curl --silent \'$url\' -X POST -H \'User-Agent: $user_agent\' -H \'Accept: */*\' -H \'Accept-Language: en-US,en;q=0.5\' -H \'Accept-Encoding: gzip, deflate, br\' -H \'Content-Type: application/json\' -H \'X-Requested-With: XMLHttpRequest\' -H \'Origin: $origin\' -H \'DNT: 1\' -H \'Connection: keep-alive\' -H \'Referer: $origin\' -H \'Cookie: cpsdid=${cookies["cpsdid"]}; cpssid_cesis.catholic.edu.au=${cookies["cpssid_cesis_catholic_edu_au"]}; ASP.NET_SessionId=${cookies["ASP_NET_SessionId"]}; SamlSessionIndex=${cookies["SamlSessionIndex"]}\' -H \'Sec-Fetch-Dest: empty\' -H \'Sec-Fetch-Mode: cors\' -H \'Sec-Fetch-Site: same-origin\' -H \'Sec-GPC: 1\' -H \'Pragma: no-cache\' -H \'Cache-Control: no-cache\' -H \'TE: trailers\' --data-raw \'{\"userId\":${user_id_str},\"homePage\":true,\"activityId\":null,\"locationId\":null,\"staffIds\":null,\"startDate\":\"${formatted_date}\",\"endDate\":\"${formatted_date}\",\"page\":1,\"start\":0,\"limit\":25}\' --compressed --output - ")
if result.exit_code != 0 {
	println("curl exited with an error!")
	exit(1)
}
entries := (json2.raw_decode(result.output)?).as_map()["d"] or {
	panic("cannot find root!")
}.arr()
timer.stop()


// sizes = [8, 10, 5, 6]
// padding = 5
// margin = 3
// gap = 0

sizes_arr := panel_cfg['sizes'] or {
	println("Could not find panel size array after reading config!")
	exit(1)
}.array()

mut sizes := []int{}
for s in sizes_arr{
	sizes << s.int()
}
assert sizes.len == 4

padding := panel_cfg['padding'] or {
	println("Could not find panel padding after reading config!")
	exit(1)
}.int()

margin := panel_cfg['margin'] or {
	println("Could not find panel margin after reading config!")
	exit(1)
}.int()

gap := panel_cfg['gap'] or {
	println("Could not find panel gap after reading config!")
	exit(1)
}.int()

//* data
//* panel_cfg

//? TOML READING

term.hide_cursor()
term.clear()
mut maxsize := 0
for ss in 0..sizes.len{
	maxsize += sizes[ss] + gap
}

//? draw padded + margin BOX
for i in padding+1..maxsize+padding+margin*2 {
	term.set_cursor_position(x: i, y: padding)
	print(term.magenta(vertical))
	term.set_cursor_position(x: i, y: padding+sizes.len+margin*2-1)
	print(term.magenta(vertical))
} //* VERTICAL
for i in padding+1..padding+sizes.len+margin*2-1 {
	term.set_cursor_position(x: padding, y: i)
	print(term.magenta(horizontal))
	term.set_cursor_position(x: padding+margin*2+maxsize, y: i)
	print(term.magenta(horizontal))
} //* HORIZONTAL

//? corners!!
term.set_cursor_position(x: padding, y: padding)
print(term.magenta("╭"))
term.set_cursor_position(x: padding+margin*2+maxsize, y: padding)
print(term.magenta("╮"))
term.set_cursor_position(x: padding, y: padding+margin*2+sizes.len-1)
print(term.magenta("╰"))
term.set_cursor_position(x: padding+margin*2+maxsize, y: padding+margin*2+sizes.len-1)
print(term.magenta("╯"))

// ╭――――――――――――――――――╮
// │                  │
// │       box!       │
// │                  │
// ╰――――――――――――――――――╯

//? note to self:
//? with how the data is structured, (i think) it's not possible to do to it in any other way
//? so im sorry if this is a bit ugly

for i, entry in entries {
	mut put := []string{}
	//? format time
	mut first_digit := (entry.as_map()["longTitle"] or {
		panic("cannot find longTitle")
	}.str().split(":")[0].int()-2)
	if first_digit <= 0 {
		first_digit += 12
	}
	second_digit := (entry.as_map()["longTitle"] or {
		panic("cannot find longTitle")
	}.str().split(":")[1])
	mut first_digit_str := first_digit.str()
	if first_digit < 10 {
		first_digit_str = " " + first_digit_str
	}
	formatted_time := first_digit_str + ":" + second_digit
	//? ---- END
	//? ['class','room','teacher']
	event := entry.as_map()["longTitleWithoutTime"] or {
		panic("cannot find longTitleWithoutTime")
	}.str().split(" - ")
	
	put << term.bold(formatted_time)
	put << term.red(event[0])
	put << term.green(event[1])
	put << term.blue(event[2])

	for j, en in put {
		mut ex := 0
		for ss in 0..j{
			ex += sizes[ss] + gap
		}
		term.set_cursor_position(x: (ex+(margin+padding)), y: (i+padding+margin-1))
		print(en)
	}
//	chars << ("│ " + formatted_time + " │ " + event[0] + " │ " + event[1] + " │ " + event[2] + " │")
}

term.set_cursor_position(x: padding+2, y: padding+sizes.len+margin*2)
print(term.bold("↪ $timer.elapsed()"))

term.set_cursor_position(x: 0, y: padding+sizes.len+margin*2+padding-1)
term.show_cursor()