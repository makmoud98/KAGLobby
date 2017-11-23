// Backend helper functions

namespace Backend
{
	void RedirectBackToLobby( CRules@ this )
	{
		string adr = this.get_string("last lobby address");
		if (adr == ""){
			warn("Lobby address to redirect not found");
			// disconnect players
			for (uint i = 0; i < getPlayersCount(); i++)
			{
				getNet().DisconnectPlayer(getPlayer(i));
			}			
			return;
		}

		print("Redirecting all players to " + adr);

		for (uint i = 0; i < getPlayersCount(); i++)
		{
			CPlayer@ player = getPlayer(i);
			if (!player.isBot())
			{
				RedirectPlayer( this, player, adr, "");
			}
		}		
	}	

	void RedirectPlayer( CRules@ this, CPlayer@ player, const string &in address, const string &in password )
	{
		if (player is null || player.isBot()){
			return;
		}
		print("Redirecting " + player.getUsername() );

		CBitStream params;
		params.write_string( address );
	 	params.write_string( password );
		params.write_netid( player.getNetworkID() );
		this.SendCommand( this.getCommandID("redirect"), params, player);
	}
}