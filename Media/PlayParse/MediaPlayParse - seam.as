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

bool PlayitemCheck(const string &in path)
{
	if (!seamExists) {
		return false;
	}
	// B站
	if (!HostRegExpParse(path, "live.bilibili.com/([0-9]+)").empty()) {
		return true;
	}
	// 抖音
	if (!HostRegExpParse(path, "www.douyu.com/([0-9]+)").empty() || !HostRegExpParse(path, "www.douyu.com/.*?rid=([0-9]+)").empty()) {
		return true;
	}
	// 斗鱼
	if (!HostRegExpParse(path, "live.douyin.com/([0-9]+)").empty()) {
		return true;
	}
	// 虎牙
	if (!HostRegExpParse(path, "huya.com/([a-zA-Z0-9_-]+)").empty()) {
		return true;
	}
	// 快手
	if (!HostRegExpParse(path, "live.kuaishou.com/u/([0-9]+)").empty()) {
		return true;
	}
	// CC
	if (!HostRegExpParse(path, "cc.163.com/([0-9]+)").empty()) {
		return true;
	}
	// 花椒
	if (!HostRegExpParse(path, "www.huajiao.com/l/([0-9]+)").empty()) {
		return true;
	}
	// 艺气山
	if (!HostRegExpParse(path, "www.173.com/([0-9]+)").empty()) {
		return true;
	}
	// 棉花糖
	if (!HostRegExpParse(path, "www.2cq.com/([0-9]+)").empty()) {
		return true;
	}
	// kk
	if (!HostRegExpParse(path, "www.kktv5.com/show/([0-9]+)").empty()) {
		return true;
	}
	// 千帆直播
	if (!HostRegExpParse(path, "qf.56.com/([0-9]+)").empty()) {
		return true;
	}
	// Now 直播
	if (!HostRegExpParse(path, "now.qq.com/pcweb/story.html.*?roomid=([0-9]+)").empty()) {
		return true;
	}
	// 映客
	if (!HostRegExpParse(path, "www.inke.cn/liveroom/index.html.*?uid=([0-9]+)").empty()) {
		return true;
	}
	// afreeca
	if (!HostRegExpParse(path, "afreecatv.com/([a-zA-Z0-9_-]+)").empty()) {
		return true;
	}
	// pandalive
	if (!HostRegExpParse(path, "www.pandalive.co.kr/channel/([a-zA-Z0-9_-]+)").empty() || !HostRegExpParse(path, "www.pandalive.co.kr/live/play/([a-zA-Z0-9_-]+)").empty()) {
		return true;
	}
	// flex
	if (!HostRegExpParse(path, "www.flextv.co.kr/channels/([0-9]+)").empty()) {
		return true;
	}
	// wink
	if (!HostRegExpParse(path, "www.winktv.co.kr/channel/([a-zA-Z0-9_-]+)").empty() || !HostRegExpParse(path, "www.winktv.co.kr/live/play/([a-zA-Z0-9_-]+)").empty()) {
		return true;
	}
	return false;
}

