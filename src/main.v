fn main(){
	offset := get_day_offset()
	config := read_config()

	mut entries, elapsed := scrape_data(config,offset)
	if entries.len == 0 {
		cli_info("Congrats, nothing on your schedule!")
		exit(0)
	}
	print_cli(entries, config, elapsed)
}