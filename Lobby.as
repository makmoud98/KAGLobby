#include "LobbyCommon.as";
#include "BackendHelper.as";
#include "KGUI.as";

Rectangle@ player_list;
Rectangle@ queue_buttons;
Rectangle@ invite_box;

Vec2f btnsize(100,30); 
Button@ btn1;
Button@ btn2;

string player_list_pos = "player_list_pos";
string queue_buttons_pos = "queue_buttons_pos";
string invite_box_pos = "invite_box_pos";

BackendPlayer@ me = null;
Party@ my_party = null;
Party@ selected = null;
BackendPlayer@ selected_player = null;

bool menu_open = false;
u8 cooldown = 0;

string[] invites;
int invite_timer = 0;

void onInit(CRules@ this)
{
	Party@[] parties;
	this.set("parties", @parties);

	this.addCommandID("create_party");
	this.addCommandID("join_party");
	this.addCommandID("leave_party");
	this.addCommandID("kick_player");
	this.addCommandID("invite_player");
	this.addCommandID("revoke_invite");
	this.addCommandID("sync_party_info");

	init_gui();
} 

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
	if(cmd == this.getCommandID("create_party"))
	{//this command assumes the player is not in a party already
		Party@[]@ parties;
		if(!this.get("parties", @parties)){
			print("cannot get parties obj in cmd create_party");
		}
		if(parties is null){//should never be null, even if it is empty
			print("parties obj is null in cmd create_party");
		}
		BackendPlayer@[]@ backend_players;
		if(!this.get("backend_players", @backend_players)){
			print("could not get backend_players in cmd create_party");
		}
		if(backend_players is null){//should never be null, even if it is empty
			print("backend_players is null in cmd create_party");
		}
		bool created = false;
		string username = params.read_string();
		u8 r = params.read_u8();
		u8 g = params.read_u8();
		u8 b = params.read_u8();
		for(u8 i = 0; i < backend_players.length; i++){
			BackendPlayer@ player = backend_players[i];
			if(player !is null && player.username == username){
				print("party created, adding party to list");
				Party prty(r, g, b);
				prty.members.push_back(player);
				parties.push_back(prty);
				if(getNet().isClient()){
					CPlayer@ local_player = getLocalPlayer(); 
					if(local_player is null)
						return;
					if(local_player.getUsername() == username){
						@my_party = prty;						
					}
				}
				created = true;
				break;
			}
		}
		if(!created){
			print("player not found in backend_players");
		}
	}
	if(cmd == this.getCommandID("join_party")){
		Party@[]@ parties;
		if(!this.get("parties", @parties)){
			print("cannot get parties obj in cmd join_party");
		}
		if(parties is null){//should never be null, even if it is empty
			print("parties obj is null in cmd join_party");
		}
		BackendPlayer@[]@ backend_players;
		if(!this.get("backend_players", @backend_players)){
			print("could not get backend_players in cmd join_party"); 
		}
		if(backend_players is null){//should never be null, even if it is empty
			print("backend_players is null in cmd join_party");
		}
		string username = params.read_string();
		string invited = params.read_string();
		for(u8 i = 0; i < backend_players.length; i++){
			BackendPlayer@ player = backend_players[i];
			if(player !is null && player.username == username){
				for(int j = 0; j < parties.length; j++){
					Party@ party = parties[j];
					if(party !is null){
						BackendPlayer@ member = party.getMemberByName(username);
						if(member !is null && member is party.getLeader()){
							for(u8 k = 0; k < backend_players.length; k++){
								BackendPlayer@ invited_player = backend_players[k];
								if(invited_player.username == invited){
									if(party.addMember(invited_player)){
										if(getNet().isClient()){
											CPlayer@ local_player = getLocalPlayer(); 
											if(local_player is null)
												return;
											if(local_player.getUsername() == invited){
												@my_party = party;												
											}
										}
										print(""+invited+ " has successfully joined " + username + "'s party");
									}
									else{
										print(invited + " attempted to join " + username + "'s party, but it was full");
									}
									return;
								}
							}
						}
					}
				}
			}
		}
	}
	if(cmd == this.getCommandID("leave_party"))
	{
		Party@[]@ parties;
		if(!this.get("parties", @parties)){
			print("cannot get parties obj in cmd leave_party");
		}
		if(parties is null){//should never be null, even if it is empty
			print("parties obj is null in cmd leave_party");
		}
		BackendPlayer@[]@ backend_players;
		if(!this.get("backend_players", @backend_players)){
			print("could not get backend_players in cmd leave_party");
		}
		if(backend_players is null){//should never be null, even if it is empty
			print("backend_players is null in cmd leave_party");
		}
		string username = params.read_string();
		for(u8 i = 0; i < backend_players.length; i++){
			BackendPlayer@ player = backend_players[i];
			if(player !is null && player.username == username){
				for(u8 j = 0; j < parties.length; j++){
					Party@ party = parties[j];
					if(party !is null){
						for(u8 k = 0; k < party.members.length; k++){
							BackendPlayer@ member = party.members[k];
							if(member !is null && member.username == player.username){
								print("removed player " + username + " from party");
								if(party.removeMember(player.username)){// if player was the last member, kill the party
									parties.removeAt(j);
									print("player left party and was the last one, so the party was killed");
								}
								if(getNet().isClient()){
									CPlayer@ local_player = getLocalPlayer(); 
									if(local_player is null)
										return;
									if(local_player.getUsername() == username){
										@my_party = null;										
									}
									 
								}
								return;
							}
						}
					}
				}
			}
		}
	}
	if(cmd == this.getCommandID("kick_player")){
		Party@[]@ parties;
		if(!this.get("parties", @parties)){
			print("cannot get parties obj in cmd kick_player");
		}
		if(parties is null){//should never be null, even if it is empty
			print("parties obj is null in cmd kick_player");
		}
		BackendPlayer@[]@ backend_players;
		if(!this.get("backend_players", @backend_players)){
			print("could not get backend_players in cmd kick_player");
		}
		if(backend_players is null){//should never be null, even if it is empty
			print("backend_players is null in cmd kick_player");
		}
		string username = params.read_string();
		string kicked = params.read_string();
		for(u8 i = 0; i < backend_players.length; i++){
			BackendPlayer@ player = backend_players[i];
			if(player !is null && player.username == username){
				for(u8 j = 0; j < parties.length; j++){
					Party@ party = parties[j];
					if(party !is null && party.getLeader() is player){
						for(u8 k = 0; k < backend_players.length; k++){
							BackendPlayer@ member = backend_players[k];
							if(member !is null && member.username == kicked){
								print("kicked player " + kicked + " from party");
								if(party.removeMember(member.username, true)){// if player was the last member, kill the party SHOULD NOT BE POSSIBLE HERE, but will leave it anyway just in case
									parties.removeAt(j);
									//should never happen because u cant kick urself
									print("player left party and was the last one, so the party was killed, should not be poss");
								}
								if(getNet().isClient()){
									CPlayer@ local_player = getLocalPlayer(); 
									if(local_player is null)
										return;
									if(local_player.getUsername() == kicked){
										@my_party = null;
									}
								}
								return;
							}
						}
					}
				}
			}
		}
	}
	if(cmd == this.getCommandID("invite_player")){
		Party@[]@ parties;
		if(!this.get("parties", @parties)){
			print("cannot get parties obj in cmd invite_player");
		}
		if(parties is null){//should never be null, even if it is empty
			print("parties obj is null in cmd invite_player");
		}
		BackendPlayer@[]@ backend_players;
		if(!this.get("backend_players", @backend_players)){
			print("could not get backend_players in cmd invite_player");
		}
		if(backend_players is null){//should never be null, even if it is empty
			print("backend_players is null in cmd invite_player");
		}
		string username = params.read_string();
		string invited = params.read_string();
		for(u8 i = 0; i < backend_players.length; i++){
			BackendPlayer@ player = backend_players[i];
			if(player !is null && player.username == username){
				for(u8 j = 0; j < parties.length; j++){
					Party@ party = parties[j];
					if(party !is null){
						BackendPlayer@ member = party.getLeader();
						if(player is member){
							for(u8 k = 0; k < backend_players.length; k++){
								BackendPlayer@ invited_player = backend_players[k];
								if(invited_player !is null && invited_player.username == invited){
									if(party.invite(invited_player)){
										print(invited + " was successfuly invited to " + username +"'s party");
										CPlayer@ local_player = getLocalPlayer();  
										if(local_player is null)
											return;
										if(getNet().isClient() && invited_player.username == local_player.getUsername()){
											//do invite stuff here????????????????
											invites.push_back(username);
											Label l = cast<Label>(invite_box.children[0]);
											l.label = "You have been invited to " + username + "'s party!\nClick Here to join!\nOr click on " + username + "'s name on the list.";
											invite_timer = 150;
											client_AddToChat("You have been invited to " + username + "'s party!");
										}
									} 
									else{
										print(invited + " was already invited to the party");
									}
									return;
								}
							}
						}
					}
				}
			}
		}
	}
	if(cmd == this.getCommandID("revoke_invite")){
		Party@[]@ parties;
		if(!this.get("parties", @parties)){
			print("cannot get parties obj in cmd revoke_invite");
		}
		if(parties is null){//should never be null, even if it is empty
			print("parties obj is null in cmd revoke_invite");
		}
		BackendPlayer@[]@ backend_players;
		if(!this.get("backend_players", @backend_players)){
			print("could not get backend_players in cmd revoke_invite");
		}
		if(backend_players is null){//should never be null, even if it is empty
			print("backend_players is null in cmd revoke_invite");
		}
		string username = params.read_string();
		string uninvited = params.read_string();
		for(u8 i = 0; i < backend_players.length; i++){
			BackendPlayer@ player = backend_players[i];
			if(player !is null && player.username == username){
				for(u8 j = 0; j < parties.length; j++){
					Party@ party = parties[j];
					if(party !is null && party.getLeader() is player){
						for(u8 k = 0; k < backend_players.length; k++){
							BackendPlayer@ member = backend_players[k];
							if(member !is null && member.username == uninvited){
								print("uninvited player " + uninvited + " from party");
								if(party.revokeInvitation(member.username)){
									print(uninvited + " has successfully been uninvited from " + username + "'s party");
								}
								return;
							}
						}
					}
				}
			}
		}
	}
	if(getNet().isClient() && cmd == this.getCommandID("sync_party_info")){
		print("client got sync party info cmd");
		string username;
		if(!params.saferead_string(username))
			return;
		CPlayer@ player = getPlayerByUsername(username);
		if(player is null)
			return;
		if(!player.isMyPlayer())
			return;
		Party@[]@ parties;
		if(!this.get("parties", @parties)){
			print("cannot get parties obj in sync_party_info");
		}
		if(parties is null){//should never be null, even if it is empty
			print("parties obj is null in sync_party_info");
		}
		BackendPlayer@[]@ backend_players;
		if(!this.get("backend_players", @backend_players)){
			print("could not get backend_players in sync_party_info");
		}
		if(backend_players is null){//should never be null, even if it is empty
			print("backend_players is null in sync_party_info");
		}
		u8 size;
		if(!params.saferead_u8(size)){
			return;
		}
		print("prtyies size = " + size);
		for(u8 i = 0; i < size; i++){
			u8 r; 
			u8 g;
			u8 b;
			if(!params.saferead_u8(r)){
				r=0;
			}
			if(!params.saferead_u8(g)){
				g=0;
			}
			if(!params.saferead_u8(b)){
				b=0;
			}
			Party prty(r,g,b);
			u8 size_members;
			if(!params.saferead_u8(size_members)){
				size_members = 0;
			}
			for(u8 j = 0; j < size_members; j++){
				string user;
				if(!params.saferead_string(user)){
					continue;
				}
				for(u8 k = 0; k < backend_players.length; k++){
					BackendPlayer@ p = backend_players[k];
					if(p !is null){
						if(p.username == user){
							prty.addMember(p);
							break;
						}
					}
				}
			}
			u8 size_invited;
			if(!params.saferead_u8(size_invited)){
				size_invited = 0;
			}
			for(u8 j = 0; j < size_invited; j++){
				string user;
				if(!params.saferead_string(user)){
					continue;
				}
				for(u8 k = 0; k < backend_players.length; k++){
					BackendPlayer@ p = backend_players[k];
					if(p !is null){
						if(p.username == user){
							prty.invite(p);
							break;
						}
					}
				}
			}  
			print("added party to parties");

			parties.push_back(prty);
		}
	}
}

