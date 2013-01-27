require 'erb'

CUSTOM = 0
POSTING = 5
WIDE_CUSTOM = 6
RANDOM = 7

LONG = 60
SAY_FULL_NUM = 30
ACTION_FULL_NUM = 30
PRV_LEN = 600
SMALL_VOICE = 'AA'

ALL_DAY_PERIOD = 24 * 60
LIST_WIDTH = 200
USE_GZIP = false
DEBUG = false
DEBUG_SHORT = false
MASTER = "DUMMY"
ADMIN = "euro"

POSTPOS = [
	"�ϡ�",
	"����",
	"��"
]

OPENING = "��ϵ������ϿͤΤդ�򤹤뤳�Ȥ��Ǥ��������ϵ��<br>���ο�ϵ������¼��ʶ�����Ǥ���Ȥ��������ɤ�����Ȥ�ʤ�������ޤ�����<br>¼��ã��Ⱦ��Ⱦ���ʤ���⡢�����˽��ޤä��ä��礤�򤹤뤳�Ȥˤ��ޤ�����"
FOLK_WIN = "���٤Ƥο�ϵ���༣���ޤ�����<br>¿���ε����ξ�ˡ��Ĥ���¼��ʿ�¤�ˬ��ޤ�����"
WOLF_WIN = "�⤦��ϵ���񹳤Ǥ���ۤ�¼�ͤϻĤäƤ��ޤ���<br>��ϵ�ϻĤä�¼�ͤ򤹤٤ƶ��餤�Ԥ����������ʳ�ʪ����Ƥ���¼���äƤ����ޤ�����"
YOKO_WIN_F = "���٤Ƥο�ϵ���༣���ޤ�����<br>¿���ε�����Ť͡��Ĥ���¼��ʿ�¤�ˬ�줿���Τ褦�˸����ޤ�����<br>��������¼�ˤϤޤ����⤬�Ҥä���������ĤäƤ��ޤ�����"
YOKO_WIN_W = "�⤦��ϵ���񹳤Ǥ���ۤ�¼�ͤϻĤäƤ��ޤ���<br>�����Ĥä�¼�ͤ⤹�٤ƿ�ϵ�˽����Ƥ��ޤ��ޤ�����<br>�����������ο�ϵ��ޤ�¼������Ǥ�������ˤ�ä��Ǥܤ���ޤ�����"
LOVE_WIN = "�������ǤϤ��٤ƤΤ�Τ�̵�ϤǤ�����"

RANDOM_MSG = "�ɤ���餳��¼�ˤϡ���ϵ���ꤤ�դ�����1�ͤ��Ĥ���褦�Ǥ�����¾�Ϥ狼��ޤ��󡣥��ߡ����򿦤������Ǥ���"

HEAD1 = <<END
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html lang="ja">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=EUC-JP">
<meta http-equiv="Content-Script-Type" content="text/javascript">
<meta http-equiv="Content-Style-Type" content="text/css">
<link rel="stylesheet" type="text/css" href="plugin/base.css">
<script type="text/javascript" src="plugin/jquery.js"> </script>
<script type="text/javascript" src="plugin/script.js"> </script>
END

HEAD2ED = <<END
</head>
<body onLoad='compChange();'>
END

HEAD2VIL = <<END
</head>
<body onLoad='init();'>
END

HEAD2 = <<END
</head>
<body>
END

FOOT = <<END
</body>
</html>
END

SHOW_UPDATE_SCRIPT = %Q(
<script>
<!--
function showUpdateTimer() {
	var resttimeSpan = document.getElementById("resttime");
	if (!resttimeSpan.innerHTML.match(/([0-9]+)���� ([0-9]+)ʬ ([0-9]+)��/)) {
		return;
	}
	hour = parseInt(RegExp.$1);
	min = parseInt(RegExp.$2);
	sec = parseInt(RegExp.$3);
	sec -= 1;
	if (sec == -1) {
		sec = 59;
		min -= 1;
		if (min == -1) {
			min = 59;
			hour -= 1;
			if (hour == -1) {
            	return;
			}
		}
	}
	resttimeSpan.innerHTML = hour + '���� ' + min + 'ʬ ' + sec + '��';
	setTimeout('showUpdateTimer();', 1000);
}
setTimeout('showUpdateTimer();', 1000);
// -->
</script>
)

