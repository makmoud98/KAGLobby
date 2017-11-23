class Server{
	bool connected;		//false until makes contact with backend
	bool waiting;		//waiting for a reply or no
	u8 type;			//0=lobby, 1=match
	string hostname;	
	u32 port;			
	u32 id;				
	string password;	//password to server, backendclient.as will need this
	u8 ready;			//used for match servers to see if they aree ready to be joined 0=true 1=false
	u32 time_since_last_sync;
	string[] que;

	Server() {
		connected = false; 
		waiting = true;
		time_since_last_sync = 0;
	}		

	void connectBackend(){
		tcpr('|BACKEND| connect');
	}

	void queryBackend(){ 	//used to query the server with the backend, used by both lobby and server
		tcpr('|BACKEND| check');
	}

	void queryPlayerInfo(string player){	//used to ask the backend to give the server the stats about the player, ex: rank, kills, deaths, will aslo check if player should be somewhere else
		que.push_back('|BACKEND| getinfo;'+player);
	}

	void queryMatchInfo(){//not used anymore, backend auto sends match info updates
		que.push_back('|BACKEND| getmatchinfo');
	}

	void updatePlayerInfo(BackendPlayer@ player){	//updates the database with info about a match, win/loss, kills/deaths that round, more stats may be added in the future
		string list_stats = "";
		for(u8 i = 0; i < player.stats.length; i++){
			list_stats += ";" + player.stats[i];
		}
		que.push_back('|BACKEND| update;'+player.username+";"+list_stats);
	}
		
	void startMatch(u8 id, BackendPlayer@[]@ players){	//starts a match given the id of the match server and the list of players. the backend will sort the teams once they connect to the server
		string list = "";
		for(u8 i = 0; i < players.length; i++){
			BackendPlayer@ player = players[i];
			if(player !is null){
				list += ";"+player.username + ';'+ player.stats[0] + ';' + player.team;
			}
		}
		que.push_back('|BACKEND| start;'+id+list);
	}

	void endMatch(u32 len){	//just tell the server to end the match and restart the match server, only sent after all players have been redirected from the server
		que.push_back('|BACKEND| end;'+len);
	}	
};

class BackendPlayer{
	string username;	//player's username	
	string[] stats;		//any info sent by the backend about the player, ex: rank, kills, deaths, etc
	string[] tag;		//used for clientside scoreboard stuff 
	u8 team;

	BackendPlayer() {}	
};