void onPlayerLeave(CRules@ this, CPlayer@ player){
	Party@[]@ parties;
	if(!this.get("parties", @parties)){
		print("cannot get parties obj in onPlayerLeave in Lobby.as");
	}
	if(parties is null){//should never be null, even if it is empty
		print("parties obj is null in onPlayerLeave in Lobby.as");
	}
	BackendPlayer@[]@ backend_players;
	if(!this.get("backend_players", @backend_players)){
		print("could not get backend_players in onPlayerLeave");
	}
	if(backend_players is null){//should never be null, even if it is empty
		print("backend_players is null in onPlayerLeave");
	}
	for(int i = 0; i < parties.length; i++){ 
		Party@ party = parties[i];
		if(party !is null){
			party.removeMember(player.getUsername(),true);
		}
	}
	for(int j = 1; j < player_list.children.length; j++){								
		Rectangle@ r = cast<Rectangle>(player_list.children[j]);						
		if(getUsernameFromRectangle(r) == player.getUsername()){	
			player_list.children.removeAt(j);
			break;
		} 
	}
} 

void onNewPlayerJoin(CRules@ this, CPlayer@ player){
	Party@[]@ parties;
	if(!this.get("parties", @parties)){
		print("cannot get parties obj in onPlayerjoin in Lobby.as");
	}
	if(parties is null){//should never be null, even if it is empty
		print("parties obj is null in onNewPlayerJoin in Lobby.as");
	}
	BackendPlayer@[]@ backend_players;
	if(!this.get("backend_players", @backend_players)){
		print("could not get backend_players in onNewPlayerJoin");
	}
	if(backend_players is null){//should never be null, even if it is empty
		print("backend_players is null in onNewPlayerJoin");
	}
 
	init_gui();

	if(!getNet().isServer() || player is null || player.isBot()) return;

	/* order of writing to stream:
	________________________________
	size of party
	for every party:
		red color
		green color
		blue color
		size of party members list
		for every member:
			party member name 
		size of party invited list
		for every member:
			party invited name
	________________________________
	*/
	CBitStream party_stream;
	party_stream.write_string(player.getUsername());
	party_stream.write_u8(parties.length);
	for(int i = 0; i < parties.length; i++){
		Party@ p = parties[i];
		if(p !is null){
			party_stream.write_u8(p.color.getRed());
			party_stream.write_u8(p.color.getGreen());
			party_stream.write_u8(p.color.getBlue());

			party_stream.write_u8(p.members.length);
			for(int j = 0; j < p.members.length; j++){
				BackendPlayer@ player = p.members[j];
				if(player !is null){
					party_stream.write_string(player.username);
				}
				else{
					party_stream.write_string("");
				}
			}
			party_stream.write_u8(p.invited.length);
			for(int j = 0; j < p.invited.length; j++){
				BackendPlayer@ player = p.invited[j];
				if(player !is null){
					party_stream.write_string(player.username);
				}
				else{
					party_stream.write_string("");
				}
			}
		}
		else{
			party_stream.write_u8(0);//r
			party_stream.write_u8(0);//g
			party_stream.write_u8(0);//b 
			party_stream.write_u8(0);//size members
			party_stream.write_u8(0);//size invited
		}
	}
	print("sent sync party info cmd to " + player.getUsername());
	this.SendCommand(this.getCommandID("sync_party_info"), party_stream);
}

