import term
import os
import strconv
import time
import x.json2

fn cli_info(info string){
	println(term.yellow("INFO: $info"))
}

[noreturn]
fn cli_fatal(error string){
	println(term.red("ERROR: $error"))
	exit(1)
}

[noreturn]
fn cli_fatals(errors []string){
	println(term.red("--- ERROR ---"))
	for error in errors {
		println(term.red(error))
	}
	exit(1)
}

fn get_day_offset() int {
	mut offset := 0
	if os.args.len == 2 {
		offset = strconv.atoi(os.args[1]) or { 
			cli_fatals([
				"Failed to parse day offset!"
				"Usage: ${os.args[0]} -5"
				"Usage: ${os.args[0]} 2"
			])
		}
	}
	return offset
}

const (
	horizontal = "│"
	vertical = "―"
)

fn print_cli(entries []json2.Any, config ScraperConfig, elapsed time.Duration){
	term.hide_cursor()
	term.clear()

	padding := config.padding
	sizes := config.sizes
	margin := config.margin
	gap := config.gap

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
		mut event := entry.as_map()["longTitleWithoutTime"] or {
			panic("cannot find longTitleWithoutTime")
		}.str().split(" - ")

		if event[1].contains("strike") {
			event[1] = event[1].split("; ")[1]
			event[1] = term.yellow(term.bold(term.italic(event[1])))
		}else {
			event[1] = term.green(event[1])
		} // room changes

		if event[2].contains("strike") {
			event[2] = event[2].split("; ")[1]
			event[2] = term.yellow(term.bold(term.italic(event[2])))
		}else {
			event[2] = term.blue(event[2])
		} // teacher changes
		
		put << term.bold(formatted_time)
		put << term.red(event[0])
		put << event[1]
		put << event[2]

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
	print(term.bold("↪ $elapsed"))

	term.set_cursor_position(x: 0, y: padding+sizes.len+margin*2+padding-1)
	term.show_cursor()
}
