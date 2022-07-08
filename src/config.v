import os
import toml

fn read_config() ScraperConfig {
	cfg := os.read_file(os.resource_abs_path('scraper-conf.toml')) or {
		config_dir := os.config_dir() or {
			cli_fatals([
				"Could not find config directory or scraper-conf.toml!"
				"Check: " + os.resource_abs_path('scraper-conf.toml')
			])
		}
		os.read_file(os.join_path_single(os.join_path(config_dir),"scraper-conf.toml")) or {
			cli_fatals([
				"Could not find scraper-conf.toml!"
				"Check: " + os.join_path_single(os.join_path(config_dir),"scraper-conf.toml")
				"Check: " + os.resource_abs_path('scraper-conf.toml')
			])
		}
	}

	doc := toml.parse_text(cfg) or { 
		cli_fatals([
			"Failed to parse compass-scraper.toml!"
			err.str()
		])
	}

	cookies := doc.value("cookies").as_map().as_strings()

	if cookies.keys() != ["cpsdid","cpssid_cesis_catholic_edu_au","ASP_NET_SessionId","SamlSessionIndex"] {
		cli_fatals([
			"Could not find all required cookies! (check names, then check order)"
			"[\"cpsdid\",\"cpssid_cesis_catholic_edu_au\",\"ASP_NET_SessionId\",\"SamlSessionIndex\"]"
		])
	}

	panel_cfg := doc.value('panel').as_map()
	if panel_cfg.keys() != ['sizes','padding','margin','gap'] {
		cli_fatals([
			"Could not find all required panel configurations! (check names, then check order)"
			"[\"sizes\",\"padding\",\"margin\",\"gap\"]"
		])
	} else {
		if panel_cfg['sizes'] or {
			cli_fatal("Could not find panel size array!")
		}.array().len != 4 {
			cli_fatal("Size entries must be a length of 4!")
		}
	}

	userid := doc.value('advanced.userid').default_to(-1).int()
	if userid == -1 {
		cli_fatal("UserId must be set!")
	}
	user_id_str := userid.str()
	url := doc.value('advanced.url').default_to("-1").string()
	if url == "-1" {
		cli_fatal("URL must be set!")
	}
	origin := doc.value('advanced.origin').default_to("-1").string()
	if origin == "-1" {
		cli_fatal("URL origin must be set!")
	}

	user_agent := doc.value('advanced.user_agent').default_to("-1").string()
	if user_agent == "-1" {
		cli_fatal("User agent must be set!")
	}

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

	return ScraperConfig {
		cookies: cookies
		gap: gap
		margin: margin
		padding: padding
		sizes: sizes
		user_agent: user_agent
		origin: origin
		url: url
		user_id_str: user_id_str
	}
}

struct ScraperConfig {
	cookies map[string]string
	user_agent string
	origin string
	url string
	user_id_str string

	sizes []int
	padding int
	margin int
	gap int
}