void onRenderScoreboard(CRules@ this){ 
	BackendPlayer@[]@ backend_players;
	if(!this.get("backend_players", @backend_players)){
		print("could not get backend_players in onNewPlayerJoin");
	}
	if(backend_players is null){//should never be null, even if it is empty
		print("backend_players is null in onNewPlayerJoin");
	}

	Party@[]@ parties;
	if(!this.get("parties", @parties)){
		print("cannot get parties obj in onPlayerjoin in Lobby.as");
	}
	if(parties is null){//should never be null, even if it is empty
		print("parties obj is null in onNewPlayerJoin in Lobby.as");
	}

	if(me is null){
		CPlayer@ local_player = getLocalPlayer(); 
		if(local_player is null)
			return;
		string username = local_player.getUsername();
		for(u8 i = 0; i < backend_players.length; i++)
		{
			BackendPlayer@ player_ = backend_players[i];
			if(player_ !is null && player_.username == username){
				@me = player_; 
			}
		}
	}

	if(true)//todo: check if connected to the backend, then render
	{
		//player_list.clearChildren();
		for(int i = 0; i < backend_players.length; i++){
			bool found = false;
			if(backend_players[i] !is null){  														
				for(int j = 1; j < player_list.children.length; j++){								
					Rectangle@ r = cast<Rectangle>(player_list.children[j]);						
					if(getUsernameFromRectangle(r) == backend_players[i].username){					
						Party@ prty = getPartyByUsername(parties, backend_players[i].username);		
 
						if(prty !is null){	

							if(r.original_color != prty.color){
								r.original_color = prty.color;
								r.color = r.original_color;
							} 
						}
						else if(r.original_color != SColor(255,100,100,100)){
							r.original_color = SColor(255,100,100,100);
							r.color = r.original_color;
						}
						found = true;
					}
				}
				if(!found){
					CPlayer@ p = getPlayerByUsername(backend_players[i].username);
					if(p is null){
						continue;
					}
					Vec2f size(712, 16); 
					Vec2f tl = Vec2f(0,0) + Vec2f(0,size.y*(i+1));
					Rectangle r(tl, size, SColor(255,100,100,100));  
					r.addClickListener(player_button_click_event);
					r.addHoverStateListener(on_hover); 

					Party@ prty = getPartyByUsername(parties, backend_players[i].username);
					if(prty !is null){//this will happen when player joins server, syncs parties, then renders the scoreboard. we need to set the color.
						r.color = prty.color;
						r.original_color = r.color;
					}
					
					Label[] labels; 

					Vec2f tl_ = Vec2f(10,2); 
					Vec2f clantag_actualsize;
					labels.push_back(Label(tl_, Vec2f(10,14), p.getClantag().substr(0,5), color_white, false));  
					tl_.x+=48;   
					labels.push_back(Label(tl_, Vec2f(10 ,14), p.getCharacterName().substr(0,12), color_white, false)); 
					tl_.x+=112;
					labels.push_back(Label(tl_, Vec2f(160,14), p.getUsername(), color_white, false)); 
					tl_.x+=160;
					s32 ping_in_ms = s32(p.getPing() * 1000.0f / 30.0f); 
					labels.push_back(Label(tl_, Vec2f(64,14), ""+ping_in_ms, color_white, false));
					tl_.x+=64;
					labels.push_back(Label(tl_, Vec2f(64,14), backend_players[i].stats[0], color_white, false));
					tl_.x+=64;
					labels.push_back(Label(tl_, Vec2f(64,14), backend_players[i].stats[1], color_white, false));
					tl_.x+=64;
					labels.push_back(Label(tl_, Vec2f(64,14), backend_players[i].stats[2], color_white, false));
					tl_.x+=64;
					labels.push_back(Label(tl_, Vec2f(64,14), backend_players[i].stats[3], color_white, false));
					tl_.x+=64;
					labels.push_back(Label(tl_, Vec2f(64,14), backend_players[i].stats[4], color_white, false));
					
					for(int j=0;j<labels.length;j++){
						r.addChild(labels[j]); 
					}

					player_list.addChild(r);
					player_list.size = Vec2f(size.x,(player_list.children.length)*size.y);
				}
			}
		}

		player_list.draw();
		if(btn1.isEnabled){btn1.draw();} 
		if(btn2.isEnabled){btn2.draw();}
		queue_buttons.draw(); 

		if(getNet().isClient()){
			if(invite_timer > 0 && invites.length > 0){
				invite_box.draw();
			}
		}
	} 
}

