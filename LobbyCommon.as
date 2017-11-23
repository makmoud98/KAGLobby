#include "BackendCommon.as";

class Party
{	
	BackendPlayer@[] members;
	BackendPlayer@[] invited;
	SColor color(255,0,0,0);

	Party(u8 r, u8 g, u8 b)
	{
		color.setRed(r);
		color.setGreen(g);
		color.setBlue(b);
	}
	bool invite(BackendPlayer@ player){
		for(int i = 0; i < invited.length; i++){
			BackendPlayer@ p = invited[i];
			if(player.username == p.username){
				return false;//player was already invited
			}
		}
		invited.push_back(player); 
		return true;
	}
	bool revokeInvitation(string username){
		for(int i = 0; i < invited.length; i++){
			BackendPlayer@ p = invited[i];
			if(p !is null && p.username == username){
				invited.removeAt(i);
				return true;
			}
		}
		return false;//this means the player was not even on the invitation list
	}
	BackendPlayer@ getInvitedByName(string username){
		for(int i = 0; i < invited.length; i++){
			BackendPlayer@ p = invited[i];
			if(p !is null && p.username == username){//found em
				return p;
			}
		}
		return null;//couldnt find em on the list
	}
	bool addMember(BackendPlayer@ member)
	{
		if(getMemberByName(member.username) is null && members.length < 5){
			this.members.push_back(member);
			return true;
		}
		else{
			print(member.username + " could not join " + getLeader().username + "'s party because it is full");
			return false;
		}
	}
	bool removeMember(string username, bool kicked = false)
	{
		for(u8 i = 0; i < members.length; i++){
			BackendPlayer@ member = members[i];
			if(member !is null && member.username == username){
				if(kicked){
					revokeInvitation(username);
				}
				members.removeAt(i);
				i--;
			}
			else if(member is null){
				members.removeAt(i);
				i--;
			}
		}
		if(members.length == 0)
			return true;//return true cuz party is empty
		return false;
	}
	BackendPlayer@ getMemberByName(string username){
		for(u8 i = 0; i < members.length; i++){
			BackendPlayer@ member = members[i];
			if(member !is null && member.username == username){
				return member;
			}
		}
		return null;
	}
	bool assignLeader(BackendPlayer@ member)
	{
		s8 found = -1;
		for(u8 i = 0; i < members.length; i++)
		{
			if(member is members[i])
			{
				found = i;
			}
		}
		if(found == -1){
			print("member not found in assignLeader");
			return false;
		}
		if(found == 0){
			print("member is already leader im assignLeader");
			return false;
		}
		print(member.username + " is now the leader of " + members[0].username + "'s party");
		members.removeAt(found);
		members.insertAt(0, member);
		return true;
	}
	BackendPlayer@ getLeader()
	{
		if(members.length > 0){
			return members[0];
		}
		return null;
	}	
};

void create_party(CRules@ rules, string owner){
	if(sv_test){
		print("create_party()");
	}
	Random@ r = Random(getGameTime());
	CBitStream params; 
	params.write_string(owner);
	params.write_u8(r.NextRanged(200));
	params.write_u8(r.NextRanged(200));
	params.write_u8(r.NextRanged(200));
	rules.SendCommand(rules.getCommandID("create_party"), params);
}

void leave_party(CRules@ rules, string member){
	if(sv_test){
		print("leave_party()");
	} 
	CBitStream params;
	params.write_string(member); 
	rules.SendCommand(rules.getCommandID("leave_party"), params);
}

void invite_player(CRules@ rules, string owner, string invited){
	if(sv_test){
		print("invite_player()");
	}
	CBitStream params;
	params.write_string(owner);
	params.write_string(invited);
	rules.SendCommand(rules.getCommandID("invite_player"), params);
}

void kick_player(CRules@ rules, string owner, string kicked){
	if(sv_test){
		print("kick_player()");
	}
	CBitStream params;
	params.write_string(owner);
	params.write_string(kicked);
	rules.SendCommand(rules.getCommandID("kick_player"), params);
}

void join_party(CRules@ rules, string owner, string joined){
	if(sv_test){
		print("join_party()");
	}
	CBitStream params;
	params.write_string(owner);
	params.write_string(joined);
	rules.SendCommand(rules.getCommandID("join_party"), params);
}

void revoke_invite(CRules@ rules, string owner, string revoked){
	if(sv_test){
		print("revoke_invite()");
	}
	CBitStream params;
	params.write_string(owner);
	params.write_string(revoked);
	rules.SendCommand(rules.getCommandID("revoke_invite"), params);
}