string execSeam(string website, string rid, dictionary &MetaData, array<dictionary> &QualityList) {
	string cmd = "-l " + website + " -i " + rid;
	string json = HostExecuteProgram(seam, cmd);
	JsonReader reader;
	JsonValue root;
	string url;
	if (!reader.parse(json, root) || !root.isObject()) {
		cmd = website + " " + rid;
		json = HostExecuteProgram(seam, cmd);
	}
	log("exec: " + seam + " " + cmd);
	log("json: " + json);
	if (reader.parse(json, root) && root.isObject()) {
		if (root["title"].isString()) {
			MetaData["title"] = root["title"].asString();
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
	string url;
	string rid;

	if (path.find("live.bilibili.com") >= 0) {
		rid = HostRegExpParse(path, "live.bilibili.com/([0-9]+)");
		return execSeam("bili", rid, MetaData, QualityList);
	}
	if (path.find("www.douyu.com") >= 0) {
		rid = HostRegExpParse(path, "www.douyu.com/([0-9]+)");
		if (rid.empty()) {
			rid = HostRegExpParse(path, "www.douyu.com/.*?rid=([0-9]+)");
		}
		return execSeam("douyu", rid, MetaData, QualityList);
	}
	if (path.find("live.douyin.com") >= 0) {
		rid = HostRegExpParse(path, "live.douyin.com/([0-9]+)");
		return execSeam("douyin", rid, MetaData, QualityList);
	}
	if (path.find("huya.com") >= 0) {
		rid = HostRegExpParse(path, "huya.com/([a-zA-Z0-9_-]+)");
		return execSeam("huya", rid, MetaData, QualityList);
	}
	if (path.find("live.kuaishou.com") >= 0) {
		rid = HostRegExpParse(path, "live.kuaishou.com/u/([a-zA-Z0-9_-]+)");
		return execSeam("kuaishou", rid, MetaData, QualityList);
	}
	if (path.find("cc.163.com") >= 0) {
		rid = HostRegExpParse(path, "cc.163.com/([0-9]+)");
		return execSeam("cc", rid, MetaData, QualityList);
	}
	if (path.find("www.huajiao.com") >= 0) {
		rid = HostRegExpParse(path, "www.huajiao.com/l/([0-9]+)");
		return execSeam("huajiao", rid, MetaData, QualityList);
	}
	if (path.find("www.173.com") >= 0) {
		rid = HostRegExpParse(path, "www.173.com/([0-9]+)");
		return execSeam("yqs", rid, MetaData, QualityList);
	}
	if (path.find("www.2cq.com") >= 0) {
		rid = HostRegExpParse(path, "www.2cq.com/([0-9]+)");
		return execSeam("mht", rid, MetaData, QualityList);
	}
	if (path.find("www.kktv5.com") >= 0) {
		rid = HostRegExpParse(path, "www.kktv5.com/show/([0-9]+)");
		return execSeam("kk", rid, MetaData, QualityList);
	}
	if (path.find("qf.56.com") >= 0) {
		rid = HostRegExpParse(path, "qf.56.com/([0-9]+)");
		return execSeam("qf", rid, MetaData, QualityList);
	}
	if (path.find("now.qq.com") >= 0) {
		rid = HostRegExpParse(path, "now.qq.com/pcweb/story.html.*?roomid=([0-9]+)");
		return execSeam("now", rid, MetaData, QualityList);
	}
	if (path.find("www.inke.cn") >= 0) {
		rid = HostRegExpParse(path, "www.inke.cn/liveroom/index.html.*?uid=([0-9]+)");
		return execSeam("inke", rid, MetaData, QualityList);
	}
	if (path.find("afreecatv.com") >= 0) {
		rid = HostRegExpParse(path, "afreecatv.com/([a-zA-Z0-9_-]+)");
		return execSeam("afreeca", rid, MetaData, QualityList);
	}
	if (path.find("www.pandalive.co.kr") >= 0) {
		rid = HostRegExpParse(path, "www.pandalive.co.kr/channel/([a-zA-Z0-9_-]+)");
		if (rid.empty()) {
			rid = HostRegExpParse(path, "www.pandalive.co.kr/live/play/([a-zA-Z0-9_-]+)");
		}
		return execSeam("panda", rid, MetaData, QualityList);
	}
	if (path.find("www.flextv.co.kr") >= 0) {
		rid = HostRegExpParse(path, "www.flextv.co.kr/channels/([0-9]+)");
		return execSeam("flex", rid, MetaData, QualityList);
	}
	if (path.find("www.winktv.co.kr") >= 0) {
		rid = HostRegExpParse(path, "www.winktv.co.kr/channel/([a-zA-Z0-9_-]+)");
		if (rid.empty()) {
			rid = HostRegExpParse(path, "www.winktv.co.kr/live/play/([a-zA-Z0-9_-]+)");
		}
		return execSeam("wink", rid, MetaData, QualityList);
	}
	return url;
}