void onRender(CRules@ this){
	if(getNet().isClient()){
		if(invite_timer > 0 && invites.length > 0){
			invite_box.draw();
		}
	}	
}

Party@ getPartyByUsername(Party@[] parties, string username){
	for(int i = 0; i < parties.length; i++){
		Party@ p = parties[i];
		if(p !is null){
			if(p.getMemberByName(username) !is null){
				return p;
			}
		}
	}
	return null;
}

string getUsernameFromRectangle(IGUIItem@ item){
	Rectangle@ r = cast<Rectangle>(item);
	if(r !is null){
		if(r.children.length > 2 && r.children[2] !is null){
			Label@ l = cast<Label>(r.children[2]);
			return l.label;
		}
	} 
	return "";
}
 
void init_gui(){  
	@player_list = Rectangle(Vec2f(0,0), Vec2f(0,0), SColor(0,0,0,0));//initial at 0 cuz we need to resize based on players
	player_list.loadPos(player_list_pos,0,0);
    player_list.addDragEventListener(drag_event_1);
    player_list.isDragable = true;
    Rectangle r(Vec2f_zero, Vec2f(712, 16), SColor(255,85,85,85));  
	r.addHoverStateListener(on_hover); 
	
	Label[] labels;
  
	Vec2f tl_ = Vec2f(10,2); 
	labels.push_back(Label(tl_, Vec2f(10,14), "Clan", color_white, false));  
	tl_.x+=48;   
	labels.push_back(Label(tl_, Vec2f(10,14), "Nickname", color_white, false)); 
	tl_.x+=112;
	labels.push_back(Label(tl_, Vec2f(160,14), "Username", color_white, false)); 
	tl_.x+=160;
	labels.push_back(Label(tl_, Vec2f(64,14), "Ping", color_white, false));
	tl_.x+=64;
	labels.push_back(Label(tl_, Vec2f(64,14), "Rank", color_white, false));
	tl_.x+=64;
	labels.push_back(Label(tl_, Vec2f(64,14), "Wins", color_white, false));
	tl_.x+=64;
	labels.push_back(Label(tl_, Vec2f(64,14), "Losses", color_white, false));
	tl_.x+=64;
	labels.push_back(Label(tl_, Vec2f(64,14), "Kills", color_white, false));
	tl_.x+=64;
	labels.push_back(Label(tl_, Vec2f(64,14), "Deaths", color_white, false));
	
	for(int j=0;j<labels.length;j++){
		r.addChild(labels[j]); 
	}

	player_list.addChild(r);

	@btn1 = Button(Vec2f_zero, btnsize, "", color_black);
	btn1.addClickListener(player_button_click_event_1);
	//btn1.addHoverStateListener(on_hover); 
	btn1.isEnabled = false; 
	@btn2 = Button(Vec2f_zero, btnsize, "", color_black);
	btn2.addClickListener(player_button_click_event_1);  
	//btn2.addHoverStateListener(on_hover); 
	btn2.isEnabled = false;

    @queue_buttons = Rectangle(Vec2f(0,0), Vec2f(170,230));

	queue_buttons.loadPos(queue_buttons_pos,getScreenWidth()-queue_buttons.size.x,0);
    queue_buttons.addDragEventListener(drag_event_2);
    queue_buttons.isDragable = true;

    Button ranked(Vec2f(10,10), Vec2f(150,100), "  Ranked\nSolo Queue",color_black);
    ranked.addClickListener(ranked_button_click);
    ranked.setToolTip("You can only enter\nthe queue solo. Teams\nare automatically assigned\nbased on rank. Your rank will\nbe automatically adjusted at the\nend of the match.",2, color_black);
    Button unranked(Vec2f(10,120), Vec2f(150,100), "  Unranked\nParty Queue",color_black);
    unranked.addClickListener(unranked_button_click);
    unranked.setToolTip("You can only enter\nthe queue with a party of 5.\nThis can be used for clan wars,\ncaptains, etc. Rank will NOT\nbe affected by the outcome.",2, color_black);
 
    queue_buttons.addChild(ranked);
    queue_buttons.addChild(unranked);
 
    @invite_box = Rectangle(Vec2f(0,0), Vec2f(200,100), SColor(175,125,125,125));
	invite_box.loadPos(invite_box_pos,getScreenWidth()-200,320);
	invite_box.addClickListener(accept_invite_button_click);
    invite_box.addDragEventListener(drag_event_3);
    invite_box.isDragable = true;
    invite_box.addChild(Label(Vec2f(10,10),Vec2f(190,90),"",color_white,true));
}
 
