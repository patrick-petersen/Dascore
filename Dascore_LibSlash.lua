----------[Global variables]----------------------------------------------
Dascore_LibSlash ={}		--Global package
----------[Initialization]----------------------------------------------
function Dascore_LibSlash.OnInitialize()
	if LibSlash then
		LibSlash.RegisterSlashCmd("dascore", Dascore.Win1.Show)
		EA_ChatWindow.Print(L"daScore: type /dascore for results window")
	end
end

