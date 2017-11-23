string _reconnectAddress = "";
string _password = "";

void onInit(CRules@ this)
{
	this.addCommandID("redirect");
}

void onTick(CRules@ this)
{
	if (_reconnectAddress != "")
	{
		CNet@ net = getNet();
		string temp = _reconnectAddress;
		_reconnectAddress = "";
		printf("Client: SafeConnect by backend");
		cl_password = _password;
		_password = "";
		net.DisconnectClient();
		net.SafeConnect(temp);
	}
}

void onCommand(CRules@ this, u8 cmd, CBitStream @params)
{
	if (getNet().isClient() && cmd == this.getCommandID("redirect"))
	{
		string address = params.read_string();
		string password = params.read_string();
		CPlayer@ player = getPlayerByNetworkId(params.read_netid());
		if (player !is null && player.isMyPlayer())
		{
			print("Backend redirecting to " + address);
			_reconnectAddress = address;
			_password = password;
		}
	}
}