#include "LobbyCommon.as"

bool onServerProcessChat(CRules@ this, const string& in text_in, string& out text_out, CPlayer@ player){
	if(player is null){
		return false;
	}
	if(!getNet().isServer()){
		return false;
	}
	if(sv_test){
		string botname = "tom";
		CPlayer@ bot = getPlayerByUsername(botname);
		string[]@ tokens = text_in.split(" ");
		if(tokens.length == 2){
			if(tokens[0] == "!test"){
				string cmd = tokens[1];
				if(cmd == "spawn"){
					AddBot(botname);
				}
				else if(cmd == "create" && bot !is null){
					create_party(this, botname);
				}
				else if(cmd == "leave" && bot !is null){
					leave_party(this, botname);
				}
				return false;
			}
		}
		else if(tokens.length == 3 && bot !is null){
			if(tokens[0] == "!test"){
				string cmd = tokens[1];
				if(cmd == "invite"){
					invite_player(this, botname, tokens[2]);
				}
				else if(cmd == "kick"){
					kick_player(this, botname, tokens[2]);
				}
				else if(cmd == "join"){
					join_party(this, tokens[2], botname);
				}
				else if(cmd == "revoke"){
					revoke_invite(this, botname, tokens[2]);
				}
				return false;
			}
		}
	}
	return true;
}