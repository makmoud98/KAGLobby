//rules script to keep lobby/server/game clients synced
#include "BackendCommon.as";

void onInit(CRules@ this){
	Server@ server;
	this.set("server", @server);
	Server@[] servers;
	this.set("servers", @servers);					//info about other servers, lobby only
	BackendPlayer@[] backend_players;
	this.set("backend_players", @backend_players);	//info about all players connected with backend

	this.addCommandID("connect");					//used to connect server to the backend
	this.addCommandID("sync");						//used to check is servers are connected to backend + sync some other stuff
	this.addCommandID("get_match_info");			//lobby only, gets info about available match servers
	this.addCommandID("get_player_info");			//used by both to get player stats
	this.addCommandID("start_match");				//match only, to get info about previous server, players who will be in the match, 
	this.addCommandID("redirect_player"); 			//lobby only, used to send a player back to their current match, ex: if they disconnected and need to rejoin.
	this.addCommandID("sync_players");				//sync the backend players to the client on join
	this.addCommandID("sync_server_info");			//sync the server info to client on join
	this.addCommandID("sync_match_info");			//sync all the match server info to the client
}

void onTick(CRules@ this){
	bool is_server = getNet().isServer();
	Server@ server;
	if(!this.get("server", @server)){			//first, check if the sever is null. it shouldnt be if the server has connected to the backend at least once
		print("cannot get server object");
		return;
	}
	if(server is null){
		Server server();
		this.set("server", @server);
		server.connectBackend();
		print("server obj is null, connecting to backend");
		return;
	}
	if(!is_server)//clients dont need this info
		return;
	bool waiting = server.waiting;
	bool connected = server.connected;
	u32 sync = server.time_since_last_sync;
	u32 gametime = getGameTime();
	u8 type = server.type;
	if(connected){
		if(waiting && sync > (getTicksASecond()*5)){
			server.connected = false;
			print("server has disconnected from the backend");
			return;
		} 
		if(server.que.length > 0){
			tcpr(server.que[0]);
			server.que.removeAt(0);
		}
		if(!waiting && gametime % (getTicksASecond()*30) == 0){
			server.queryBackend();	
			print("sending query to backend");
			server.waiting = true;
			server.time_since_last_sync = 0;
		}
		else if(waiting){
			server.time_since_last_sync++;
		}
		BackendPlayer@[]@ backend_players;
		if(!this.get("backend_players", @backend_players)){
			print("could not get backend_players in ontick");
			return;
		}
		if(backend_players is null){//should never be null, even if it is empty
			print("backend_players is null in ontick");
			return;
		}
		if(getPlayerCount() != backend_players.length && (gametime % getTicksASecond() == 7)){
			for(u8 i = 0; i < getPlayerCount(); i++){
				bool found = false;
				CPlayer@ p = getPlayer(i);
				if(p is null)
					continue;
				string username = p.getUsername();
				for(u8 j = 0; j < backend_players.length; j++){	
					if(username == backend_players[j].username)
						found = true;
				}
				if(!found)
					server.queryPlayerInfo(username);
			}
		}
		if(type == 0){								//lobby code here

		}
		if(type == 1){								//match code here

		}
	}
	else if(gametime % (getTicksASecond()*10) == 0){//every 10 second
		server.connectBackend();
		print("waiting for connection to backend, retrying...");
	}
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params){
	if(cmd == this.getCommandID("connect")){
		Server@ server;
		if(!this.get("server", @server)){			//first, check if the server is null. it shouldnt be...
			print("cannot get server object in connect cmd");
			return;
		}
		if(server is null){
			print("server obj is null in connect cmd");	//should never happen theoretically. but i might be wrong
			return;
		}
		server.connected = true;
		server.waiting = false;
		server.type = params.read_u8();
		server.hostname = params.read_string();
		server.port = params.read_u16();
		server.id = params.read_u8();
		server.ready = params.read_u8();
		this.set("server", @server);
		print("connected to the backend!!!");
	}
	if(cmd == this.getCommandID("sync")){
		Server@ server;
		if(!this.get("server", @server)){			//first, check if the server is null. it shouldnt be...
			print("cannot get server object in sync");
			return;
		}
		if(server is null){
			print("server obj is null in sync cmd");	//should never happen theoretically. but i might be wrong
			return;
		}
		else {
			if(!server.connected){
				print("got sync cmd even though server not connected");
			}										//check for null
			server.connected = true;				// we are connected, no longer waiting for a connection, setting sync time counter to 0
			server.waiting = false;
			server.time_since_last_sync = 0;
		}
		print("reply got from backend");			//the backend got our query at some point and sent us back some info
	}
	if(cmd == this.getCommandID("get_player_info")){
		BackendPlayer p();
		p.username = params.read_string();
		p.team = 2;	//2 = auto 0=blue 1=red, will be changed later based on player input
		p.stats.clear();
		//rank, wins, losses, kills, deaths, + maybe more idk
		p.stats.push_back(''+params.read_u32());
		p.stats.push_back(''+params.read_u32());
		p.stats.push_back(''+params.read_u32());
		p.stats.push_back(''+params.read_u32());
		p.stats.push_back(''+params.read_u32());
		BackendPlayer@[]@ backend_players;
		if(!this.get("backend_players", @backend_players)){
			print("could not get backend_players in get_player_info cmd");
			return;
		}
		if(backend_players is null){//should never be null, even if it is empty
			print("backend_players is null in get_player_info cmd");
			return;
		}
		bool found = false;
		for(u8 i = 0; i < backend_players.length; i++)
		{
			if(p.username == backend_players[i].username){
				found = true;
			}
		}
		if(!found)
			backend_players.push_back(p);

		print("successfully accquired player info for " + p.username);
	}
	if(cmd == this.getCommandID("get_match_info")){
		Server@ s;
		if(!this.get("server", @s)){			//first, check if the server is null. it shouldnt be...
			print("cannot get server object in get_match_info cmd");
			return;
		}
		if(s is null){
			print("server obj is null in get_match_info cmd");	//should never happen theoretically. but i might be wrong
			return;
		}
		if(s.type != 0){//only use command for lobbies connected to the backend
			return;
		}
		Server@[]@ servers;
		if(!this.get("servers", @servers)){
			print("cannot get servers obj in get_match_info cmd");
			return;
		}
		if(servers is null){
			print("servers obj is null in get_match_info cmd");
			return;
		}
		Server server();
		server.type = 1;//only match servers here
		server.hostname = params.read_string();
		server.port = params.read_u16();
		server.id = params.read_u8();
		server.ready = params.read_u8(); 
		bool found = false;
		for(u8 i = 0; i < servers.length; i++){
			Server@ target = servers[i];
			if(target.hostname == server.hostname && target.port == server.port){
				target.type = server.type;
				target.id = server.id;
				target.ready = server.ready;
				found = true;
				print("updating match info for " + server.hostname + ":" + server.port + " in get_match_info cmd");
				break;
			}
		}
		if(!found){
			servers.push_back(server);
			print("adding match server " + server.hostname + ":" + server.port + " in get_match_info cmd");
		}
	}
	if(cmd == this.getCommandID("start_match")){
		
	}
	if(cmd == this.getCommandID("redirect_player")){

	}
	if(getNet().isClient() && cmd == this.getCommandID("sync_server_info")){
		string username;
		if(!params.saferead_string(username))
			return;
		CPlayer@ player = getPlayerByUsername(username);
		if(player is null)
			return;
		if(!player.isMyPlayer())
			return;
		bool connected;
		bool waiting;
		u8 type;
		string hostname;
		u16 port;
		u8 id;
		u8 ready;
		Server@ server;
		if(!this.get("server", @server)){			//first, check if the server is null. it shouldnt be...
			print("cannot get server object in sync server info cmd");
			return;
		}
		if(server is null){
			print("server obj is null in sync server info cmd");	//should never happen theoretically. but i might be wrong
			return;
		}
		if(!params.saferead_bool(connected))
			return;
		if(!params.saferead_bool(waiting))
			return;
		if(!params.saferead_u8(type))
			return;
		if(!params.saferead_string(hostname))
			return;
		if(!params.saferead_u16(port))
			return;
		if(!params.saferead_u8(id))
			return;
		if(!params.saferead_u8(ready))
			return;
		server.connected = connected;
		server.waiting = waiting;
		server.type = type;
		server.hostname = hostname;
		server.port = port;
		server.id = id;
		server.ready = ready;
		print("client got server info!!!"); 
	}
	if(getNet().isClient() && cmd == this.getCommandID("sync_players"))
	{
		string username;
		if(!params.saferead_string(username))
			return;
		CPlayer@ player = getPlayerByUsername(username);
		if(player is null)
			return;
		if(!player.isMyPlayer())
			return;
		BackendPlayer@[]@ backend_players;
		if(!this.get("backend_players", @backend_players)){
			print("could not get backend_players in get_player_info cmd");
	 		return;  
		}
		if(backend_players is null){//should never be null, even if it is empty
			print("backend_players is null in get_player_info cmd");
			return;
		}
		u8 num_players = params.read_u8();
		u8 stat_size = params.read_u8();
		for(int x = 0; x < num_players; x++)
		{
			BackendPlayer p();
			string player_username;
			if(!params.saferead_string(player_username))
				return;
			p.username = player_username;
			for(u8 i = 0; i < stat_size; i++)
			{
				string stat;
				if(!params.saferead_string(stat))
					return;
				p.stats.push_back(stat);
			}
			if(username == player_username)
				continue;
			backend_players.push_back(p);
		}
		print("client got player info!!!");
	}
	if(getNet().isClient() && cmd == this.getCommandID("sync_match_info"))
	{
		string username;
		if(!params.saferead_string(username))
			return;
		CPlayer@ player = getPlayerByUsername(username);
		if(player is null)
			return;
		if(!player.isMyPlayer())
			return;
		Server@[]@ servers;
		if(!this.get("servers", @servers)){
			print("cannot get servers obj in sync_match_info cmd");
			return;
		}
		if(servers is null){
			print("servers obj is null in sync_match_info cmd");
			return;
		}
		u8 size;
		if(!params.saferead_u8(size)) 
			return;
		for(u8 i = 0; i < size; i++){
			string hostname;
			if(!params.saferead_string(hostname))
				return;
			u16 port;
			if(!params.saferead_u16(port))
				return;
			u8 id;
			if(!params.saferead_u8(id))
				return;
			u8 ready;
			if(!params.saferead_u8(ready))
				return;	
			Server server();
			server.type = 1;//only match servers here
			server.hostname = hostname;
			server.port = port;
			server.id = id;
			server.ready = ready; 
			servers.push_back(server);
		}
	}
} 

