local npcTalk = nil

local Tutorial = {
	ped = {
		npc = 's_m_m_dockwork_01',
		coords = vec4(-599.69, 2093.15, 130.31, 347.62),
		heading = 347.62,
		name = 'Seu Fábio',
		tag = 'MINERADOR',
		animScenario = 'WORLD_HUMAN_CLIPBOARD',
		color = "green",
		startMSG = 'Você chegou longe hein! Posso te ensinar tudo sobre mineração.',
	},
	waypoints = {
		mines = {
			{ name = 'Mina 1', coords = vec3(2960.9, 2754.14, 43.33) },
			{ name = 'Mina 2', coords = vec3(-596.74, 2090.99, 131.41) },
		},
		washing = {
			{ name = 'Lavar 1', coords = vec3(1840.18, 412.43, 160.12) },
			{ name = 'Lavar 2', coords = vec3(-432.59, 2936.83, 13.87) },
			{ name = 'Lavar 3', coords = vec3(2500.64, 6129.4, 162.46) },
			{ name = 'Lavar 4', coords = vec3(907.06, 4377.66, 30.22) },
		},
		smelter = {
			{ name = 'Fundição', coords = vec3(1081.76, -1994.48, 30.99) },
		},
		jewels = {
			{ name = 'Vender Jóias', coords = vec3(-631.1, -241.18, 38.16) },
			{ name = 'Fabricar Jóias', coords = vec3(1074.8, -1986.04, 30.92) },
		},
		panning = {
			{ name = 'Garimpar 1', coords = vec3(-1410.58, 2005.91, 59.4) },
			{ name = 'Garimpar 2', coords = vec3(-1550.06, 1445.13, 116.37) },
			{ name = 'Garimpar 3', coords = vec3(-865.75, 4417.1, 15.25) },
		},
	},
}

local waypointOptions = { color = { 100, 255, 100, 100 }, clearEnter = false, blipId = 304, blipColor = 5 }

local function markWaypoints(list)
	for i = 1, #list do
		exports.pickle_waypoints:AddWaypoint(list[i].name, list[i].coords, waypointOptions)
	end
end

local function waypointOption(label, list)
	return { label = label, shouldClose = true, action = function() markWaypoints(list) end }
end

local function closeOption(label)
	return { label = label, shouldClose = true, action = function() end }
end

local function stepThree()
	exports['rep-talkNPC']:changeDialog("E depois é só fazer as 💍 joias para vender na joalheria. Mas lembrando que você também pode garimpar ✨ ouro e prata nessas localizações do seu GPS.  \nViu como é fácil? Agora que você já sabe como funciona, por que ainda está aqui olhando para minha cara? Vai trabalhar! 💼👊", {
		{ label = "Bora trabalhar!", action = function() end },
		waypointOption("Localizar 💍 joias.", Tutorial.waypoints.jewels),
		waypointOption("Localizar ✨ ouro e prata.", Tutorial.waypoints.panning),
	})
end

local function stepTwo()
	exports['rep-talkNPC']:changeDialog("Depois de minerar as pedras, você precisa ir a algumas dessas localizações e lavar as pedras. 💧  \nApós lavar as pedras, você vai precisar fundir elas, podendo ir nessa localização 🔥.", {
		{ label = "Entendido. E depois?", action = stepThree },
		waypointOption("Localizar locais para lavar minérios. 💧", Tutorial.waypoints.washing),
		waypointOption("Localizar fundição. 🔥", Tutorial.waypoints.smelter),
	})
end

local function stepOne()
	exports['rep-talkNPC']:changeDialog("👋 Olá, me chamo 😃**Fábio Henrique**, mas pode me chamar de **Fábio**.  \nAgora vou te explicar como funciona o emprego de ⛏️ minerador, é bem fácil.  \nEm seu GPS tem essas marcações, então basta ir até elas e minerar. Mas, para isso, você vai precisar de uma 🛠️ picareta ou algo mais profissional que pode ser adquirida na loja de ferramentas.", {
		{ label = "Entendido. E depois?", action = stepTwo },
		waypointOption("Marque as localizações!", Tutorial.waypoints.mines),
		closeOption("Ah sim... Tenho que fazer outra coisa."),
	})
end

local function createNPCtalk()
	if not Config.General.npcTalk or npcTalk then return end
	if not isStarted("rep-talkNPC") or not isStarted("pickle_waypoints") then return end
	npcTalk = exports['rep-talkNPC']:CreateNPC(Tutorial.ped, {
		{ label = "Como funciona esse trabalho?", shouldClose = false, action = stepOne },
		closeOption("Trabalhar/Finalizar"),
		closeOption("Talvez outra hora..."),
	})
end

local function deleteNPCtalk()
	if not npcTalk then return end
	DeleteEntity(npcTalk)
	npcTalk = nil
end

onPlayerLoaded(function() Wait(1000) createNPCtalk() end, true)
onResourceStop(deleteNPCtalk, true)
