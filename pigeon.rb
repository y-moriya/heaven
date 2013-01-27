require 'jcode'
$KCODE='e'

require 'cgi'
require 'kconv'
require 'pstore'

require 'util'
require 'player'
require 'vil'
require 'errormsg'
require 'skill'
require 'charset'

STANDARD_AM = 20
MAX_AM = 100
VIL_NUM = 15

class Pigeon
	def initialize
		@cgi = CGI.new()
		@vid = @cgi['vid'].to_i
		if (@vid > 0 && File.exists?("db/vil#{(@vid - 1) / 100}"))
			@vildb = PStore.new("db/vil#{(@vid - 1) / 100}/#{@vid}.db")
		end
	end

	def get_vil_lock(vid)
		v = @vildb.transaction do
			@vildb['root']
		end
		v
	end
	def get_vil(vid)
		v = @vildb['root']
		v
	end

	def handle_end_log
		vldb = PStore.new('db/vil.db')
		state = vldb.transaction do
			return if (!vldb.root?("root#{@vid}"))
			vild = vldb["root#{@vid}"]
			vild['state']
		end
		if (state > 2)
			print_head("#{@vil.vid} #{@vil.name}")
			s = "����¼�Ϥ��Ǥ˽�λ���Ƥ��ޤ���<br>"
			s += %Q(<a href="?userid=#{@esuserid}&pass=#{@pass}">¼����</a>)
			s += "</body></html>"
			print Kconv.tosjis(s)
			exit(0)
		end
	end

	def handle_update
		up_flag = false

		@vil = get_vil_lock(@vid)

		if (!@vil || !File.exists?("db/log#{(@vid - 1) / 100}"))
			print_head
			s = "¸�ߤ��ʤ�¼�Ǥ���<br>"
			s += %Q(<a href="?userid=#{@esuserid}&pass=#{@pass}">¼����</a>)
			s += "</body></html>"
			print Kconv.tosjis(s)
			exit(0)
		end

		if(@vil.death_defeat)
			Skill.skills[1].name = "�Ͷ���"
		end

		if (@vil.state < 3 && @vil.update_time && @vil.update_time < Time.now.to_i)
			@vildb.transaction do
				@vil = get_vil(@vid)
				if (@vil.update_time < Time.now.to_i)
					@vil.update
					up_flag = true
				end
			end
		elsif (@vil.state == 0 && @vil.upstart_time && @vil.upstart_time < Time.now.to_i)
			@vildb.transaction do
				@vil = get_vil(@vid)
				if (@vil.upstart_time < Time.now.to_i && @vil.state == 0 && @vil.players.size <= @vil.entry_max)
					if (@vil.players.size < @vil.entry_min)
						@vil.upstart_time += 24*60*60
					else
						@vil.update_time = @vil.upstart_time
						@vil.update
						up_flag = true
					end
				end
			end
		elsif (@vil.state == 1 && @vil.upreset_time && @vil.upreset_time < Time.now.to_i)
			@vildb.transaction do
				@vil = get_vil(@vid)
				if (@vil.upreset_time < Time.now.to_i)
					@vil.up_upreset_time
				end
			end
		end
		return up_flag
	end

	def handle_vid
		date = (@cgi.key?('date')) ? @cgi['date'].to_i : @vil.date
		log = (@cgi.key?('log')) ? @cgi['log'].to_i : 0
		exid = @cgi['id'].to_i
		id_str = (exid > 0) ? "&id=#{exid}" : ""

		date_all = ''
		for i in 0..@vil.date
			datestr =
			if (i == 0)
				"����"
			else
				"#{i}��"
			end
			if (i == date)
				if (date != 0)
					date_all += %Q(|#{datestr})
				else
					date_all += %Q(#{datestr})
				end
			else
				if (i == 0)
					date_all += %Q(<a href="?vid=#{@vid}&userid=#{@esuserid}&pass=#{@pass}&date=#{i}#{@am_str}" accesskey="3">#{datestr}</a>)
				else
					date_all += %Q(|<a href="?vid=#{@vid}&userid=#{@esuserid}&pass=#{@pass}&date=#{i}#{@am_str}#{id_str}">#{datestr}</a>)
				end
			end
		end
		@player = (@vil.players.key?(@userid)) ? @vil.players[@userid] : nil

		s = %Q(<a name="u" href="#b" accesskey="4">��</a>|)
		s += %Q(<a href="?userid=#{@esuserid}&pass=#{@pass}#{@am_str}" accesskey="2">¼����</a><br>)
		s += "#{@vil.name}<hr>"
		if (date == 0)
			s += date_all + "<hr>"
			s += "������: #{@vil.userid}"
			s+= "<hr>��:"
			if (@vil.period % 60 == 0)
				s += "#{@vil.period / 60}����"
	    	else
				s += "#{@vil.period}ʬ"
			end
			s += " ��:"
			np = @vil.night_period.to_i
			if (np != 0)
				if (np % 60 == 0)
					s += "#{np / 60}����"
				else
					s += "#{np}ʬ"
				end
				if (@vil.life_period)
					s += "<br>��¸��1�ͤ��Ȥ�#{@vil.life_period}���ɲ�"
				end
			else
			 s += "��̵��"
			end

			s += "<hr>���ߡ�"
			if (@vil.dummy)
				s += '����'
			else
				s += '�ʤ�'
				s += (@vil.first_guard) ? '�ʽ�����Ҳ�ǽ��' : '�ʽ�������Բ�ǽ��'
			end
			s += "<br>"
			if (@vil.card)
				s += '�����ɿ�ϵ����'
			else
				s += '�££ӷ���'
			end
			s += "<br>�򿦴�˾"
			if (@vil.hope_skill)
				s += 'ͭ��'
			else
				s += '̵��'
			end
			s += "<br>�륳�ߥå�"
			if (@vil.night_commit)
				s += 'ͭ��'
			else
				s += '̵��'
			end
			s += "<br>ID����"
			if (@vil.open_id)
				s += 'ͭ��'
			else
				s += '̵��'
			end
			s += "<br>�貼����"
			if (@vil.open_skill)
				s += 'ͭ��'
			else
				s += '̵��'
			end

			s += "<hr>����: #{Composition.compositions[@vil.composition].name }<br>"
			s += @vil.display_skill if (@vil.state != 0) && !(@vil.composition == RANDOM && @vil.state < 2)
			s += "<hr>��¸ #{@vil.survivors.size}��<hr>"
			@vil.survivors.each do |p|
				s += %Q(<a href="?vid=#{@vid}&userid=#{@esuserid}&pass=#{@pass}&id=#{p.num_id}#{@am_str}">#{p.name}</a>)
				if (@vil.state > 1 || @vil.open_id || (@vil.open_skill && @player && @player.dead != 0))
					s += %Q(<br>ID: #{p.userid})
				end
				if (@vil.state < 2)
					s += %Q(<br>&lt;#{p.say_cnt}&gt;)
				end
				if (@vil.state == 1 && p.say_remain)
					s += %Q(#{p.say_remain}/#{SAY_FULL_NUM})
				end
				if (@vil.tenko != -1 && p.tenko && p.tenko != -1)
					s += %Q(<br>����#{p.tenko})
				end
				if(@vil.state == 1)
					if (!@vil.card && @vil.date == 2 && p.commit == 0)
						s += %Q(<br>���ߥåȺ�)
					else
						if (p.vote != -1)
							s += %Q(<br>��ɼ��)
						end
					end
				end
				if (@vil.state > 1 || (@vil.open_skill && @player && @player.dead != 0))
					s += %Q(<br>#{Skill.skills[p.sid].name})
					if (p.lovers.size != 0)
						s += %Q(<font color="fuchsia">(����)</font>)
					end
				elsif (@vil.state == 1)
					if (@player)
						if (@player.sid == 2)
							if(p.fortune_t.key?(@player))
								d = p.fortune_t[@player]
								if (p.sid == 1)
									s += %Q(<br><font color="red">#{d}���ܡ�#{Skill.skills[1].name}</font>)
								else
									s += %Q(<br><font color="aqua">#{d}���ܡ��ʹ�</font>)
								end
							end
						elsif (@player.sid == 11)
							if (!@vil.open_id)
								if (p.fortune_id_t.key?(@player))
									s += "<br>ID: #{p.userid}"
								end
							end
						elsif (@player.sid == 16)
							if (p.guard_t.key?(@player))
								s += %Q(<br><font color="green">��ҽ�λ</font>)
							end
						end
					end
				end
				s += "<hr>"
			end
			s += "���� #{@vil.victims.size}��<hr>"
			@vil.victims.each do |p|
				s += %Q(<a href="?vid=#{@vid}&userid=#{@esuserid}&pass=#{@pass}&id=#{p.num_id}#{@am_str}">#{p.name}</a>)
				if (@vil.state > 1 || @vil.open_id || (@vil.open_skill && @player && @player.dead != 0))
					s += %Q(<br>ID: #{p.userid})
				end

				if (@vil.state > 1 || (@vil.open_skill && @player && @player.dead != 0))
					s += %Q(<br>#{Skill.skills[p.sid].name})
					if (p.lovers.size != 0)
						s += %Q(<font color="fuchsia">(����)</font>)
					end
				elsif (@vil.state == 1 && @player)
					if (@player.sid == 2)
						if(p.fortune_t.key?(@player))
							d = p.fortune_t[@player]
							if (p.sid == 1)
								s += %Q(<br><font color="red">#{d}���ܡ�#{Skill.skills[1].name}</font>)
							else
								s += %Q(<br><font color="aqua">#{d}���ܡ��ʹ�</font>)
							end
						end
					elsif (@player.sid == 11)
						if (!@vil.open_id)
							if (p.fortune_id_t.key?(@player))
								s += "<br>ID: #{p.userid}"
							end
						end
					end
				end
				s += "<hr>"
			end
			s += "�跺 #{@vil.executions.size}��<hr>"
			@vil.executions.each do |p|
				s += %Q(<a href="?vid=#{@vid}&userid=#{@esuserid}&pass=#{@pass}&id=#{p.num_id}#{@am_str}">#{p.name}</a>)
				if (@vil.state > 1 || @vil.open_id || (@vil.open_skill && @player && @player.dead != 0))
					s += %Q(<br>ID: #{p.userid})
				end

				if (@vil.state > 1 || (@vil.open_skill && @player && @player.dead != 0))
					s += %Q(<br>#{Skill.skills[p.sid].name})
					if (p.lovers.size != 0)
						s += %Q(<font color="fuchsia">(����)</font>)
					end
				elsif (@vil.state == 1 && @player)
					if (@player.sid == 2)
						if(p.fortune_t.key?(@player))
							d = p.fortune_t[@player]
							if (p.sid == 1)
								s += %Q(<br><font color="red">#{d}���ܡ�#{Skill.skills[1].name}</font>)
							else
								s += %Q(<br><font color="aqua">#{d}���ܡ��ʹ�</font>)
							end
						end
					elsif (@player.sid == 11)
						if (!@vil.open_id)
							if (p.fortune_id_t.key?(@player))
								s += "<br>ID: #{p.userid}"
							end
						end
					elsif (@player.sid == 3)
						if (p.sid == 1)
							s += %Q(<br><font color="red">#{Skill.skills[1].name}</font>)
						else
							s += %Q(<br><font color="aqua">�ʹ�</font>)
						end
					end
				end
				s += "<hr>"
			end
			s += date_all.sub(/ accesskey="3"/, '') + "<hr>"
			s += %Q(<a name="b" href="#u" accesskey="1">��</a>|)
			s += %Q(<a href="?vid=#{@vid}&userid=#{@esuserid}&pass=#{@pass}#{@am_str}#b" accesskey="9">��</a>|)
			s += %Q(<a href="?vid=#{@vid}&userid=#{@esuserid}&pass=#{@pass}#{@am_str}&act=o" accesskey="0">��ư</a>)
		else
			s_log = Array.new
			reg = /<a href="#([a-z]+)(\d+)">[*+-]?\d+<\/a> <a href="\?[^"]+" target="_blank">([^<]+)<\/a> <span class="time">([^<]+)<\/span><\/td><\/tr><tr><td><div class="mes_[^_]+"><\/div><\/td><td width="464"><div class="mes_[^_]+_body0"><div class="mes_[^_]+_body1">(.*)$/
			regsys = /^<!--([a-z]+)\d*--><div class="announce[^"]*">(.*)$/
			regvote = /^<!--[a-z]+\d*--><div class="announce"><table class="vote_t">(.*)$/
			date = @vil.date if (date > @vil.date)
			File.open("db/log#{(@vid - 1) / 100}/#{@vid}_#{date}.html") do |ifile|
				lines = ifile.readlines
				(lines.size - 1).downto(0) do |i|
					line = lines[i]
					if (line =~ /^<!--([a-z]+)(\d*)-->/)
						if (exid != 0)
							next if ($2.to_i != exid)
							next if (@vil.state < 2 && $1 == 'whisperhowl' && (@player == nil || !@player.can_whisper))
						end
						if (@vil.state < 2)
							if ($1 == 'think')
								next if (@player == nil)
								next if (@player.num_id != $2.to_i)
							elsif ($1 == 'whisperhowl')
								next if(@vil.state == 0)
								if (@player == nil || (!@player.can_whisper && (!@vil.open_skill || @player.dead == 0)))
									line = nil
									msg = %Q(<font color="red">ϵ�α��ʤ�<br>�浪����<hr></font>)
								end
							elsif ($1 == 'whisper')
								next if(@vil.state == 0)
								next if (@player == nil)
								next if (!@player.can_whisper && (!@vil.open_skill || @player.dead == 0))
							elsif ($1 == 'groan')
								next if(@vil.state == 0)
								next if (@player == nil)
								next if (@player.dead == 0)
							elsif ($1 == 'sprit')
								next if(@vil.state == 0)
								next if (@player == nil)
								next if (@player.sid != 3)
							elsif ($1 == 'fanatic')
								next if(@vil.state == 0)
								next if (@player == nil)
								next if (!@player.can_whisper && @player.sid != 9)
							end
						end
					end
					if (reg =~ line)
						rtype = $1
						rnm = $2
						rn = $3
						rt = $4
						rm = $5
						rm.gsub!(/<a class="say" href="\?vid=\d+&date=(\d+)&log=all#(\D+)(\d+)" onmouseover="[^"]+" onmouseout="[^"]+">([^<]+)<\/a>/) do
							 %Q(<a href="?vid=#{@vid}&userid=#{@esuserid}&pass=#{@pass}&date=#{$1}&type=#{$2}&nm=#{$3}#{@am_str}">#{$4}</a>)
						end
						rm.gsub!(/<a class="say" [^>]+>([^<]+)<\/a>/) do
							"#{$1}"
						end
						#rm.gsub!(/<div class="loud">/, "(����)<br>")
						rm.gsub!(/<div class="loud">([^<]+)<\/div>/) do
							 "(����)<br><b>#{$1}</b>"
						end
						rm.gsub!(/<\/div>/, '')
						rm.gsub!(/<\/td>/, '')
						rm.gsub!(/<\/tr>/, '')
						rm.gsub!(/<\/table>/, '')
						rm.sub!(/ +$/, '')
						if (rtype == 'whisper' || rtype == 'whisperhowl')
							msg = %Q(<font color="red">*#{rnm} #{rn} #{rt}<br>#{rm}</font><hr>)
						elsif (rtype == 'think')
							msg = %Q(<font color="silver">-#{rnm} #{rn} #{rt}<br>#{rm}</font><hr>)
						elsif (rtype == 'groan')
							msg = %Q(<font color="blue">+#{rnm} #{rn} #{rt}<br>#{rm}</font><hr>)
						else
							msg = "#{rnm} #{rn} #{rt}<br>#{rm}<hr>"
						end
					elsif (regvote =~ line)
						rm = $1
						rm.gsub!(/<td>/, '')
						rm.gsub!(/<tr>/, '')
						rm.gsub!(/<\/td>/, '')
						rm.gsub!(/<\/tr>/, '<br>')
						rm.gsub!(/<\/table>/, '')
						rm.gsub!(/<\/div>/, '')
						msg = "#{rm}<hr>"
					elsif (regsys =~ line)
						rtype = $1
						rm = $2
						#rm.sub!(/ /, '&nbsp;')
						rm.gsub!(/<a class="say" href="\?vid=\d+&date=(\d+)&log=all#(\D+)(\d+)" onmouseover="[^"]+" onmouseout="[^"]+">([^<]+)<\/a>/) do
							 %Q(<a href="?vid=#{@vid}&userid=#{@esuserid}&pass=#{@pass}&date=#{$1}&type=#{$2}&nm=#{$3}#{@am_str}">#{$4}</a>)
						end
						rm.gsub!(/<a class="say" [^>]+>([^<]+)<\/a>/) do
							"#{$1}"
						end
						rm.gsub!(/<span class="act_time">/, '')
						rm.gsub!(/<\/span>/, '')
						rm.gsub!(/<\/div>/, '')
						if (rtype == 'whisper' || rtype == 'fanatic')
							msg = %Q(<font color="red">#{rm}</font><hr>)
						elsif (rtype == 'think' || rtype == 'sprit')
							msg = %Q(<font color="silver">#{rm}</font><hr>)
						else
							msg = "#{rm}<hr>"
						end
					end
					s_log.push(msg)
					next if (@cgi['log'] == 's')
					if (@cgi.key?('type') && @cgi.key?('nm'))
						break if (rtype == @cgi['type'] && rnm == @cgi['nm'])
					elsif (log > 0)
						break if (s_log.size == log + @am)
					else
						break if (s_log.size == @am)
					end
				end
			end
			s_log.reverse!
			log = s_log.size - @am if (@cgi.key?('type') && @cgi.key?('nm'))
			log = s_log.size - @am if (@cgi['log'] == 's')
			ba = (log + @am > s_log.size) ? s_log.size : log + @am
			ne = (log - @am > 0) ? log - @am : 0

			s_time = ''
			if (@vil.date == date && @vil.update_time && @vil.state == 1)
				if (@vil.period < LONG)
					t = Time.at(@vil.update_time) - Time.now
					if (t > 0)
						dt = Time.at(t)
						hour = dt.to_i / 3600
						s_time += %Q(<font color="red">#{hour}���� #{dt.min}ʬ #{dt.sec}��)
						if (@vil.night_commit && @vil.night)
							s_time += "�塢�ޤ���ǽ�ϼ���������ư����ꤹ��й�������ޤ���</font>"
						else
							s_time += "��˹�������ޤ���</font>"
						end
					else
						s_time += %Q(<font color="red">�������֤򤹤Ǥ˲᤮�Ƥ��ޤ���</font>)
					end
				else
					ts = Time.at(@vil.update_time)
					s_time += %Q(<font color="red">����¼�ϡ�#{ts.mon}�� #{ts.day}�� #{ts.hour}�� #{ts.min}ʬ�˹�������ޤ���</font>)
				end
			elsif (@vil.upstart_time && @vil.state == 0)
				ts = Time.at(@vil.upstart_time)
				s_time += %Q(<font color="red">����¼�ϡ�#{ts.mon}�� #{ts.day}�� #{ts.hour}�� #{ts.min}ʬ�� #{@vil.entry_min}�Ͱʾ夤��г��Ϥ���ޤ���</font>)
			elsif (@vil.date == date && @vil.update_time && @vil.state == 2)
				ts = Time.at(@vil.update_time)
				s_time += %Q(<font color="red">����¼�ϡ�#{ts.mon}�� #{ts.day}�� #{ts.hour}�� #{ts.min}ʬ�˽�λ���ޤ���</font>)
			end

			info_str = ""
			if(@player)
				if(!@player.sid)
					sn = -1
				else
					sn = @player.sid
				end
				if (sn == -1)
					s_str = "���ޤ���"
				elsif (sn == -2)
					s_str = "������"
				else
					s_str = Skill.skills[sn].name
				end
				if (@vil.state == 0)
					s_str += "���˾"
				end
				info_str += "#{@player.name}(#{s_str})"
				info_str += " ��˾��̵���Ǥ���" if (!@vil.hope_skill && @vil.state == 0)
				if (@vil.state > 1)
					if (@player.win == 0)
						info_str += %Q(<br><font color="red">���ʤ��Ͼ������ޤ�����</font>)
					else
						info_str += %Q(<br><font color="blue">���ʤ������̤��ޤ�����</font>)
					end
				elsif (@player.lovers.size > 0)
					@player.lovers.each do |p|
						info_str += %Q(<br><font color="fuchsia">���ʤ��� #{p.name} �Ȱ�����äƤ��ޤ���</font>)
					end
				end
			end

			s += date_all + "<hr>"
			s += "#{s_log[0, @am]}"
			s += s_time + "<hr>" if (s_time != '')
			s += date_all.sub(/ accesskey="3"/, '') + "<hr>"
			s += info_str + "<br>"
			s += %Q(<a name="b" href="#u" accesskey="1">��</a>|)
			s += %Q(<a href="?vid=#{@vid}&userid=#{@esuserid}&pass=#{@pass}&date=#{date}&log=#{ba}#{@am_str}#{id_str}" accesskey="5">��</a>|)
			s += %Q(<a href="?vid=#{@vid}&userid=#{@esuserid}&pass=#{@pass}&date=#{date}&log=#{ne}#{@am_str}#{id_str}" accesskey="6">��</a>|)
			s += %Q(<a href="?vid=#{@vid}&userid=#{@esuserid}&pass=#{@pass}&date=#{date}&log=s#{@am_str}#{id_str}" accesskey="7">��</a>|)
			s += %Q(<a href="?vid=#{@vid}&userid=#{@esuserid}&pass=#{@pass}&date=#{date}#{@am_str}#{id_str}#b" accesskey="8">��</a>|)
			s += %Q(<a href="?vid=#{@vid}&userid=#{@esuserid}&pass=#{@pass}#{@am_str}#b" accesskey="9">��</a>|)
			s += %Q(<a href="?vid=#{@vid}&userid=#{@esuserid}&pass=#{@pass}#{@am_str}&act=o" accesskey="0">��ư</a>|)
			s += %Q(<a href="?vid=#{@vid}&userid=#{@esuserid}&pass=#{@pass}#{@am_str}&con=o" accesskey="*">��</a>)
		end

		print NKF.nkf('-xsE', s)
	end

	def handle_entry
		pid = @cgi['pid'].to_i
		msg = @cgi['message']
    v_pass = @cgi['v_pass']
		skill = @cgi['skill'].to_i

		return if (!@login)
		return if (!msg || msg == '')

		msg = Kconv.toeuc(msg)
		msg = CGI.escapeHTML(msg)
		msg.gsub!(/\r\n/, '<br>')
		msg.gsub!(/[\r\n]/, '<br>')
		msg.gsub!(/^ +$/, '��')

		num_char = 1

		@vildb.transaction do
			vil = get_vil(@vid)

			return if (vil.players.key?(@userid))
			return if (vil.state != 0)
			return if (vil.players.size >= vil.entry_max)
      return if (vil.pass != v_pass)

			ps = vil.players.values.select {|p| p.pid == pid}

			if (!vil.num_char[pid])
				vil.num_char[pid] = 1
			end

			for i in 1..(ps.size + 1)
				if (ps.all? {|p| p.num_char != i})
					num_char = i

					for j in (num_char + 1)..(ps.size + 2)
						if (ps.all? {|p| p.num_char != j})
							vil.num_char[pid] = j
							break
						end
					end
					break
				end
			end

			if (@userid != MASTER)
				player = Player.new(pid, @userid, vil.num_id, skill, Charset.charsets[vil.char].char_names[pid], num_char)
				vil.num_id += 1
			else
				vil.dummy = true
				player = Player.new(pid, @userid, 1, skill, Charset.charsets[vil.char].char_names[pid], num_char)
			end

			vil.add_player(player)

			type = 'say'
			s = announce("#{player.name} ��������ˬ��ޤ�����")
			vil.say_cnt[type] = vil.say_cnt[type] + 1
			cnt = vil.say_cnt[type]
			s += vil.say(type, cnt, player, msg, player.userid)
			vil.addlog(s)
		end
		@f_success = true
	end

	def print_head(title = nil)
		@headered = true
		print Kconv.tosjis("Content-Type: text/html; charset=Shift_JIS\n\n")

		head = %Q(<html><head><meta http-equiv="pragma" content="no-cache"><meta http-equiv="cache-control" content="no-cache">)
		if (title)
			head += "<title>����ŷ�� #{title}</title>"
		else
			head += "<title>����ŷ��</title>"
		end
		head += "</head><body>"
		print Kconv.tosjis(head)
	end

	def print_foot
		print Kconv.tosjis("</body></html>")
	end

	def print_body(s)
		print Kconv.tosjis(s)
	end

	def handle_index
		show = Array.new
		vldb = PStore.new('db/vil.db')
		vldb.transaction do
			if (vldb.root?('recent_vid'))
				for i in 1..vldb['recent_vid']
					return if (!vldb.root?("root#{i}"))
					vild = vldb["root#{i}"]
					if (vild['state'] == 2 && File.exists?("db/vil#{(i - 1) / 100}/#{i}.db"))
						show.push(i)
					end
				end
			end
		end
		show.each do |i|
			@vid = i
			@vildb = PStore.new("db/vil#{(@vid - 1) / 100}/#{@vid}.db")
			handle_update
		end

		showdown = Array.new
		progress = Array.new
		preinitiation = Array.new
		vldb = PStore.new('db/vil.db')
		vldb.transaction do
			break if (!vldb['recent_vid'])
			recent_vid = vldb['recent_vid'].to_i
			(recent_vid).downto(1) do |i|
				next if (!vldb.root?("root#{i}"))
				vild = vldb["root#{i}"]
				next if (vild['state'] > 2)
				if (vild['state'] == 2)
					showdown.push(%Q(#{i}¼ <a href="?userid=#{@esuserid}&pass=#{@pass}&vid=#{i}#{@am_str}#b">#{vild['sname']}</a><br>))
				elsif (vild['state'] == 1)
					progress.push(%Q(#{i}¼ <a href="?userid=#{@esuserid}&pass=#{@pass}&vid=#{i}#{@am_str}#b">#{vild['sname']}</a><br>))
				else
					preinitiation.push(%Q(#{i}¼ <a href="?userid=#{@esuserid}&pass=#{@pass}&vid=#{i}#{@am_str}#b">#{vild['sname']}</a><br>))
				end
			end
		end

		s = ''
		vlist = Array.new
		vlist = preinitiation.unshift("�� �罸��<br>") + progress.unshift("�� �ʹ���<br>") + showdown.unshift("�� ����<br>")
		first = @cgi['first'].to_i
		last = (first + VIL_NUM > vlist.size) ? vlist.size : first + VIL_NUM
		for i in first...last do
			s += vlist[i]
		end
		if (first != 0)
			f = (first - VIL_NUM < 0) ? 0 : first - VIL_NUM
			s += %Q(<a href="?userid=#{@esuserid}&pass=#{@pass}&first=#{f}" accesskey="1">����</a> )
		end
		if (last != vlist.size)
			s += %Q(<a href="?userid=#{@esuserid}&pass=#{@pass}&first=#{first + VIL_NUM}" accesskey="2">����</a>)
		end
		print Kconv.tosjis(s)
	end

	def handle_vote
		v = @cgi['vote_id'].to_i
		d = @cgi['set_date'].to_i
		return if (!@login)

		@vildb.transaction do
			vil = get_vil(@vid)
			return if(vil.state != 1)
			return if(vil.night)
			return if (d != vil.date)
			player = (vil.players.key?(@userid)) ? vil.players[@userid] : nil
			return if (!player)
			player.vote = v
			if (v == -1)
				str = "#{player.name} ����ɼ����ä��ޤ�����"
			else
				str = "#{player.name} �� #{vil.player_p(v).name} ����ɼ���ޤ�����"
			end
			vil.addlog(setvote(player.num_id, str))
			if (!vil.pids.find { |p| p.vote == -1 })
        		if (vil.update_time && vil.update_time > Time.now.to_i)
					vil.update_time = Time.now.to_i
					vil.update
				end
			end
		end
		@f_success = true
	end

	def handle_skill
		t = @cgi['target_id'].to_i
		d = @cgi['set_date'].to_i
		return if (!@login)

		@vildb.transaction do
			vil = get_vil(@vid)
			return if(vil.state != 1)
			return if (d != vil.date)
			player = (vil.players.key?(@userid)) ? vil.players[@userid] : nil
			return if(!player)
			return if(player.dead != 0)
			target_p = vil.player_p(t)
			return if(t != -1 && (!target_p || target_p.dead != 0))
			if (player.sid == 12)
				t2 = @cgi['target_id2'].to_i
				if (t == t2 || t == -1 || t2 == -1)
					str = "#{player.name} ��������о��������ä��ޤ���"
					player.target = -1
					player.target2 = -1
				elsif
					str = "#{player.name} �� #{vil.player_p(t).name} �� #{vil.player_p(t2).name} �˰���������ޤ���"
					player.target = t
					player.target2 = t2
				end
				vil.addlog(cupid_announce(str, player.num_id))
      elsif (player.sid == 4)
				player.target = t
				if (t == -1)
					str = settarget(player)
				else
					str = settarget(player, true)
				end
				vil.addlog(str)
			else
				player.target = t
				if (t == -1)
					str = settarget(player)
				else
					str = settarget(player, vil.player_p(t).name)
				end
				vil.addlog(str)
			end
			if (vil.night_commit && !vil.skill_pids.find { |p| p.target == -1 })
        		if (vil.update_time && vil.update_time > Time.now.to_i && vil.night)
					vil.update_time = Time.now.to_i
					vil.update
				end
			end
		end
		@f_success = true
	end

	def handle_exit
		id = @cgi['exit_id'].to_i
    	@vildb.transaction do
			vil = get_vil(@vid)
			p = vil.player_p(id)

			return if (!p)
			return if (vil.state != 0)

			if (p.userid == MASTER)
				vil.dummy = false
			end

			if (p.num_char < vil.num_char[p.pid])
				vil.num_char[p.pid] = p.num_char
			end
			s = announce("#{p.name} ��¼����ޤ�����")
			vil.addlog(s)
			vil.players.delete(p.userid)

			vldb = PStore.new('db/vil.db')
			vldb.transaction do
				vild = vldb["root#{@vid}"]
				vild['player_num'] = vil.players.size
				vild['dummy'] = vil.dummy
			end
		end
		@f_success = true
	end

	def handle_commit
		v = @cgi['commit_value'].to_i
		return if (!@login)
		@vildb.transaction do
			vil = get_vil(@vid)
			return if(vil.night)
			return if (vil.date != 2 || vil.card || vil.state != 1)
			player = (vil.players.key?(@userid)) ? vil.players[@userid] : nil
			return if(!player)
			player.commit = v
			if (v == -1)
				str = "#{player.name} �����֤�ʤ�����ä��ޤ�����"
			else
				str = "#{player.name} �����֤�ʤ������򤷤ޤ�����"
			end
			vil.addlog(setvote(player.num_id, str))

			if (!vil.pids.find { |p| p.commit == -1 && p.userid != MASTER})
				if (vil.update_time && vil.update_time > Time.now.to_i)
					vil.pids.each { |p| p.commit = 0}
					vil.update
				end
			end
		end
		@f_success = true
	end

	def handle_cmd
		cmd = @cgi['cmd']
		cmd = 'msg' if (cmd == 'prv')
		if (@vid != 0 && handle_update)
			if (cmd == 'msg')
				handle_message
			end
		else
			if (cmd == 'entry')
				handle_entry
			elsif (cmd == 'msg')
				handle_message
			elsif (cmd == 'vote')
				handle_vote
			elsif (cmd == 'skill')
				handle_skill
			elsif (cmd == 'exit')
				handle_exit
			elsif (cmd == 'commit')
				handle_commit
			elsif (cmd == 'cancel')
				@f_success = true
			end
		end
	end

	def handle_prv
		msg = @cgi['message']
		type = 'say'
		return false if (@cgi['think'] == 'on' || @cgi['groan'] == 'on')
		return false if (!msg || msg == '')
		msg.gsub!(/#{"\x1B+[\x21-\x7A]+\x0F"}|#{"[\xF8\x9F-\xF9\xFC]"}|#{"[\xF3\x40-\xF4\x8E]"}/s, '')
		j_data = @cgi['j_data']
		j_code = NKF.guess(j_data)
		opt =
			if (j_code == NKF::JIS)
				'-xeJ'
			elsif (j_code == NKF::EUC)
				'-xeE'
			elsif (j_code == NKF::SJIS)
				'-xeS'
			elsif (j_code == NKF::UTF8)
				'-xeW'
			elsif (j_code == NKF::UTF16)
				'-xeW16'
			else
				'-xe'
			end
		msg = NKF.nkf(opt, msg)
		len = PRV_LEN
		@val_msg = msg[0..len]
		if (@val_msg == "")
			@val_msg = "��"
			cut = ""
		else
		    if (/.\z/ !~ @val_msg)
		        @val_msg[-1,1] = ''
				cut = msg[len..-1]
			else
				cut = msg[(len + 1)..-1]
		    end
		end
		str = CGI.escapeHTML(@val_msg)
		@val_msg = CGI.escape(@val_msg)
		str.gsub!(/\r\n/, '<br>')
		str.gsub!(/[\r\n]/, '<br>')
		str.gsub!(/^ +$/, '��')
		str = "��" if (str == "")
		if (@cgi['loud'] == 'on')
			str = "(����)<br>#{str}"
		end
		if (cut)
			cut = CGI.escapeHTML(cut)
			cut.gsub!(/\r\n/, '<br>')
			cut.gsub!(/[\r\n]/, '<br>')
			str += %Q(<font color="silver">#{cut}</font>)
		end

		vil = get_vil_lock(@vid)
		return false if (!vil)
		return false if (vil.state != 1)
		return false if (!(vil.period >= LONG && vil.state == 1))
		return false if (!@login)
		@player = (vil.players.key?(@userid)) ? vil.players[@userid] : nil
		return false if (!@player)
		type = 'say'
		cnt = vil.say_cnt[type] + 1
		name = @player.name
		day = Time.now
		timestr = day.strftime("%Y/%m/%d %X")
		@prv_str = "#{cnt} #{name} #{timestr}<br>#{str}"
		return true
	end

	def handle_message
		msg = @cgi['message']
		guest = (@cgi['guest'] == 'on')
		type =
			if (@cgi['think'] == 'on')
				'think'
			elsif (@cgi['whisper'] == 'on')
				'whisper'
			elsif (@cgi['groan'] == 'on')
				'groan'
			elsif (@cgi['action'] == 'on')
				'action'
			else
				'say'
			end

		return if (!msg || msg == '')
		msg.gsub!(/#{"\x1B+[\x21-\x7A]+\x0F"}|#{"[\xF8\x9F-\xF9\xFC]"}|#{"[\xF3\x40-\xF4\x8E]"}/s, '')

		j_data = @cgi['j_data']
		j_code = NKF.guess(j_data)
		opt =
			if (j_code == NKF::JIS)
				'-xeJ'
			elsif (j_code == NKF::EUC)
				'-xeE'
			elsif (j_code == NKF::SJIS)
				'-xeS'
			elsif (j_code == NKF::UTF8)
				'-xeW'
			elsif (j_code == NKF::UTF16)
				'-xeW16'
			else
				'-xe'
			end
		msg = NKF.nkf(opt, msg)
		msg = CGI.unescape(msg) if (@cgi['prv'] == 'on')
		msg = msg.acut if (type == 'action')
		msg = CGI.escapeHTML(msg)
		msg.gsub!(/\r\n/, '<br>')
		msg.gsub!(/[\r\n]/, '<br>')
		msg.gsub!(/^ +$/, '��')
		msg = "��" if (msg == "")

		@vildb.transaction do
			vil = get_vil(@vid)
			return if (vil.state > 2)

			if (@login)
				if (@cgi['loud'] == 'on')
					msg = "<div class=\"loud\">#{msg}</div>"
				end
				if (!guest)
					player = (vil.players.key?(@userid)) ? vil.players[@userid] : nil
					return if(!player)

					if (player.dead != 0 && type == 'say')
						type = 'groan'
					end
					if (player.dead == 0 && type == 'groan')
						type = 'think'
					end
					if (vil.night && type == 'say' && vil.state == 1)
						type = 'think'
					end
					if (player.dead != 0 && type == 'whisper')
	          			type = 'think'
	        		end
					if (vil.state != 1 && type == 'whisper')
	          			type = 'think'
	        		end
					if (vil.card && !vil.night && type == 'whisper')
	          			type = 'think'
	        		end
					if (vil.period >= LONG && vil.state == 1 && type == 'say')
						return if (player.say_remain == 0)
						player.say_remain -= 1
					end

					if (type == 'action')
						return if (vil.date != @cgi['set_date'].to_i)
						return if (player.dead != 0 || vil.night)
						postpos = POSTPOS[@cgi['postpos'].to_i]
						postpos = "" if (postpos == "��")
						if (@cgi['action_id'] != "")
							p = vil.player_p(@cgi['action_id'].to_i)
							return if(!p)
							msg = postpos + p.name + msg
						else
							msg = postpos + msg
						end
						if (vil.period >= LONG && vil.state == 1)
							return if (player.action_remain == 0)
							player.action_remain -= 1
						end
						s = vil.say_action(player, msg)
						vil.addlog(s)
						@f_success = true
					else
						vil.say_cnt[type] = vil.say_cnt[type] + 1
						cnt = vil.say_cnt[type]
						s = vil.say(type, cnt, player, msg, @userid)
						vil.addlog(s)
						@f_success = true
					end
				else
					if (vil.state == 1)
						type = 'groan'
					end
					vil.say_cnt[type] = vil.say_cnt[type] + 1
					cnt = vil.say_cnt[type]
					s = vil.say(type, cnt, nil, msg, @userid)
					vil.addlog(s)
					@f_success = true
				end
			end
        end
	end

	def form_conf
		s = %Q(#{@vid}¼ #{@vil.name}<hr>���٤�ɽ��������ο�<br><form method="get" action="pigeon.cgi">)
		s += %Q(<input type="hidden" name="userid" value="#{@userid}"><input type="hidden" name="pass" value="#{@pass}"><input type="hidden" name="vid" value="#{@vid}">)
		s += %Q(<input name="am" value="#{@am}" istyle="4" size="3" type="text"><br>)
		s += %Q{<input type="submit" value="����"></form><br>�ʺ���#{MAX_AM})}
		print Kconv.tosjis(s)
	end

	def form_login
		s = ''
		print_head
		s += %Q(<form method="get" action="pigeon.cgi">)
		s += "����ŷ��<hr>"
		s += %Q(ID:<br><input type="text" name="userid" size="10" istyle="3"><br>)
		s += %Q(PASS:<br><input type="text" name="pass" size="10" istyle="3"><br><input type="submit" value="������"></form>)
		s += "</body></html>"
		print Kconv.tosjis(s)
	end

  def form_link
    url = CGI.unescape(@cgi['url'])
    s = %Q(������<hr>���������ȡ�#{url}�ˤذ�ư���ޤ�<br>���Ȥ��η���ü���Ǥ�ɽ�������줿�ꡢ�Ǹ�ޤ�ɽ������ʤ��ä��ꤷ�ޤ�<br>Google Mobile Proxy��Ȥ����Ȥǡ������Ȥ���Ӹ������Ѵ����뤳�Ȥ��Ǥ��ޤ�<br>�������С����Υ�󥯤򲡤��Ƥ�������<hr>��<a href=\"#{url}\">���Τޤޥ�����</a><br>��<a href=\"http://www.google.co.jp/gwt/n?u=#{CGI.escape(url)}\">Google Mobile Proxy</a><HR>)
		print Kconv.tosjis(s)
  end

	def form_act
		s = %Q(#{@vid}¼ #{@vil.name}<hr>)
		str_post = %Q(<form method="post" action="pigeon.cgi"><input type="hidden" name="userid" value="#{@userid}"><input type="hidden" name="pass" value="#{@pass}"><input type="hidden" name="vid" value="#{@vid}">#{@am_inp})
		skill_post = str_post + %Q(<input type="hidden" name="set_date" value="#{@vil.date}"><input type="hidden" name="cmd" value="skill">)
		str_post += %Q(<input type="hidden" name="j_data" value="���ܸ�">)
		@player = (@vil.players.key?(@userid)) ? @vil.players[@userid] : nil
		if (!@player)
			if (@vil.state == 0)
				s += str_post
				s += %Q(<input type="hidden" name="cmd" value="entry">)
				s += %Q(����饯������<select name="pid">)
				c_names = Charset.charsets[@vil.char].char_names
				if (@userid != MASTER)
					for i in 1...c_names.size do
						n = (@vil.num_char[i].to_i < 2) ? c_names[i] : (c_names[i] + @vil.num_char[i].to_s)
						s += %Q(<option value="#{i}">#{n}</option>)
						s += "\n"
					end
				else
					n = (@vil.num_char[0].to_i < 2) ? c_names[0] : (c_names[0] + @vil.num_char[0].to_s)
					s += %Q(<option value="#{0}">#{n}</option>)
					s += "\n"
				end
				s += "</select><br>"
				s += %Q(��˾�򿦡�<select name="skill">)
				if (@userid != MASTER)
					s += "<option value = -1>���ޤ���"
					s += "<option value = -2>������"
					for i in 0...Skill.skills.size
						s += %Q(<option value="#{i}">#{Skill.skills[i].name}\n)
						s += "\n"
					end
				else
					s += %Q(<option value="#{0}">#{Skill.skills[0].name}</option>)
					s += "\n"
				end
				s += "</select><br>"
        s += %Q(�ѥ���ɡ�<input name="v_pass" size="10"><br>)
				s += %Q(<textarea rows=3 cols=30 name="message"></textarea><br>)
				s += %Q(<input type="submit" value="����ȥ꡼">)
				s += "</form>"
			end
		else
			if(!@player.sid)
				sn = -1
			else
				sn = @player.sid
			end
			if (sn == -1)
				s_str = "���ޤ���"
			elsif (sn == -2)
				s_str = "������"
			else
				s_str = Skill.skills[sn].name
			end
			if (@vil.state == 0)
				s_str += "���˾"
			end
			s += "#{@player.name}(#{s_str})"
			s += " ��˾��̵���Ǥ���" if (!@vil.hope_skill && @vil.state == 0)

			if(@vil.state == 1 && @vil.night == false && @player.dead == 0)
				s += str_post
				if (!(!@vil.card && @vil.date == 2))
					s += %Q(<input type="hidden" name="cmd" value="vote">)
					s += %Q(<input type="hidden" name="set_date" value="#{@vil.date}">)
					s += "��ɼ��"
					s += %Q(<select name="vote_id">)
					if (@player.vote == -1)
						s += "<option value = -1>̤���� *"
					else
						s += "<option value = -1>����󥻥�"
					end
					@vil.pids.each do |p|
						next if (p == @player)
						i = p.num_id
						if (@player.vote == i)
							s += %Q(<option value = "#{i}" selected>#{p.name} *)
						else
							s += %Q(<option value = "#{i}">#{p.name})
						end
						s += "\n"
					end
					s += %Q(</select><input type="submit" value="�ѹ�">)
				else
					s += %Q(<input type="hidden" name="cmd" value="commit">)
					s += "���ߥåȡ�"
					s += %Q(<select name="commit_value">)
					if (@player.commit == -1)
						s += "<option value = -1>̤���� *"
						s += "<option value = 0>���֤�ʤ��"
					else
						s += "<option value = 0>���֤�ʤ�� *"
						s += "<option value = -1>����󥻥�"
					end
					s += %Q(</select><input type="submit" value="�ѹ�">)
				end
				s += "</form>"
			end

			if (!(@player.can_whisper &&  @vil.night && @vil.state == 1 && @player.dead == 0))
				s += str_post
				if (@vil.period >= LONG && @vil.state == 1)
					s += %Q(<input type="hidden" name="cmd" value="prv">)
				else
					s += %Q(<input type="hidden" name="cmd" value="msg">)
				end
				s += %Q(<textarea rows=3 cols=30 name="message"></textarea><br>)
				if (@player.dead != 0)
					s += %Q(<input type="hidden" name="groan" value="on"><input type="submit" value="���᤭"><input name="think" value="on" type="checkbox">��)
				elsif (@vil.night && @vil.state == 1)
					s += %Q(<input type="hidden" name="think" value="on"><input type="submit" value="�Ȥ��">)
				else
					s += %Q(<input type="submit" value="ȯ��">)
					if (@vil.period >= LONG && @vil.state == 1)
						s += %Q(#{@player.say_remain}/#{@vil.sayfull})
					end
					s += %Q(<input name="think" value="on" type="checkbox">��)
				end
				s += %Q(<input name="loud" value="on" type="checkbox">��)
				s += "</form>"
			end
			if (@player.dead == 0 && !@vil.night)
				s += "<br>"
				s += str_post
				s += %Q(<input type="hidden" name="cmd" value="msg">)
				s += %Q(<input type="hidden" name="set_date" value="#{@vil.date}"><input type="hidden" name="action" value="on">)
				s += @player.name
				s += %Q(<select name="postpos">)
				for i in 0...POSTPOS.size do
					s += %Q(<option value = "#{i}">#{POSTPOS[i]})
					s += "\n"
				end
				s += "</select>"
				s += %Q(<select name="action_id">)
				s += %Q(<option value = "" selected>��)
				@vil.pids.each do |p|
					next if (p == @player)
					i = p.num_id
					s += %Q(<option value = "#{i}">#{p.name})
					s += "\n"
				end
				s += "</select><br>"
				s += %Q(<input type="text" name="message" maxlength="50"><input type="submit" value="���������">)
				if (@vil.period >= LONG && @vil.state == 1)
					s += %Q(#{@player.action_remain}/#{@vil.actfull})
				end
				s += "</form>"
			end

			s += "<br>"
			if (@player.dead == 0 && @vil.state == 1)
				if (@player.sid == 1)
					if (@vil.night || !@vil.card)
						s += skill_post
						s += "������"
						s += %Q(<select name="target_id">)
						if (@player.target == -1)
							s += "<option value = -1>̤���� *"
						else
							s += "<option value = -1>����󥻥�"
						end

						if (@vil.attack_dummy(@vil.date + 1))
							p = @vil.player_p(1)
							if (@player.target == 1)
								s += %Q(<option value = "#{1}" selected>#{p.name} *)
							else
								s += %Q(<option value = "#{1}">#{p.name})
							end
							s += "\n"
						else
							@vil.pids.each do |p|
								next if (p == @player)
								next if (p.sid == 1)
								i = p.num_id
								if (@player.target == i)
									s += %Q(<option value = "#{i}" selected>#{p.name} *)
								else
									s += %Q(<option value = "#{i}">#{p.name})
								end
								s += "\n"
							end
						end
						s += %Q(</select><input type="submit" value="�ѹ�">)
						s += "</form>"
						s += str_post
						s += %Q(<input type="hidden" name="cmd" value="msg">)
						s += %Q(<input type="hidden" name="whisper" value="on">)
						s += %Q(<textarea rows=3 cols=30 name="message"></textarea><br>)
						s += %Q(<input type="submit" value="�����䤭"><input name="think" value="on" type="checkbox">��)
						s += %Q(<input name="loud" value="on" type="checkbox">��)
						s += "</form>"
					end
				elsif (@player.sid == 2)
					s += skill_post
					s += "�ꤦ��"
					s += %Q(<select name="target_id">)
					if (@player.target == -1)
						s += "<option value = -1>̤���� *"
					else
						s += "<option value = -1>����󥻥�"
					end
					@vil.pids.each do |p|
						next if (p == @player)
						i = p.num_id
						if (@player.target == i)
							s += %Q(<option value = "#{i}" selected>#{p.name} *)
						else
							s += %Q(<option value = "#{i}">#{p.name})
						end
						s += "\n"
					end
					s += %Q(</select><input type="submit" value="�ѹ�">)
					s += "</form>"
        elsif (@player.sid == 4 && @vil.possessed)
					s += skill_post
          s += "�������å���"
          s += %Q(<select name="target_id">)
          if (@player.target == -1)
            s += "<option value = -1>̤���� *"
          else
            s += "<option value = -1>����"
          end
          if (@player.target == 0)
            s += %Q(<option value = "0" selected>���� *)
          else
            s += %Q(<option value = "0">����)
          end
          s += "\n"
          s += %Q(</select><input type="submit" value="�ѹ�">)
          s += "</form>"
				elsif (@player.sid == 5 || @player.sid == 16)
					if (@vil.can_guard(@vil.date + 1))
						s += skill_post
						s += "��ҡ�"
						s += %Q(<select name="target_id">)
						if (@player.target == -1)
							s += "<option value = -1>̤���� *"
						else
							s += "<option value = -1>����󥻥�"
						end
						@vil.pids.each do |p|
							next if (p == @player)
							i = p.num_id
							if (@player.target == i)
								s += %Q(<option value = "#{i}" selected>#{p.name} *)
							else
								s += %Q(<option value = "#{i}">#{p.name})
							end
							s += "\n"
						end
						s += %Q(</select><input type="submit" value="�ѹ�">)
						s += "</form>"
					end
				elsif (@player.sid == 8)
					if(@vil.night || !@vil.card)
						s += str_post
						s += %Q(<input type="hidden" name="cmd" value="msg">)
						s += %Q(<input type="hidden" name="whisper" value="on">)
						s += %Q(<textarea rows=3 cols=30 name="message"></textarea><br>)
						s += %Q(<input type="submit" value="�����䤭"><input name="think" value="on" type="checkbox">��)
						s += %Q(<input name="loud" value="on" type="checkbox">��)
						s += "</form>"
					end
				elsif (@player.sid == 11)
					s += skill_post
					s += "��Ȥ��ꤦ:"
					s += %Q(<select name="target_id">)
					if (@player.target == -1)
						s += "<option value = -1>̤���� *"
					else
						s += "<option value = -1>����󥻥�"
					end
					@vil.pids.each do |p|
						next if (p == @player)
						i = p.num_id
						if (@player.target == i)
							s += %Q(<option value = "#{i}" selected>#{p.name} *)
						else
							s += %Q(<option value = "#{i}">#{p.name})
						end
						s += "\n"
					end
					s += %Q(</select><input type="submit" value="�ѹ�">)
					s += "</form>"
				elsif (@player.sid == 12)
					if (@vil.can_cupid(@vil.date + 1))
						s += skill_post
						s += "��������ġ�<br>"
						s += %Q(<select name="target_id">)
						if (@player.target == -1)
							s += "<option value = -1>̤���� *"
						else
							s += "<option value = -1>����󥻥�"
						end
						@vil.pids.each do |p|
							i = p.num_id
							if (@player.target == i)
								s += %Q(<option value = "#{i}" selected>#{p.name} *)
							else
								s += %Q(<option value = "#{i}">#{p.name})
							end
							s += "\n"
						end
						s += %Q(</select><select name="target_id2">)
						if (@player.target2 == -1)
							s += "<option value = -1>̤���� *"
						else
							s += "<option value = -1>����󥻥�"
						end
						@vil.pids.each do |p|
							i = p.num_id
							if (@player.target2 == i)
								s += %Q(<option value = "#{i}" selected>#{p.name} *)
							else
								s += %Q(<option value = "#{i}">#{p.name})
							end
							s += "\n"
						end
						s += %Q(</select><input type="submit" value="�ѹ�">)
						s += "</form>"
					end
				elsif (@player.sid == 13)
					if (@vil.can_cupid(@vil.date + 1))
					s += skill_post
					s += "������롧"
					s += %Q(<select name="target_id">)
					if (@player.target == -1)
						s += "<option value = -1>̤���� *"
					else
						s += "<option value = -1>����󥻥�"
					end
					@vil.pids.each do |p|
						next if (p == @player)
						i = p.num_id
						if (@player.target == i)
							s += %Q(<option value = "#{i}" selected>#{p.name} *)
						else
							s += %Q(<option value = "#{i}">#{p.name})
						end
						s += "\n"
					end
					s += %Q(</select><input type="submit" value="�ѹ�">)
					s += "</form>"
					end
				elsif (@player.sid == 14)
					s += skill_post
					s += "���⤹�롧"
					s += %Q(<select name="target_id">)
					if (@player.target == -1)
						s += "<option value = -1>̤���� *"
					else
						s += "<option value = -1>����󥻥�"
					end
					@vil.pids.each do |p|
						next if (p == @player)
						i = p.num_id
						if (@player.target == i)
							s += %Q(<option value = "#{i}" selected>#{p.name} *)
						else
							s += %Q(<option value = "#{i}">#{p.name})
						end
						s += "\n"
					end
					s += %Q(</select><input type="submit" value="�ѹ�">)
					s += "</form>"
				end
			end
			if (@vil.state == 0)
				s += str_post
				s += %Q(<input type="hidden" name="cmd" value="exit"><input type="hidden" name="exit_id" value="#{@player.num_id}">)
				s += %Q(<input type="submit" value="¼��Ф�">)
				s += "</form>"
			end
		end
		if (!@player || @vil.state != 1)
			s += "<br>"
			s += str_post
			s += %Q(<input type="hidden" name="cmd" value="msg" ><input type="hidden" name="guest" value="on">)
			s += "#{@userid}<br>"
			s += %Q(<textarea rows=3 cols=30 name="message"></textarea><br>)
			s += %Q(<input type="submit" value="ȯ��"><input name="think" value="on" type="checkbox">��)
			s += %Q(<input name="loud" value="on" type="checkbox">��)
			s += "</form>"
		end
		print Kconv.tosjis(s)
	end

	def handle_login
		@login = false
		userid = @cgi['userid']
		return if (userid == '')
		userid = CGI.unescape(userid) if (ENV['REQUEST_METHOD'] == 'GET')
		@userid = CGI.escapeHTML(Kconv.toeuc(CGI.unescape(userid)))
		@pass = Kconv.toeuc(@cgi['pass'])
		return if (@pass == '')

		userdb = PStore.new('db/user.db')
		userdb.transaction do
			if (userdb.root?(@userid))
				if (@pass == userdb[@userid]['pass'])
					@login = true
					@esuserid = CGI.escape(@userid)
				end
			end
		end
	end

	def form_prv
		s = ""
		if (@player.say_remain == 0)
			s += "ȯ����������С��Ǥ���<hr>"
			s += %Q(<a href="?vid=#{@vid}&userid=#{@esuserid}&pass=#{@pass}#{@am_str}#b">���</a> )
		else
			s += @prv_str
			s += %Q(<form action="pigeon.cgi" method="post">)
			s += %Q(<input type="hidden" name="userid" value="#{@userid}"><input type="hidden" name="pass" value="#{@pass}"><input type="hidden" name="vid" value="#{@vid}">)
			s += @am_inp
			s += %Q(<input type="hidden" name="cmd" value="msg">)
			s += %Q(<input type="hidden" name="prv" value="on"><input type="hidden" name="message" value="#{@val_msg}">)
			s += %Q(<input type="hidden" name="j_data" value="���ܸ�">)
			s += %Q(<input type="hidden" name="loud" value="on">) if (@cgi['loud'] == 'on')
			s += %Q(<input type="submit" value="ȯ��">)
			s += "</form>"
			s += %Q(<form action="pigeon.cgi" method="post">)
			s += %Q(<input type="hidden" name="cmd" value="cancel">)
			s += %Q(<input type="hidden" name="userid" value="#{@userid}"><input type="hidden" name="pass" value="#{@pass}"><input type="hidden" name="vid" value="#{@vid}">)
			s += @am_inp
			s += %Q(<input type="submit" value="����󥻥�">)
			s += "</form>"
		end
		print NKF.nkf('-xsE', s)
	end

	def form_successful
		s = ''
		print_head
		s += "��ư�δ�λ<hr>"
		s += %Q(<font color="red">��ư�ϼ��Ԥ��ޤ���) if (@f_success == false)
		s += %Q(<a href="?vid=#{@vid}&userid=#{@esuserid}&pass=#{@pass}#{@am_str}#b">¼����롣</a>)
		s += "</body></html>"
		print Kconv.tosjis(s)
	end

	def log_amount
		if (@cgi.key?('am') && @cgi['am'].to_i != STANDARD_AM)
			@am = @cgi['am'].to_i
			@am = MAX_AM if (@am > MAX_AM)
			@am = 0 if (@am < 0)
			@am_str = "&am=#{@am}"
			@am_inp = %Q(<input name="am" value="#{@am}" type="hidden">)
		else
			@am = STANDARD_AM
			@am_str = ""
			@am_inp = ""
		end
	end

	def run
		@headered = false
		head = Kconv.tosjis("Content-Type: text/html; charset=Shift_JIS\n\n")

		begin
    if (ENV['REQUEST_METHOD'] == 'GET') && (@cgi['cmd'] == 'link')
      print_head
      form_link
      print_foot
      return
    end
		handle_login
		log_amount
		if (!@login)
			form_login
			return
		elsif (ENV['REQUEST_METHOD'] == 'POST')
			if (@cgi['cmd'] == 'prv' && handle_prv)
				print_head
				form_prv
				print_foot
				return
			end
			@f_success = false
			handle_cmd
			form_successful
			return
		end

		if (@vildb && @vid != 0)
			handle_update
			handle_end_log
			print_head("#{@vil.vid} #{@vil.name}")
			if (@cgi['act'] == 'o')
				form_act
			elsif (@cgi['con'] == 'o')
				form_conf
			else
				handle_vid
			end
			print_foot
		else
			print_head
			handle_index
			print_foot
		end

		rescue ErrorMsg
			if (!@headered)
				print head + "\r\n"
			end
			print $!
		rescue
			if (!@headered)
				print head + "\r\n"
			end
			print "<pre>\n"
			print CGI.escapeHTML("#{$!.to_s}\n")
			print CGI.escapeHTML("#{$!.backtrace.join("\n")}\n")
			print "</pre>\n"
		end
	end
end

Pigeon.new.run

