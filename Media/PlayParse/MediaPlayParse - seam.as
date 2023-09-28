/*
	seam live parse
	author: chen310
	link: https://github.com/chen310/SeamPotPlayer
*/

// void OnInitialize()
// void OnFinalize()
// string GetTitle() 									-> get title for UI
// string GetVersion									-> get version for manage
// string GetDesc()										-> get detail information
// string GetLoginTitle()								-> get title for login dialog
// string GetLoginDesc()								-> get desc for login dialog
// string GetUserText()									-> get user text for login dialog
// string GetPasswordText()								-> get password text for login dialog
// string ServerCheck(string User, string Pass) 		-> server check
// string ServerLogin(string User, string Pass) 		-> login
// void ServerLogout() 									-> logout
//------------------------------------------------------------------------------------------------
// bool PlayitemCheck(const string &in)					-> check playitem
// array<dictionary> PlayitemParse(const string &in)	-> parse playitem
// bool PlaylistCheck(const string &in)					-> check playlist
// array<dictionary> PlaylistParse(const string &in)	-> parse playlist


string seam;
bool seamExists;
bool debug = false;

void OnInitialize() {
	if (debug) {
		HostOpenConsole();
	}
}

string GetTitle() {
	return "seam";
}

string GetVersion() {
	return "1.1";
}

string GetDesc() {
	return "https://github.com/Borber/seam";
}

string GetLoginTitle()
{
	return "请输入 seam.exe 所在位置";
}

string GetLoginDesc()
{
	return "请输入 seam.exe 所在位置";
}

string GetUserText()
{
	return "seam.exe 路径";
}

string GetPasswordText()
{
	return "";
}

string ServerLogin(string User, string Pass)
{
	if (User.empty()) {
		return "路径不可为空";
	}
	seam = User;
	seamExists = HostFileOpen(seam) > 0;
	if (not seamExists) {
		return "该路径无效";
	}
	return "路径设置成功";
}

void log(string item) {
	if (!debug) {
		return;
	}
	HostPrintUTF8(item);
}

array<array<string>> getPatterns() {
	return {
		{"bili", "live.bilibili.com/([0-9]+)"},
		{"douyu", "www.douyu.com/([0-9]+)", "www.douyu.com/.*?rid=([0-9]+)"},
		{"douyin", "live.douyin.com/([a-zA-Z0-9_-]+)"},
		{"huya", "huya.com/([a-zA-Z0-9_-]+)"},
		{"kuaishou", "live.kuaishou.com/u/([a-zA-Z0-9_-]+)"},
		{"cc", "cc.163.com/([0-9]+)"},
		{"huajiao", "www.huajiao.com/l/([0-9]+)"},
		{"yqs", "www.173.com/([0-9]+)"},
		{"mht", "www.2cq.com/([0-9]+)", "www.2cq.com/.*?/([0-9]+)"},
		{"kk", "www.kktv5.com/show/([0-9]+)"},
		{"qf", "qf.56.com/([0-9]+)"},
		{"now", "now.qq.com/pcweb/story.html.*?roomid=([0-9]+)"},
		{"inke", "www.inke.cn/liveroom/index.html.*?uid=([0-9]+)"},
		{"afreeca", "afreecatv.com/([a-zA-Z0-9_-]+)"},
		{"panda", "www.pandalive.co.kr/channel/([a-zA-Z0-9_-]+)", "www.pandalive.co.kr/live/play/([a-zA-Z0-9_-]+)"},
		{"flex", "www.flextv.co.kr/channels/([0-9]+)"},
		{"wink", "www.winktv.co.kr/channel/([a-zA-Z0-9_-]+)", "www.winktv.co.kr/live/play/([a-zA-Z0-9_-]+)"},
	};
}

bool PlayitemCheck(const string &in path)
{
	if (!seamExists) {
		return false;
	}
	array<array<string>> patterns = getPatterns();
	for (uint i = 0; i < patterns.length(); i++) {
		for (uint j = 1; j < patterns[i].length(); j++) {
			if (!HostRegExpParse(path, patterns[i][j]).empty()) {
				return true;
			}
		}
	}
	return false;
}