void onNewPlayerJoin(CRules@ this, CPlayer@ player){
	if(!getNet().isServer() || player is null || player.isBot()) return;

	Server@ server;
	if(!this.get("server", @server))//first, check if the server is null. it shouldnt be...
	{			
		print("cannot get server object in onNewPlayerJoin");
		return;
	}
	if(server is null)
	{	
		print("server is null in onNewPlayerJoin");
		return; 
	}
 
	if(server.connected) 
	{ 
		CBitStream server_stream;
		server_stream.write_string(player.getUsername());
		server_stream.write_bool(server.connected);
		server_stream.write_bool(server.waiting);
		server_stream.write_u8(server.type);
		server_stream.write_string(server.hostname);
		server_stream.write_u16(server.port); 
		server_stream.write_u8(server.id);
		server_stream.write_u8(server.ready);
		this.SendCommand(this.getCommandID("sync_server_info"), server_stream);
	}

	BackendPlayer@[]@ backend_players;
	if(!this.get("backend_players", @backend_players))
	{
		print("could not get backend_players in onNewPlayerJoin");
		return;
	}
	if(backend_players is null)
	{//should never be null, even if it is empty
		print("backend_players is null in onNewPlayerJoin");
		return; 
	}

	if(backend_players.length != 0)
	{
		CBitStream player_stream;
		player_stream.write_string(player.getUsername());
		player_stream.write_u8(backend_players.length);
		player_stream.write_u8(backend_players[0].stats.length);//tells us how big the stats array is so we know when to read the next player
		for(u8 i = 0; i < backend_players.length; i++)
		{
			BackendPlayer@ player = backend_players[i];
			player_stream.write_string(player.username);
			for(u8 j = 0; j < player.stats.length; j++)
			{
				player_stream.write_string(player.stats[j]);
			}
		} 
		this.SendCommand(this.getCommandID("sync_players"), player_stream);
	}
	if(server.type == 0){
		Server@[]@ servers;
		if(!this.get("servers", @servers)){
			print("cannot get servers obj in onNewPlayerJoin");
			return;
		}
		if(servers is null){
			print("servers obj is null in onNewPlayerJoin");
			return;
		}
		CBitStream match_info_stream;
		match_info_stream.write_string(player.getUsername());
		match_info_stream.write_u8(servers.length);
		for(u8 i = 0; i < servers.length; i++)
		{
			Server@ server = servers[i];
			if(server !is null){
				match_info_stream.write_string(server.hostname);
				match_info_stream.write_u16(server.port);
				match_info_stream.write_u8(server.id);
				match_info_stream.write_u8(server.ready);
			}
			else{
				print("error sending match info sync cmd");
			}
		}
		this.SendCommand(this.getCommandID("sync_match_info"), match_info_stream);
	}
}

void onPlayerLeave(CRules@ this, CPlayer@ player){
	BackendPlayer@[]@ backend_players;
	if(!this.get("backend_players", @backend_players)){
		print("could not get backend_players in onplayerleave");
		return;
	}
	if(backend_players is null){//should never be null, even if it is empty
		print("backend_players is null in onplayerleave");
		return;
	}
	if(backend_players.length == 0){
		print("backend_players.length is 0 while a player is leaving");	
		return;															
	}
	for(u8 i = 0; i < backend_players.length; i++){
		if(backend_players[i].username == player.getUsername()){
			backend_players.removeAt(i);
			print("successfully removed backendplayer on leave from " + player.getUsername() + "  backendplayers left: " + backend_players.length);
			break;
		}
	} 
}   