void on_hover(bool hover, IGUIItem@ sender){
	Rectangle@ r = cast<Rectangle>(sender);
	if(r !is null){ 
		if(!r.useColor)
			return;
		SColor hovercolor = r.original_color;
		if(hover){
			hovercolor.setRed(hovercolor.getRed()*.75);
			hovercolor.setGreen(hovercolor.getGreen()*.75);
			hovercolor.setBlue(hovercolor.getBlue()*.75);
		}
		r.color = hovercolor;
	}
}

void accept_invite_button_click(int x , int y , int button, IGUIItem@ sender){
	if(button == KEY_LBUTTON && cooldown == 0){
		print("clicked join button");
		cooldown = 2;
	}
}

void ranked_button_click(int x , int y , int button, IGUIItem@ sender){
	if(button == KEY_LBUTTON && cooldown == 0){
		print("clicked ranked button");
		cooldown = 2;
	}
}

void unranked_button_click(int x , int y , int button, IGUIItem@ sender){
	if(button == KEY_LBUTTON && cooldown == 0){
		print("clicked unranked button");
		cooldown = 2;
	}
}

void player_button_click_event(int x , int y , int button, IGUIItem@ sender){
	if(button == KEY_LBUTTON && !menu_open && cooldown == 0){//open menu by enabling both buttons
		CRules@ this = getRules();
		if(this is null){
			return;
		}
		BackendPlayer@[]@ backend_players;
		if(!this.get("backend_players", @backend_players)){
			print("could not get backend_players in onNewPlayerJoin");
		}
		if(backend_players is null){//should never be null, even if it is empty
			print("backend_players is null in onNewPlayerJoin");
		}

		Party@[]@ parties;
		if(!this.get("parties", @parties)){
			print("cannot get parties obj in onPlayerjoin in Lobby.as");
		}
		if(parties is null){//should never be null, even if it is empty
			print("parties obj is null in onNewPlayerJoin in Lobby.as");
		}
		string username_ = getUsernameFromRectangle(sender);
		if(username_ == "")
			return;
		for(int i = 0; i < backend_players.length; i++){
			if(backend_players[i] !is null && backend_players[i].username == username_){
				@selected_player = backend_players[i];
				@selected = getPartyByUsername(parties, username_);
			}
		}
		CPlayer@ local_player = getLocalPlayer(); 
		if(local_player is null)
			return;
		string username = local_player.getUsername();
		bool is_me = username == selected_player.username;	//if i clicked on myself
		bool i_am_party = my_party !is null;		 	//if local player is in a party
		bool is_party = selected !is null;			 	//if i clicked on someone who is in a party
		bool i_am_leader = i_am_party && my_party.getLeader() is me; 	//if i am a leader
		bool is_leader = is_party && selected.getLeader() is selected_player;//if i selected a leader
		bool i_am_invited = is_party && selected.getInvitedByName(me.username) is me;//if i am invited to that party and im not in it already
		bool is_invited = i_am_party && my_party.getInvitedByName(selected_player.username) is selected_player;//if i am invited to that party and im not in it already

		string option_text = "";
		if(is_me && (i_am_leader || i_am_party)){
			option_text = "Leave Party";
		}
		else if(is_me){
			option_text = "Create Party";
		}
		else if(i_am_leader && !is_invited && my_party !is selected){
			option_text = "Invite Player";
		}
		else if(i_am_leader && is_invited && my_party !is selected){
			option_text = "Revoke Invite";
		}
		else if(i_am_leader && is_party && my_party is selected){
			option_text = "Kick Player";
		}
		else if(!i_am_party && my_party !is selected && i_am_invited){
			option_text = "Join Party";
		} 
		else{
			option_text = "";// i think we have every situation covered
		}
		Rectangle@ rect = cast<Rectangle>(sender);
		if(rect !is null){ 
			if(btn1 !is null && btn2 !is null){
				if(option_text == ""){
					btn1.desc = "Cancel";
					btn1.position = Vec2f(x,y);
					btn1.isEnabled = true;
				}
				else{							
					btn1.desc = option_text;	
					btn1.position = Vec2f(x,y); 
					btn1.isEnabled = true;

					btn2.desc = "Cancel"; 
					btn2.position = Vec2f(x,y) + Vec2f(0,btnsize.y);
					btn2.isEnabled = true;
				}
				menu_open = true;
				cooldown = 2;
			}
		}
	}
}
 