string execSeam(string website, string rid, dictionary &MetaData, array<dictionary> &QualityList, string path) {
	JsonReader reader;
	JsonValue root;
	string url;
	string json;
	string cmd;
	array<string> cmds = {
		"-l " + website + " -i " + rid + " -a",
		"-l " + website + " -i " + rid,
		website + " " + rid
	};

	for (uint i = 0; i < cmds.length(); i++) {
		cmd = cmds[i];
		json = HostExecuteProgram(seam, cmd);
		if (reader.parse(json, root) && root.isObject()) {
			break;
		}
	}
	log("exec: " + seam + " " + cmd);
	log("json: " + json);
	if (reader.parse(json, root) && root.isObject()) {
		MetaData["vid"] = rid;
		if (root['anchor'].isString() && !root['anchor'].asString().empty()) {
			MetaData["author"] = root['anchor'].asString();
		}
		if (root["title"].isString() && !root['title'].asString().empty()) {
			MetaData["title"] = root["title"].asString();
			MetaData["content"] = root["title"].asString();
		}
		MetaData["webUrl"] = path;
		if (root["cover"].isString() && !root["cover"].asString().empty()) {
			MetaData["thumbnail"] = root["cover"].asString();
		} else if (root["head"].isString() && !root["head"].asString().empty()) {
			MetaData["thumbnail"] = root["head"].asString();
		}
		JsonValue list;
		if (root["nodes"].isArray()) {
			list = root["nodes"];
		} else if (root["urls"].isArray()) {
			list = root["urls"];
		}
		url = list[0]["url"].asString();
		if (@QualityList !is null) {
			for (int i = 0; i < list.size(); i++) {
				JsonValue node = list[i];
				dictionary item;
				url = node["url"].asString();
				item["url"] = url;
				item["quality"] = node["format"].asString();
				item["qualityDetail"] = item["quality"];
				item["itag"] = i + 1;
				QualityList.insertLast(item);
			}
		}
	}
	return url;
}

string PlayitemParse(const string &in path, dictionary &MetaData, array<dictionary> &QualityList) {
	array<array<string>> patterns = getPatterns();
	for (uint i = 0; i < patterns.length(); i++) {
		for (uint j = 1; j < patterns[i].length(); j++) {
			string rid = HostRegExpParse(path, patterns[i][j]);
			if (!rid.empty()) {
				return execSeam(patterns[i][0], rid, MetaData, QualityList, path);
			}
		}
	}
	return path;
}

string post(string url, string data="") {
	string UserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.115 Safari/537.36";
	string Headers = "Referer: https://www.douyin.com\r\n";
	return HostUrlGetStringWithAPI(url, UserAgent, Headers, data, true);
}

array<dictionary> AsianGames() {
	string res = post("https://www.douyin.com/aweme/v1/web/activity/yayun/match?tag=ALL&aid=6383");
	array<dictionary> lives;
	JsonReader Reader;
	JsonValue Root;
	if (res.empty()) {
		return lives;
	}
	array<dictionary> temp;
	if (Reader.parse(res, Root) && Root.isObject()) {
		JsonValue days = Root["data"]["tag_match_info"];
		for (int i = 0; i < days.size(); i++) {
			JsonValue items = days[i]["content_items"];
			for (int j = 0; j < items.size(); j++) {
				JsonValue item = items[j];
				if (item.isObject() && item["room_status"].isInt() && item["room_status"].asInt() == 2) {
					dictionary live;
					live["title"] = item["content_title"].asString();
					live["url"] = "https://live.douyin.com/" + item["web_rid_str"].asString();
					if (item["match_info"]["is_hot"].isBool() and item["match_info"]["is_hot"].asBool()) {
						lives.insertLast(live);
					} else {
						temp.insertLast(live);
					}
				}
			}
		}
		for (uint i = 0; i < temp.length(); i++) {
			lives.insertLast(temp[i]);
		}
	}
	return lives;
}

bool PlaylistCheck(const string &in path) {
	if (path.find("www.douyin.com/asiangames") >= 0) {
		return true;
	}
	return false;
}

array<dictionary> PlaylistParse(const string &in path) {
	array<dictionary> result;
	if (path.find("www.douyin.com/asiangames") >= 0) {
		return AsianGames();
	}
	return result;
}