def two(n)
	s = n.to_s
	if (s.size < 2)
		'0' + s
	else
	s
	end
end

class String
	def jcut
		if (self =~ /^((.){20})./)
			$1 + '...'
		else
			self
		end
	end
	def acut
		if (self =~ /^((.){50})./)
			$1
		else
			self
		end
	end
	def fortune!
		self.sub!(/\[ayano\]/){
			"<b>#{rand(101)}</b>"
		}
	end
	def vil_url!
		self.sub!(/\[(\d{1,5})¼?\]|http:\/\/(euroz.sakura.ne.jp\/wolf|euros.x0.com)\/index.rb\?vil_id=(\d{1,5})[0-9A-Za-z_=#(&amp;)]*/){
			vil_id = ($1) ? $1 : $3
			%Q(<a href="http://euroz.sakura.ne.jp/wolf/index.rb?vil_id=#{vil_id}#form" class="say" target="_blank">[��ϵ@��Ȥ� #{vil_id}¼]</a>)
		}
	end
end

def announce(str)
	%Q(<!--say--><div class="announce">#{str}</div>\n)
end
def act_announce(str, id)
	%Q(<!--say#{id}--><div class="announce">#{str}</div>\n)
end
def win_announce(str)
	%Q(<!--say--><div class="announce win">#{str}</div>\n)
end
def victim_announce(str)
	%Q(<!--say--><div class="announce whisper">#{str}</div>\n)
end
def execution_announce(str)
	%Q(<!--say--><div class="announce vote">#{str}</div>\n)
end
def dead_announce(str)
	%Q(<!--say--><div class="announce vote">#{str}</div>\n)
end
def whisper_announce(str)
	%Q(<!--whisper--><div class="announce whisper">#{str}</div>\n)
end
def fanatic_announce(str)
	%Q(<!--fanatic--><div class="announce whisper">#{str}</div>\n)
end
def fortune_announce(str, id)
	%Q(<!--think#{id}--><div class="announce fortune">#{str}</div>\n)
end
def fortune_id_announce(str, id)
	%Q(<!--think#{id}--><div class="announce fortune_id">#{str}</div>\n)
end
def guard_announce(str, id)
	%Q(<!--think#{id}--><div class="announce guard">#{str}</div>\n)
end
def safety_announce(str)
	%Q(<!--say--><div class="announce safety">#{str}</div>\n)
end
def spirit_announce(str)
	%Q(<!--sprit--><div class="announce spirit">#{str}</div>\n)
end
def free_announce(str, id)
	%Q(<!--think#{id}--><div class="announce free">#{str}</div>\n)
end
def stigmata_announce(str, id)
	%Q(<!--think#{id}--><div class="announce stigmata">#{str}</div>\n)
end
def gammer_announce(str, id)
	%Q(<!--think#{id}--><div class="announce gammer">#{str}</div>\n)
end
def cupid_announce(str, id = nil)
	if (id)
		%Q(<!--think#{id}--><div class="announce cupid">#{str}</div>\n)
	else
		%Q(<!--say--><div class="announce cupid">#{str}</div>\n)
	end
end
def possessed_announce(str, id)
	%Q(<!--think#{id}--><div class="announce possessed">#{str}</div>\n)
end
def secret_announce(str)
	%Q(<!--think00--><div class="announce">#{str}</div>\n)
end
def time_announce(str)
	%Q(<div class="time_announce">#{str}</div>\n)
end
def alllog_announce(str)
	%Q(<div class="alllog_announce">#{str}</div>\n)
end
def setvote(id, str)
	%Q(<!--think#{id}--><div class="announce vote">#{str}</div>\n)
end
def howl_wolf(howl_filename)
	%Q(<table class="message"><tr><td width="50" rowspan="2"><img src="img/#{howl_filename}.png"></td><td colspan="2" class="howl">ϵ�α��ʤ�</td></tr><tr><td width="16"><img src="img/whisper00.jpg"></td><td width="464"><div class="mes_whisper_body0"><div class="mes_whisper_body1">�浪����</div></div></td></tr></table>\n)
end

def vil_list(v)
	vilid = %Q(<a class="vid" href="?vid=#{v['vid']}&amp;date=0">#{v['vid']}¼</a>)
	if (v['state'] > 2)
		if (v['sname'].jsize > 20)
			sname = %Q(<a href="?vid=#{v['vid']}&amp;date=1&amp;log=all" title="#{v['name']}">#{v['sname']}</a>)
		else
			sname = %Q(<a href="?vid=#{v['vid']}&amp;date=1&amp;log=all">#{v['sname']}</a>)
		end
	else
		if (v['sname'].jsize > 20)
			sname = %Q(<a href="?vid=#{v['vid']}#form" title="#{v['name']}">#{v['sname']}</a>)
		else
			sname = %Q(<a href="?vid=#{v['vid']}#form">#{v['sname']}</a>)
		end
	end

	card = (v['card']) ? 'CARD' : 'BBS'
	comp = Composition.compositions[v['composition']].name
	dummy = (v['dummy']) ? '���ߡ�����' : '���ߡ��ʤ�'
	char = Charset.charsets[v['char']].name
	open_id = (v['open_id']) ? 'ID����' : ''

	start =
	if (v['upstart_time'])
		"#{v['start_hour']}�� #{v['start_min']}ʬ����"
	else
		"��ư����"
	end
	num = (v['state'] == 0) ? "#{v['player_num']}/#{v['entry_max']}��" : "#{v['player_num']}��"

	time =
		if (v['period'] % 60 == 0)
			"��#{v['period'] / 60}����"
		else
			"��#{v['period']}ʬ"
		end
	if (v['night_period'].to_i != 0)
		night_period =
			if (v['night_period'] % 60 == 0)
				"��#{v['night_period'] / 60}����"
			else
				"��#{v['night_period']}ʬ"
			end
		night_period = "(#{night_period}+#{v['life_period']}��*��)" if (v['life_period'].to_i != 0)
		time += "/#{night_period}"
	end
	"<tr><td>#{vilid}</td><td>#{sname}</td><td>#{time}</td><td>#{card}</td><td>#{comp}</td><td>#{dummy}</td><td>#{char}</td><td>#{num}</td><td>#{start}</td><td>#{open_id}</td></tr>"
end

def settarget(player, t_name = nil)
	if(player.sid == 1)
		if(t_name)
			str = "#{player.name} �� #{t_name} �򽱷⤷�ޤ���"
		else
			str = "#{player.name} �Ͻ����о��������ä��ޤ���"
		end
		%Q(<!--think#{player.num_id}--><div class="announce whisper">#{str}</div>\n)
	elsif(player.sid == 2)
		if(t_name)
			str = "#{player.name} �� #{t_name} ���ꤤ�ޤ���"
		else
			str = "#{player.name} ���ꤤ�о��������ä��ޤ���"
		end
		fortune_announce(str, player.num_id)
  elsif(player.sid == 4)
		if(t_name)
			str = "#{player.name} ���������å��򲡤��ޤ�����"
		else
			str = "#{player.name} ���������å�������ޤ�����"
		end
		possessed_announce(str, player.num_id)
	elsif(player.sid == 5 || player.sid == 16)
		if(t_name)
			str = "#{player.name} �� #{t_name} ���Ҥ��ޤ���"
		else
			str = "#{player.name} �ϸ���о��������ä��ޤ���"
		end
		guard_announce(str, player.num_id)
	elsif(player.sid == 11)
		if(t_name)
			str = "#{player.name} �� #{t_name} ����Ȥ��ꤤ�ޤ���"
		else
			str = "#{player.name} ������ꤤ�о��������ä��ޤ���"
		end
		fortune_id_announce(str, player.num_id)
	elsif(player.sid == 13)
		if(t_name)
			str = "#{player.name} �� #{t_name} �˰�����ޤ���"
		else
			str = "#{player.name} �ϵᰦ�о��������ä��ޤ���"
		end
		cupid_announce(str, player.num_id)
	elsif(player.sid == 14)
		if(t_name)
			str = "#{player.name} �� #{t_name} �μ���򤷤ޤ���"
		else
			str = "#{player.name} �ϼ����о��������ä��ޤ���"
		end
		gammer_announce(str, player.num_id)
	end
end

def erbrun(file)
	ERB.new(File.open(file){|f| f.read}).run(binding)
end

def erbres(file)
	ERB.new(File.open(file){|f| f.read}).result(binding)
end
