function firstTime()
	executeSQLQuery("CREATE TABLE IF NOT EXISTS VOLTgangdb (gangname TEXT, money NUMERIC, hometext TEXT, inviteperm NUMERIC, motdperm NUMERIC, kickperm NUMERIC, levelperm NUMERIC, warnperm NUMERIC, depositperm NUMERIC, withdrawperm NUMERIC, deleteperm NUMERIC);")
end
addEventHandler("onResourceStart", resourceRoot, firstTime)