void player_button_click_event_1(int x , int y , int button, IGUIItem@ sender){
	if(button == KEY_LBUTTON && menu_open && cooldown == 0){//clicks a button
		CPlayer@ local_player = getLocalPlayer(); 
		if(local_player is null)
			return;
		string username = local_player.getUsername();

		CRules@ this = getRules();
		if(this is null){
			return;
		}

		string option_text = "";
		Button@ btn = cast<Button>(sender);
		if(btn !is null){
			option_text = btn.desc;
		}

		if(btn1 !is null && btn2 !is null){
			btn1.desc = "";	
			//btn1.position = Vec2f_zero; 
			btn1.isEnabled = false;		

			btn2.desc = "";
			//btn2.position = Vec2f_zero;
			btn2.isEnabled = false;
		}

		if(option_text == 		"Create Party"){
			create_party(this, username);
		}
		else if(option_text == 	"Leave Party"){
			leave_party(this, username);
		}
		else if(option_text == 	"Invite Player"){
			invite_player(this, username, selected_player.username);
		}
		else if(option_text == 	"Kick Player"){
			kick_player(this, username, selected_player.username);
		}
		else if(option_text == 	"Join Party"){
			join_party(this, selected_player.username, username);
		}
		else if(option_text == 	"Revoke Invite"){ 
			revoke_invite(this, username, selected_player.username);
		}
		
		menu_open = false;
		cooldown = 2;
	}
}

void drag_event_1(int dType ,Vec2f mPos, IGUIItem@ sender){
    if (dType ==  DragFinished) {sender.savePos(player_list_pos);}
}

void drag_event_2(int dType ,Vec2f mPos, IGUIItem@ sender){
    if (dType ==  DragFinished) {sender.savePos(queue_buttons_pos);}
}

void drag_event_3(int dType ,Vec2f mPos, IGUIItem@ sender){
    if (dType ==  DragFinished) {sender.savePos(invite_box_pos);}
}

void onTick(CRules@ this){
	if(cooldown > 0){
		cooldown--;
	}
	if(invite_timer > 0){
		invite_timer--;
	}
	else if(invites.length > 0){
		invites.removeAt(0);
		if(invites.length > 0){
			invite_timer = 150;
		}
	}
}