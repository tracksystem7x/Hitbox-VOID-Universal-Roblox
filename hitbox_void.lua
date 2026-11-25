if getgenv and getgenv().UniversalTargetLockLoaded then
	getgenv().UniversalTargetLockActive = not getgenv().UniversalTargetLockActive
	if getgenv().SetTargetLockUI then
		getgenv().SetTargetLockUI(getgenv().UniversalTargetLockActive)
	end
	warn("[The VOID Painel] Alternado para:", getgenv().UniversalTargetLockActive and "ON" or "OFF")
	return
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local StatsService = game:GetService("Stats")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- ==========================================
-- CONFIGURACAO GERAL
-- ==========================================
local TECLA_ATALHO = Enum.KeyCode.E
local TECLA_KILL_AURA = Enum.KeyCode.Q
local TECLA_PAINEL = Enum.KeyCode.J
local TECLA_ESPECIAL = Enum.KeyCode.G
local JANELA_ESPECIAL_SEG = 1.2

local DISTANCIA_MAXIMA = 25
local MARGEM_TROCA = 4.0
local FIRMEZA_GIRO = 1.0
local ORBITAR = false

local DISTANCIA_COSTAS = 3.2
local DISTANCIA_MAXIMA_COSTAS = 45

local DISTANCIA_KILL_AURA = 28
local MARGEM_PERSISTENCIA_KILL_AURA = 5
local DELAY_KILL_AURA = 0.001
local RAJADA_KILL_AURA = 3
local KILL_AURA_PULSO_ALVO = false
local DURACAO_PULSO_MIRA = 0.008

local ATIVAR_AUTOCLICK_JUNTO = true
local DELAY_CLIQUE = 0.001
local RAJADA_AUTOCLICK = 3

local WALKSPEED_BASE = 16
local JUMPPOWER_BASE = 50

local TARGET_LOCK_PADRAO_HABILITADO = true
local BACK_COSTAS_PADRAO_ATIVO = false
local ANTI_RAGDOLL_PADRAO_ATIVO = false
local ANTI_GRAB_RAG_PADRAO_ATIVO = false
local DEATH_TP_PADRAO_ATIVO = false
local NO_SLOW_PADRAO_ATIVO = false
local KILL_AURA_PADRAO_ATIVO = false
local NO_ANIMATION_PADRAO_ATIVO = false
local HUD_LOSANGO_PADRAO_VISIVEL = true
local HUD_STATS_PADRAO_VISIVEL = true

local SPEED_PADRAO_ATIVO = false
local SPEED_VALOR_PADRAO = 16
local SPEED_MIN = 1
local SPEED_MAX = 200
local MODOS_SPEED = { "CFrame", "WalkSpeed", "Passo" }

local JUMP_MULT_PADRAO_ATIVO = false
local JUMP_MULT_PADRAO = 1
local JUMP_MULT_MIN = 1
local JUMP_MULT_MAX = 5

local HITBOX_PADRAO_ATIVO = false
local HITBOX_TAMANHO_PADRAO = 12
local HITBOX_MAX_SLIDER = 40
local HITBOX_VISIVEL_PADRAO = true
local HITBOX_TRANSPARENCIA_VISIVEL = 0.965
local COR_HITBOX_AURA = Color3.fromRGB(220, 55, 55)

-- Tema Roxo Nexus
local ROXO_NEXUS = Color3.fromRGB(155, 65, 255)
local BOTAO_CINZA = Color3.fromRGB(42, 42, 50)
local BOTAO_ROXO_ON = Color3.fromRGB(145, 50, 250)
local POSICAO_PAINEL_PADRAO = UDim2.new(1, -214, 1, -486)
-- ==========================================

if getgenv then
	getgenv().UniversalTargetLockLoaded = true
	getgenv().UniversalTargetLockActive = false
end

local ativo = false
local targetLockHabilitadoNoPainel = TARGET_LOCK_PADRAO_HABILITADO
local backCostasAtivo = BACK_COSTAS_PADRAO_ATIVO
local antiRagdollAtivo = ANTI_RAGDOLL_PADRAO_ATIVO
local antiGrabRagAtivo = ANTI_GRAB_RAG_PADRAO_ATIVO
local deathTpAtivo = DEATH_TP_PADRAO_ATIVO
local noSlowAtivo = NO_SLOW_PADRAO_ATIVO
local killAuraAtivo = KILL_AURA_PADRAO_ATIVO
local noAnimationAtivo = NO_ANIMATION_PADRAO_ATIVO
local hudLosangoVisivel = HUD_LOSANGO_PADRAO_VISIVEL
local hudStatsVisivel = HUD_STATS_PADRAO_VISIVEL

local speedAtivo = SPEED_PADRAO_ATIVO
local speedValor = SPEED_VALOR_PADRAO
local speedModoIndex = 1

local jumpMultAtivo = JUMP_MULT_PADRAO_ATIVO
local jumpMultValor = JUMP_MULT_PADRAO

local boostFpsRedeAtivo = false

local alvoAtual = nil
local alvoKillAuraPlayer = nil
local ultimoDisparoKillAuraTick = 0
local ultimoDisparoAutoClickTick = 0

local hitboxAtivo = HITBOX_PADRAO_ATIVO
local hitboxVisivel = HITBOX_VISIVEL_PADRAO
local hitboxSize = HITBOX_TAMANHO_PADRAO
local amgTexto = ""
local focusTexto = ""
local backFilterTexto = ""

local originaisRoot = {}
local ultimoEstadoAplicado = {}
local marcadoresJogadores = {}
local animConexoes = {}
local ultimoEspecialTick = 0
local ultimoToggleKillAura = 0
local pulsoMiraAte = 0
local yawAntesPulso = nil
local yawAplicadoNoPulso = nil
local ultimaPosicaoMorte = nil
local morteRegistradaNestaVida = false
local snapshotGraficoSalvo = nil

local btnKillAuraUI
local btnAutoClickUI
local kaBadgeUI

local function atualizarKillAuraUI(ligado)
	if btnKillAuraUI then
		btnKillAuraUI.Text = ligado and "Kill Aura (Q): ON" or "Kill Aura (Q): OFF"
		btnKillAuraUI.BackgroundColor3 = ligado and BOTAO_ROXO_ON or BOTAO_CINZA
	end
	if kaBadgeUI then
		kaBadgeUI.Text = ligado and "KA: ON" or "KA: OFF"
		kaBadgeUI.TextColor3 = ligado and Color3.fromRGB(185, 115, 255) or Color3.fromRGB(185, 185, 200)
	end
end

local function setKillAuraEstado(novoEstado)
	local agora = os.clock()
	if (agora - ultimoToggleKillAura) < 0.05 and novoEstado ~= killAuraAtivo then
		return
	end
	ultimoToggleKillAura = agora
	killAuraAtivo = novoEstado
	if not killAuraAtivo then
		alvoKillAuraPlayer = nil
		pulsoMiraAte = 0
		yawAntesPulso = nil
		yawAplicadoNoPulso = nil
	end
	atualizarKillAuraUI(killAuraAtivo)
end

-- ==========================================
-- OTIMIZACAO DE FPS E LIMPEZA VISUAL / REDE LEVE
-- ==========================================
local function aplicarOtimizacaoFpsERede(ativar)
	boostFpsRedeAtivo = ativar

	if ativar then
		if not snapshotGraficoSalvo then
			snapshotGraficoSalvo = {
				GlobalShadows = Lighting.GlobalShadows
			}
		end

		pcall(function()
			Lighting.GlobalShadows = false
			Lighting.EnvironmentSpecularScale = 0
			Lighting.EnvironmentDiffuseScale = 0
			for _, obj in ipairs(Lighting:GetChildren()) do
				if obj:IsA("PostEffect") or obj:IsA("Atmosphere") or obj:IsA("Clouds") then
					obj.Enabled = false
				end
			end
		end)

		pcall(function()
			if settings and settings().Rendering then
				settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
			end
		end)

		pcall(function()
			local ws = workspace
			if ws.Terrain then
				ws.Terrain.Decoration = false
				ws.Terrain.WaterWaveSize = 0
				ws.Terrain.WaterWaveSpeed = 0
				ws.Terrain.WaterReflectance = 0
				ws.Terrain.WaterTransparency = 1
			end
			for _, desc in ipairs(ws:GetDescendants()) do
				if desc:IsA("ParticleEmitter") or desc:IsA("Fire") or desc:IsA("Smoke") or desc:IsA("Sparkles") then
					desc.Enabled = false
				elseif desc:IsA("Trail") or desc:IsA("Beam") then
					desc.Enabled = false
				elseif desc:IsA("Decal") or desc:IsA("Texture") then
					desc.Transparency = math.max(desc.Transparency, 0.85)
				elseif desc:IsA("BasePart") then
					desc.CastShadow = false
				end
			end
		end)

		pcall(function()
			if setfpscap then
				setfpscap(60)
			end
		end)
		pcall(function()
			if collectgarbage then
				collectgarbage("collect")
			end
		end)
	else
		if snapshotGraficoSalvo then
			pcall(function()
				Lighting.GlobalShadows = snapshotGraficoSalvo.GlobalShadows
				for _, obj in ipairs(Lighting:GetChildren()) do
					if obj:IsA("PostEffect") or obj:IsA("Atmosphere") or obj:IsA("Clouds") then
						obj.Enabled = true
					end
				end
			end)
			pcall(function()
				if settings and settings().Rendering then
					settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
				end
			end)
		end
	end
end

local function getGuiParent()
	local ok, res = pcall(function()
		local test = Instance.new("ScreenGui")
		test.Name = "LockGuiTest"
		test.Parent = CoreGui
		test:Destroy()
		return CoreGui
	end)
	if ok and res then return res end
	return LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 5)
end

local parentGui = getGuiParent()

local losangoGuiRoot, losangoUI, statusUI, statsLabelUI

local function lerPingMs()
	local ok, pingVal = pcall(function()
		local net = StatsService and StatsService:FindFirstChild("Network")
		local item = net and net:FindFirstChild("ServerStatsItem")
		local pingItem = item and item:FindFirstChild("Data Ping")
		if pingItem and typeof(pingItem.GetValue) == "function" then
			return pingItem:GetValue()
		end
		return nil
	end)
	if ok and typeof(pingVal) == "number" and pingVal >= 0 then
		return math.floor(pingVal + 0.5)
	end
	return nil
end

local function criarIndicadorUI()
	if not parentGui then return end
	local antiga = parentGui:FindFirstChild("UniversalLockDiamondHUD")
	if antiga then antiga:Destroy() end

	local gui = Instance.new("ScreenGui")
	gui.Name = "UniversalLockDiamondHUD"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Enabled = hudLosangoVisivel
	gui.Parent = parentGui

	local holder = Instance.new("Frame")
	holder.Name = "DiamondHolder"
	holder.Size = UDim2.new(0, 148, 0, 56)
	holder.Position = UDim2.new(0, 14, 0, 66)
	holder.BackgroundTransparency = 1
	holder.Parent = gui

	local losango = Instance.new("Frame")
	losango.Name = "DiamondShape"
	losango.Size = UDim2.new(0, 22, 0, 22)
	losango.Position = UDim2.new(0, 17, 0, 17)
	losango.AnchorPoint = Vector2.new(0.5, 0.5)
	losango.Rotation = 45
	losango.BackgroundColor3 = Color3.fromRGB(220, 45, 45)
	losango.BorderSizePixel = 0
	losango.Parent = holder

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Thickness = 1.5
	stroke.Transparency = 0.25
	stroke.Parent = losango

	local textoEstado = Instance.new("TextLabel")
	textoEstado.Name = "StatusLabel"
	textoEstado.Size = UDim2.new(0, 44, 0, 22)
	textoEstado.Position = UDim2.new(0, 36, 0, 17)
	textoEstado.AnchorPoint = Vector2.new(0, 0.5)
	textoEstado.BackgroundTransparency = 1
	textoEstado.Text = "OFF"
	textoEstado.TextColor3 = Color3.fromRGB(235, 65, 65)
	textoEstado.TextStrokeTransparency = 0.2
	textoEstado.Font = Enum.Font.GothamBold
	textoEstado.TextSize = 13
	textoEstado.TextXAlignment = Enum.TextXAlignment.Left
	textoEstado.Parent = holder

	local kaBadge = Instance.new("TextLabel")
	kaBadge.Name = "KillAuraBadge"
	kaBadge.Size = UDim2.new(0, 64, 0, 20)
	kaBadge.Position = UDim2.new(0, 78, 0, 17)
	kaBadge.AnchorPoint = Vector2.new(0, 0.5)
	kaBadge.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
	kaBadge.BackgroundTransparency = 0.2
	kaBadge.Text = "KA: OFF"
	kaBadge.TextColor3 = Color3.fromRGB(185, 185, 200)
	kaBadge.TextStrokeTransparency = 0.25
	kaBadge.Font = Enum.Font.GothamBold
	kaBadge.TextSize = 10
	kaBadge.Parent = holder
	Instance.new("UICorner", kaBadge).CornerRadius = UDim.new(0, 4)
	local kaStroke = Instance.new("UIStroke")
	kaStroke.Color = ROXO_NEXUS
	kaStroke.Thickness = 1
	kaStroke.Parent = kaBadge

	local statsLabel = Instance.new("TextLabel")
	statsLabel.Name = "FpsPingLabel"
	statsLabel.Size = UDim2.new(1, 0, 0, 18)
	statsLabel.Position = UDim2.new(0, 4, 0, 34)
	statsLabel.BackgroundTransparency = 1
	statsLabel.Text = "FPS: -- | -- MS"
	statsLabel.TextColor3 = Color3.fromRGB(235, 235, 245)
	statsLabel.TextStrokeTransparency = 0.25
	statsLabel.Font = Enum.Font.GothamBold
	statsLabel.TextSize = 11
	statsLabel.TextXAlignment = Enum.TextXAlignment.Left
	statsLabel.Visible = hudStatsVisivel
	statsLabel.Parent = holder

	losangoGuiRoot = gui
	losangoUI = losango
	statusUI = textoEstado
	kaBadgeUI = kaBadge
	statsLabelUI = statsLabel
	atualizarKillAuraUI(killAuraAtivo)
end

criarIndicadorUI()

local function atualizarVisual(ligado)
	if losangoUI then
		losangoUI.BackgroundColor3 = ligado and Color3.fromRGB(35, 205, 95) or Color3.fromRGB(220, 45, 45)
	end
	if statusUI then
		statusUI.Text = ligado and "ON" or "OFF"
		statusUI.TextColor3 = ligado and Color3.fromRGB(70, 235, 120) or Color3.fromRGB(235, 65, 65)
	end
	if btnAutoClickUI then
		btnAutoClickUI.Text = ligado and "AutoClick VOID (E): ON" or "AutoClick VOID (E): OFF"
		btnAutoClickUI.BackgroundColor3 = ligado and BOTAO_ROXO_ON or BOTAO_CINZA
	end
end

local function setEstado(novoEstado)
	ativo = novoEstado
	if not ativo then
		alvoAtual = nil
	end
	if getgenv then
		getgenv().UniversalTargetLockActive = ativo
	end
	atualizarVisual(ativo)
end

if getgenv then
	getgenv().SetTargetLockUI = atualizarVisual
end

atualizarVisual(false)

-- ==========================================
-- NO ANIMATION + SILENCIAR SOM DE ATAQUE (SOCO / G)
-- ==========================================
local NOMES_MOVIMENTO_PADRAO = {
	"idle", "walk", "run", "jump", "fall", "swim", "climb", "land", "freefall", "running", "walking"
}

local PALAVRAS_ACAO_SOCO_G = {
	"punch", "hit", "attack", "atk", "combat", "fight", "combo",
	"grab", "catch", "special", "ult", "skill", "ability", "g_", "kick", "slap", "swing", "impact"
}

local function contemPalavra(texto, lista)
	if not texto or texto == "" then return false end
	local low = string.lower(texto)
	for _, p in ipairs(lista) do
		if string.find(low, p, 1, true) then
			return true
		end
	end
	return false
end

local function silenciarSomSeAtaque(inst)
	if not noAnimationAtivo or not inst then return end
	if inst:IsA("Sound") then
		local nomeSom = inst.Name or ""
		local paiNome = (inst.Parent and inst.Parent.Name) or ""
		if contemPalavra(nomeSom, PALAVRAS_ACAO_SOCO_G) or contemPalavra(paiNome, PALAVRAS_ACAO_SOCO_G) or (os.clock() - ultimoEspecialTick) <= JANELA_ESPECIAL_SEG then
			pcall(function()
				inst.Volume = 0
				inst:Stop()
			end)
		end
	end
end

local function limparSonsAtaqueNoPersonagem(char)
	if not noAnimationAtivo or not char then return end
	for _, desc in ipairs(char:GetDescendants()) do
		silenciarSomSeAtaque(desc)
	end
end

local function ehAnimacaoMovimentoPadrao(track)
	if not track then return false end

	local okPrio, prio = pcall(function() return track.Priority end)
	if okPrio and prio then
		if prio == Enum.AnimationPriority.Core or prio == Enum.AnimationPriority.Idle or prio == Enum.AnimationPriority.Movement then
			local nomeTrack = string.lower(track.Name or "")
			local nomeAnim = (track.Animation and string.lower(track.Animation.Name or "")) or ""
			if not contemPalavra(nomeTrack, PALAVRAS_ACAO_SOCO_G) and not contemPalavra(nomeAnim, PALAVRAS_ACAO_SOCO_G) then
				return true
			end
		end
	end

	local nomeTrack = track.Name or ""
	local nomeAnim = (track.Animation and track.Animation.Name) or ""
	if contemPalavra(nomeTrack, NOMES_MOVIMENTO_PADRAO) or contemPalavra(nomeAnim, NOMES_MOVIMENTO_PADRAO) then
		if not contemPalavra(nomeTrack, PALAVRAS_ACAO_SOCO_G) and not contemPalavra(nomeAnim, PALAVRAS_ACAO_SOCO_G) then
			return true
		end
	end

	return false
end

local function deveCortarTrack(track)
	if not noAnimationAtivo or not track then return false end
	if ehAnimacaoMovimentoPadrao(track) then
		return false
	end

	local nomeTrack = track.Name or ""
	local nomeAnim = (track.Animation and track.Animation.Name) or ""

	if contemPalavra(nomeTrack, PALAVRAS_ACAO_SOCO_G) or contemPalavra(nomeAnim, PALAVRAS_ACAO_SOCO_G) then
		return true
	end

	local okPrio, prio = pcall(function() return track.Priority end)
	if okPrio and prio then
		local ehAction = (prio == Enum.AnimationPriority.Action)
			or (pcall(function() return prio == Enum.AnimationPriority.Action2 end) and prio == Enum.AnimationPriority.Action2)
			or (pcall(function() return prio == Enum.AnimationPriority.Action3 end) and prio == Enum.AnimationPriority.Action3)
			or (pcall(function() return prio == Enum.AnimationPriority.Action4 end) and prio == Enum.AnimationPriority.Action4)

		if ehAction then
			return true
		end
	end

	if (os.clock() - ultimoEspecialTick) <= JANELA_ESPECIAL_SEG then
		return true
	end

	return false
end

local function cortarSeAplicavel(track)
	if deveCortarTrack(track) then
		pcall(function()
			track:Stop(0)
			track:AdjustWeight(0, 0)
		end)
	end
end

local function limparConexoesAnim()
	for _, conn in ipairs(animConexoes) do
		pcall(function() conn:Disconnect() end)
	end
	table.clear(animConexoes)
end

local function checarTracksHumanoid(hum)
	if not hum then return end
	local animator = hum:FindFirstChildOfClass("Animator")
	if animator then
		for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
			cortarSeAplicavel(track)
		end
	end
	for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
		cortarSeAplicavel(track)
	end
end

local function sincronizarNoAnimation()
	local char = LocalPlayer.Character
	if not char then return end

	local animate = char:FindFirstChild("Animate")
	if animate and animate:IsA("LocalScript") and animate.Disabled then
		pcall(function() animate.Disabled = false end)
	end

	limparConexoesAnim()
	local hum = char:FindFirstChildOfClass("Humanoid")
	if noAnimationAtivo then
		checarTracksHumanoid(hum)
		limparSonsAtaqueNoPersonagem(char)
	end

	if hum then
		local animator = hum:FindFirstChildOfClass("Animator")
		if animator then
			table.insert(animConexoes, animator.AnimationPlayed:Connect(function(track)
				cortarSeAplicavel(track)
			end))
		end
		table.insert(animConexoes, hum.AnimationPlayed:Connect(function(track)
			cortarSeAplicavel(track)
		end))
	end

	table.insert(animConexoes, char.DescendantAdded:Connect(function(desc)
		silenciarSomSeAtaque(desc)
	end))
end

-- ==========================================
-- DEATH TP (SALVA POSICAO DA MORTE E VOLTA AO RENASCER)
-- ==========================================
local function registrarMorteSeNecessario(char)
	if morteRegistradaNestaVida then return end
	local targetChar = char or LocalPlayer.Character
	if not targetChar then return end
	local root = targetChar:FindFirstChild("HumanoidRootPart") or targetChar.PrimaryPart
	if root then
		ultimaPosicaoMorte = root.CFrame + Vector3.new(0, 3, 0)
		morteRegistradaNestaVida = true
	end
end

local function conectarMonitorMorte(char)
	morteRegistradaNestaVida = false
	if not char then return end

	local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 5)
	if hum then
		hum.Died:Connect(function()
			registrarMorteSeNecessario(char)
		end)
		hum:GetPropertyChangedSignal("Health"):Connect(function()
			if hum.Health <= 0 then
				registrarMorteSeNecessario(char)
			end
		end)
	end
end

local function recuperarEstadoAposQueda(novoChar)
	alvoAtual = nil
	alvoKillAuraPlayer = nil
	pulsoMiraAte = 0
	yawAntesPulso = nil
	yawAplicadoNoPulso = nil

	atualizarVisual(ativo)
	atualizarKillAuraUI(killAuraAtivo)

	task.spawn(function()
		local hum = novoChar:FindFirstChildOfClass("Humanoid") or novoChar:WaitForChild("Humanoid", 5)
		if hum then
			pcall(function()
				if hum:GetState() == Enum.HumanoidStateType.Dead or hum:GetState() == Enum.HumanoidStateType.Ragdoll then
					hum:ChangeState(Enum.HumanoidStateType.GettingUp)
				end
			end)
		end
		local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
		if backpack and hum then
			task.wait(0.25)
			local jaTemTool = novoChar:FindFirstChildOfClass("Tool")
			if not jaTemTool then
				for _, item in ipairs(backpack:GetChildren()) do
					if item:IsA("Tool") then
						pcall(function()
							hum:EquipTool(item)
						end)
						break
					end
				end
			end
		end
	end)
end

if LocalPlayer.Character then
	conectarMonitorMorte(LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(function(novoChar)
	local destinoMorte = ultimaPosicaoMorte
	conectarMonitorMorte(novoChar)
	recuperarEstadoAposQueda(novoChar)

	if deathTpAtivo and destinoMorte then
		task.spawn(function()
			local root = novoChar:FindFirstChild("HumanoidRootPart") or novoChar:WaitForChild("HumanoidRootPart", 5)
			local hum = novoChar:FindFirstChildOfClass("Humanoid") or novoChar:WaitForChild("Humanoid", 5)
			if root then
				for _ = 1, 8 do
					if not root or not root.Parent then break end
					pcall(function()
						if hum and hum.Sit then
							hum.Sit = false
						end
						root.AssemblyLinearVelocity = Vector3.zero
						root.AssemblyAngularVelocity = Vector3.zero
						root.CFrame = destinoMorte
					end)
					task.wait(0.03)
				end
			end
		end)
	end

	task.wait(0.2)
	sincronizarNoAnimation()
end)

task.spawn(function()
	while true do
		if noAnimationAtivo then
			local char = LocalPlayer.Character
			if char then
				local animate = char:FindFirstChild("Animate")
				if animate and animate:IsA("LocalScript") and animate.Disabled then
					pcall(function() animate.Disabled = false end)
				end
				local hum = char:FindFirstChildOfClass("Humanoid")
				checarTracksHumanoid(hum)
				limparSonsAtaqueNoPersonagem(char)
			end
		end
		task.wait(0.15)
	end
end)

-- Retorna valido APENAS se o jogador estiver vivo (Health > 0) e com HumanoidRootPart
local function getCharAndRoot(plr)
	local char = plr and plr.Character
	if not char or not char.Parent then return nil, nil, nil end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return char, nil, hum
	end
	local root = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
	if not root or not root.Parent then
		return char, nil, hum
	end
	return char, root, hum
end

local function jogadorEstaCaidoKnockdown(hum)
	if not hum or hum.Health <= 0 then return false end
	if hum.PlatformStand then return true end
	local ok, st = pcall(function() return hum:GetState() end)
	if ok and (st == Enum.HumanoidStateType.Ragdoll
		or st == Enum.HumanoidStateType.FallingDown
		or st == Enum.HumanoidStateType.Physics) then
		return true
	end
	return false
end

-- ==========================================
-- NO SLOW (EVITA REDUCAO DE WALKSPEED POR GOLPE/EFEITO)
-- ==========================================
local function aplicarNoSlow()
	if not noSlowAtivo or speedAtivo then return end

	local char, _, hum = getCharAndRoot(LocalPlayer)
	if not char or not hum then return end

	pcall(function()
		if hum.WalkSpeed < WALKSPEED_BASE then
			hum.WalkSpeed = WALKSPEED_BASE
		end
	end)
end

-- ==========================================
-- MULTIPLICADOR DE JUMP (JUMPPOWER)
-- ==========================================
local function aplicarJumpMultiplier()
	local char, _, hum = getCharAndRoot(LocalPlayer)
	if not char or not hum then return end

	pcall(function()
		hum.UseJumpPower = true
		if jumpMultAtivo then
			hum.JumpPower = JUMPPOWER_BASE * jumpMultValor
		elseif hum.JumpPower ~= JUMPPOWER_BASE then
			hum.JumpPower = JUMPPOWER_BASE
		end
	end)
end

-- ==========================================
-- ANTI-RAGDOLL E ANTI GRAB RAG
-- ==========================================
local function aplicarAntiRagdoll()
	if not antiRagdollAtivo then return end

	local char, root, hum = getCharAndRoot(LocalPlayer)
	if not char or not hum then return end

	pcall(function()
		if hum.PlatformStand then
			hum.PlatformStand = false
		end

		local estado = hum:GetState()
		if estado == Enum.HumanoidStateType.Physics
			or estado == Enum.HumanoidStateType.FallingDown
			or estado == Enum.HumanoidStateType.Ragdoll then
			hum:ChangeState(Enum.HumanoidStateType.GettingUp)
		end

		for _, desc in ipairs(char:GetDescendants()) do
			if desc:IsA("Motor6D") and not desc.Enabled then
				desc.Enabled = true
			elseif desc:IsA("BallSocketConstraint") or desc:IsA("HingeConstraint") then
				if desc.Name:lower():find("ragdoll") then
					desc.Enabled = false
				end
			end
		end

		if root then
			root.RotVelocity = Vector3.zero
		end
	end)
end

local function aplicarAntiGrabRag()
	if not antiGrabRagAtivo then return end

	local char, root, hum = getCharAndRoot(LocalPlayer)
	if not char or not hum then return end

	pcall(function()
		if hum.PlatformStand then
			hum.PlatformStand = false
		end

		local estado = hum:GetState()
		if estado == Enum.HumanoidStateType.Physics
			or estado == Enum.HumanoidStateType.FallingDown
			or estado == Enum.HumanoidStateType.Ragdoll then
			hum:ChangeState(Enum.HumanoidStateType.GettingUp)
		end

		for _, desc in ipairs(char:GetDescendants()) do
			if desc:IsA("Motor6D") and not desc.Enabled then
				desc.Enabled = true
			elseif desc:IsA("BallSocketConstraint") or desc:IsA("HingeConstraint") or desc:IsA("WeldConstraint") then
				local lowName = desc.Name:lower()
				if lowName:find("ragdoll") or lowName:find("grab") or lowName:find("catch") or lowName:find("hold") then
					desc.Enabled = false
				end
			elseif desc:IsA("BodyVelocity") or desc:IsA("BodyPosition") or desc:IsA("BodyGyro") or desc:IsA("LinearVelocity") then
				local lowName = desc.Name:lower()
				if lowName:find("grab") or lowName:find("ragdoll") or lowName:find("throw") or lowName:find("launch") then
					desc:Destroy()
				end
			end
		end

		if root then
			root.RotVelocity = Vector3.zero
			if root.AssemblyLinearVelocity.Magnitude > 140 then
				root.AssemblyLinearVelocity = Vector3.zero
			end
		end
	end)
end

-- ==========================================
-- SPEED MULTI-MODO (CFRAME / WALKSPEED / PASSO)
-- ==========================================
local function obterDirecaoMovimento(hum)
	local dir = hum and hum.MoveDirection or Vector3.zero
	local plano = Vector3.new(dir.X, 0, dir.Z)
	if plano.Magnitude > 0.01 then
		return plano.Unit
	end

	local cam = workspace.CurrentCamera
	if not cam then return Vector3.zero end

	local forward = Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z)
	local right = Vector3.new(cam.CFrame.RightVector.X, 0, cam.CFrame.RightVector.Z)
	if forward.Magnitude > 0.001 then forward = forward.Unit end
	if right.Magnitude > 0.001 then right = right.Unit end

	local move = Vector3.zero
	if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up) then
		move += forward
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down) then
		move -= forward
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right) then
		move += right
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left) then
		move -= right
	end

	if move.Magnitude > 0.01 then
		return move.Unit
	end
	return Vector3.zero
end

local function getModoSpeedAtual()
	return MODOS_SPEED[speedModoIndex] or "CFrame"
end

local function aplicarSpeed(dt)
	local char, meuRoot, hum = getCharAndRoot(LocalPlayer)
	if not char or not meuRoot or not hum then return end

	if not speedAtivo then
		if getModoSpeedAtual() == "WalkSpeed" and hum.WalkSpeed > WALKSPEED_BASE and not noSlowAtivo then
			pcall(function() hum.WalkSpeed = WALKSPEED_BASE end)
		end
		return
	end

	if UserInputService:GetFocusedTextBox() then return end
	if hum.Sit then return end

	local modo = getModoSpeedAtual()
	local dir = obterDirecaoMovimento(hum)

	if modo == "WalkSpeed" then
		pcall(function()
			hum.WalkSpeed = speedValor
		end)
	elseif modo == "CFrame" then
		if dir.Magnitude > 0.01 then
			local passo = dir * (speedValor * math.clamp(dt, 0.001, 0.05))
			pcall(function()
				meuRoot.CFrame = meuRoot.CFrame + passo
			end)
		end
	elseif modo == "Passo" then
		if dir.Magnitude > 0.01 then
			local delta = dir * (speedValor * 0.45 * math.clamp(dt, 0.001, 0.05))
			pcall(function()
				meuRoot.AssemblyLinearVelocity = Vector3.new(delta.X * 55, meuRoot.AssemblyLinearVelocity.Y, delta.Z * 55)
			end)
		end
	end
end

local function splitListaNomes(texto)
	local lista = {}
	if not texto or texto:match("^%s*$") then
		return lista
	end
	for token in texto:gmatch("[^%s,;|]+") do
		local limpo = token:match("^%s*(.-)%s*$"):lower()
		if limpo ~= "" then
			table.insert(lista, limpo)
		end
	end
	return lista
end

local function combinaComLista(plr, lista)
	if #lista == 0 then return false end
	local nomeUser = (plr.Name or ""):lower()
	local nomeDisplay = (plr.DisplayName or ""):lower()
	for _, termo in ipairs(lista) do
		if (nomeUser ~= "" and nomeUser:find(termo, 1, true))
			or (nomeDisplay ~= "" and nomeDisplay:find(termo, 1, true)) then
			return true
		end
	end
	return false
end

local function ehAmigoAMG(plr)
	return combinaComLista(plr, splitListaNomes(amgTexto))
end

local function ehAlvoFocus(plr)
	local listaFocus = splitListaNomes(focusTexto)
	if #listaFocus == 0 then
		return true
	end
	return combinaComLista(plr, listaFocus)
end

local function temFiltroFocusAtivo()
	return #splitListaNomes(focusTexto) > 0
end

local function elegivelBackCostas(plr)
	if not plr or plr == LocalPlayer then return false end
	if ehAmigoAMG(plr) then return false end
	local listaBack = splitListaNomes(backFilterTexto)
	if #listaBack > 0 then
		return combinaComLista(plr, listaBack)
	end
	return ehAlvoFocus(plr)
end

-- Exige jogador VIVO (Health > 0) e fora da lista AMG; respeita Focus quando preenchido
local function jogadorElegivelComoAlvo(plr)
	if not plr or plr == LocalPlayer then return false end
	if ehAmigoAMG(plr) then return false end
	if not ehAlvoFocus(plr) then return false end
	local _, root, hum = getCharAndRoot(plr)
	if not root or not hum or hum.Health <= 0 then
		return false
	end
	return true
end

local function normalizarAngulo(ang)
	while ang > math.pi do
		ang -= math.pi * 2
	end
	while ang < -math.pi do
		ang += math.pi * 2
	end
	return ang
end

local function acharMaisProximoGeral(meuRoot, raioMax, filtroExtra)
	local melhorRoot = nil
	local menorDist = raioMax

	for _, plr in ipairs(Players:GetPlayers()) do
		if jogadorElegivelComoAlvo(plr) and (not filtroExtra or filtroExtra(plr)) then
			local _, r, hum = getCharAndRoot(plr)
			if r and hum and hum.Health > 0 then
				local d = (r.Position - meuRoot.Position).Magnitude
				if d <= raioMax and d > 0.1 and d < menorDist then
					menorDist = d
					melhorRoot = r
				end
			end
		end
	end

	return melhorRoot, menorDist
end

-- ==========================================
-- SELECAO PERSISTENTE DO KILL AURA (SEM MORTOS E SEM DESPERDICIO COM MULTIPLOS ALVOS)
-- ==========================================
local function obterAlvoKillAuraPersistente(meuRoot, raioMax)
	if not meuRoot then return nil, nil end

	-- 1) Se ha filtro Focus ativo, prioriza jogador vivo dentro do filtro Focus antes de manter outro
	if alvoKillAuraPlayer and alvoKillAuraPlayer.Parent == Players and jogadorElegivelComoAlvo(alvoKillAuraPlayer) then
		local _, rootTravado, humTravado = getCharAndRoot(alvoKillAuraPlayer)
		if rootTravado and humTravado and humTravado.Health > 0 then
			local distTravado = (rootTravado.Position - meuRoot.Position).Magnitude
			local limitePersistencia = raioMax + MARGEM_PERSISTENCIA_KILL_AURA
			if distTravado <= limitePersistencia and distTravado > 0.1 then
				return rootTravado, alvoKillAuraPlayer
			end
		else
			alvoKillAuraPlayer = nil
		end
	else
		alvoKillAuraPlayer = nil
	end

	-- 2) Seleciona um unico alvo vivo e consistente (evita alternar quando ha 2+ no raio)
	local melhorRoot = nil
	local melhorPlr = nil
	local melhorPontuacao = math.huge

	for _, plr in ipairs(Players:GetPlayers()) do
		if jogadorElegivelComoAlvo(plr) then
			local _, r, hum = getCharAndRoot(plr)
			if r and hum and hum.Health > 0 then
				local d = (r.Position - meuRoot.Position).Magnitude
				if d <= raioMax and d > 0.1 then
					local bonusCaido = jogadorEstaCaidoKnockdown(hum) and -10 or 0
					local pontuacao = d + bonusCaido
					if pontuacao < melhorPontuacao then
						melhorPontuacao = pontuacao
						melhorRoot = r
						melhorPlr = plr
					end
				end
			end
		end
	end

	alvoKillAuraPlayer = melhorPlr
	return melhorRoot, melhorPlr
end

-- ==========================================
-- BACK / COSTAS (COM FILTRO DEDICADO)
-- ==========================================
local function aplicarBackCostas()
	if not backCostasAtivo then return end
	if UserInputService:GetFocusedTextBox() then return end

	local char, meuRoot, hum = getCharAndRoot(LocalPlayer)
	if not char or not meuRoot then return end
	if hum and hum.Sit then return end

	local inimigoRoot = acharMaisProximoGeral(meuRoot, DISTANCIA_MAXIMA_COSTAS, elegivelBackCostas)
	if not inimigoRoot then return end

	local lookInimigoPlano = Vector3.new(inimigoRoot.CFrame.LookVector.X, 0, inimigoRoot.CFrame.LookVector.Z)
	if lookInimigoPlano.Magnitude < 0.001 then
		lookInimigoPlano = Vector3.new(0, 0, -1)
	else
		lookInimigoPlano = lookInimigoPlano.Unit
	end

	local posCostas = inimigoRoot.Position - (lookInimigoPlano * DISTANCIA_COSTAS)
	local posFinal = Vector3.new(posCostas.X, meuRoot.Position.Y, posCostas.Z)
	local destinoCFrame = CFrame.lookAt(posFinal, posFinal + lookInimigoPlano)

	pcall(function()
		meuRoot.AssemblyLinearVelocity = Vector3.zero
		meuRoot.AssemblyAngularVelocity = Vector3.zero
		meuRoot.CFrame = destinoCFrame
	end)
end

local function obterAlcanceAutoClick()
	local raioBase = DISTANCIA_MAXIMA
	if hitboxAtivo then
		local raioHitbox = hitboxSize + 6
		if raioHitbox > raioBase then
			raioBase = raioHitbox
		end
	end
	return raioBase
end

local function haAlvoVivoNoAlcanceAutoClick(meuRoot)
	if not meuRoot then return false end
	local raioEfetivo = obterAlcanceAutoClick()

	for _, plr in ipairs(Players:GetPlayers()) do
		if jogadorElegivelComoAlvo(plr) then
			local _, r, hum = getCharAndRoot(plr)
			if r and hum and hum.Health > 0 then
				local d = (r.Position - meuRoot.Position).Magnitude
				local margemExtraAlvo = hitboxAtivo and (hitboxSize * 0.5) or 0
				if d <= (raioEfetivo + margemExtraAlvo) and d > 0.1 then
					return true
				end
			end
		end
	end

	return false
end

local function executarCliqueRapido()
	if typeof(mouse1click) == "function" then
		pcall(mouse1click)
	else
		pcall(function()
			VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
			VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
		end)
	end
end

local function dispararPulsoAtaque(char)
	if char then
		local tool = char:FindFirstChildOfClass("Tool")
		if tool and tool.Parent == char then
			pcall(function()
				tool:Activate()
			end)
		end
	end
	executarCliqueRapido()
end

local function processarKillAuraFrame(agora)
	if not killAuraAtivo then return false end
	if UserInputService:GetFocusedTextBox() then return false end
	if (agora - ultimoDisparoKillAuraTick) < DELAY_KILL_AURA then
		return alvoKillAuraPlayer ~= nil
	end

	local char, meuRoot = getCharAndRoot(LocalPlayer)
	if not char or not meuRoot then
		alvoKillAuraPlayer = nil
		return false
	end

	local alcanceEfetivo = hitboxAtivo and math.max(DISTANCIA_KILL_AURA, hitboxSize + 6) or DISTANCIA_KILL_AURA
	local alvoProximo = obterAlvoKillAuraPersistente(meuRoot, alcanceEfetivo)
	if not alvoProximo then
		pulsoMiraAte = 0
		yawAntesPulso = nil
		yawAplicadoNoPulso = nil
		return false
	end

	ultimoDisparoKillAuraTick = agora

	if KILL_AURA_PULSO_ALVO then
		local _, yawAtual, _ = meuRoot.CFrame:ToEulerAnglesYXZ()
		if yawAntesPulso == nil then
			yawAntesPulso = yawAtual
		end
		local dx = alvoProximo.Position.X - meuRoot.Position.X
		local dz = alvoProximo.Position.Z - meuRoot.Position.Z
		if (dx * dx + dz * dz) > 0.0025 then
			local yawAlvo = math.atan2(-dx, -dz)
			yawAplicadoNoPulso = yawAlvo
			pcall(function()
				meuRoot.CFrame = CFrame.new(meuRoot.Position) * CFrame.fromEulerAnglesYXZ(0, yawAlvo, 0)
			end)
			pulsoMiraAte = agora + DURACAO_PULSO_MIRA
		end
	end

	for _ = 1, RAJADA_KILL_AURA do
		dispararPulsoAtaque(char)
	end

	return true
end

local function processarAutoClickFrame(agora, killAuraAtacouNesteFrame)
	if killAuraAtacouNesteFrame then return end

	local estaLigado = ativo
	if getgenv and getgenv().UniversalTargetLockActive ~= nil then
		estaLigado = getgenv().UniversalTargetLockActive
	end

	if not estaLigado or not ATIVAR_AUTOCLICK_JUNTO then return end
	if UserInputService:GetFocusedTextBox() then return end
	if (agora - ultimoDisparoAutoClickTick) < DELAY_CLIQUE then return end

	local char, meuRoot = getCharAndRoot(LocalPlayer)
	if meuRoot and haAlvoVivoNoAlcanceAutoClick(meuRoot) then
		ultimoDisparoAutoClickTick = agora
		for _ = 1, RAJADA_AUTOCLICK do
			dispararPulsoAtaque(char)
		end
	end
end

local function restaurarPulsoMiraKillAura()
	if not KILL_AURA_PULSO_ALVO or yawAntesPulso == nil then return end
	if os.clock() < pulsoMiraAte then return end

	local _, meuRoot = getCharAndRoot(LocalPlayer)
	if meuRoot and yawAplicadoNoPulso ~= nil then
		local _, yawAgora, _ = meuRoot.CFrame:ToEulerAnglesYXZ()
		if math.abs(normalizarAngulo(yawAgora - yawAplicadoNoPulso)) < 0.04 then
			pcall(function()
				meuRoot.CFrame = CFrame.new(meuRoot.Position) * CFrame.fromEulerAnglesYXZ(0, yawAntesPulso, 0)
			end)
		end
	end
	yawAntesPulso = nil
	yawAplicadoNoPulso = nil
end

local function restaurarRoot(part)
	local saved = originaisRoot[part]
	if saved and part and part.Parent then
		pcall(function()
			part.Size = saved.Size
			part.Transparency = saved.Transparency
			part.CanCollide = saved.CanCollide
		end)
	end
	originaisRoot[part] = nil
	ultimoEstadoAplicado[part] = nil
end

local function limparMarcador(plr)
	local m = marcadoresJogadores[plr]
	if m and m.tagGui then
		pcall(function() m.tagGui:Destroy() end)
	end
	marcadoresJogadores[plr] = nil
end

local function garantirMarcador(plr, root)
	local m = marcadoresJogadores[plr]
	if m and m.tagGui and m.tagGui.Parent then
		if m.tagGui.Adornee ~= root then
			m.tagGui.Adornee = root
		end
		return m
	end
	limparMarcador(plr)

	local tagGui = Instance.new("BillboardGui")
	tagGui.Name = "AMG_Focus_Indicator"
	tagGui.Adornee = root
	tagGui.Size = UDim2.new(0, 16, 0, 16)
	tagGui.StudsOffset = Vector3.new(0, 3.6, 0)
	tagGui.AlwaysOnTop = true
	tagGui.Enabled = false
	tagGui.Parent = parentGui

	local dot = Instance.new("Frame")
	dot.Size = UDim2.new(0, 10, 0, 10)
	dot.Position = UDim2.new(0.5, 0, 0.5, 0)
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.Rotation = 45
	dot.BackgroundColor3 = Color3.fromRGB(45, 215, 95)
	dot.BorderSizePixel = 0
	dot.Parent = tagGui
	Instance.new("UIStroke", dot).Color = Color3.fromRGB(255, 255, 255)

	m = { tagGui = tagGui, tagDot = dot }
	marcadoresJogadores[plr] = m
	return m
end

local function sincronizarHitboxEMarcadores()
	local rootsAtivos = {}
	local transpAlvo = hitboxVisivel and HITBOX_TRANSPARENCIA_VISIVEL or 1
	local assinaturaAlvo = string.format("%d|%.4f", hitboxSize, transpAlvo)

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer then
			local char, root, hum = getCharAndRoot(plr)
			if char and root and hum and hum.Health > 0 then
				local isAMG = ehAmigoAMG(plr)
				local isFocus = (not isAMG) and temFiltroFocusAtivo() and ehAlvoFocus(plr)

				if isAMG and originaisRoot[root] then
					restaurarRoot(root)
				end

				local m = garantirMarcador(plr, root)
				if m and m.tagGui and m.tagDot then
					if isAMG then
						m.tagGui.Enabled = true
						m.tagDot.BackgroundColor3 = Color3.fromRGB(45, 215, 95)
					elseif isFocus then
						m.tagGui.Enabled = true
						m.tagDot.BackgroundColor3 = Color3.fromRGB(230, 45, 45)
					else
						m.tagGui.Enabled = false
					end
				end

				local deveExpandir = hitboxAtivo and jogadorElegivelComoAlvo(plr)
				if deveExpandir then
					rootsAtivos[root] = true
					if not originaisRoot[root] then
						originaisRoot[root] = {
							Size = root.Size,
							Transparency = root.Transparency,
							CanCollide = root.CanCollide
						}
					end
					if ultimoEstadoAplicado[root] ~= assinaturaAlvo or root.Size.X ~= hitboxSize then
						ultimoEstadoAplicado[root] = assinaturaAlvo
						pcall(function()
							root.CanCollide = false
							root.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
							root.Color = COR_HITBOX_AURA
							root.Transparency = transpAlvo
						end)
					end
				end
			end
		end
	end

	for part in pairs(originaisRoot) do
		if not rootsAtivos[part] then
			restaurarRoot(part)
		end
	end

	for plr in pairs(marcadoresJogadores) do
		if plr.Parent ~= Players then
			limparMarcador(plr)
		end
	end
end

local painelFrameUI

local function aplicarBordaRoxa(instancia, espessura)
	local stroke = Instance.new("UIStroke")
	stroke.Color = ROXO_NEXUS
	stroke.Thickness = espessura or 1.2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = instancia
	return stroke
end

local function criarBotaoPadrao(pai, texto, pos, tamanho, tamanhoTexto)
	local btn = Instance.new("TextButton")
	btn.Size = tamanho
	btn.Position = pos
	btn.BackgroundColor3 = BOTAO_CINZA
	btn.Text = texto
	btn.TextColor3 = Color3.fromRGB(240, 240, 248)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = tamanhoTexto or 11
	btn.BorderSizePixel = 0
	btn.Parent = pai
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
	aplicarBordaRoxa(btn, 1)
	return btn
end

local function criarCampoTextoPadrao(pai, placeholder, pos, altura)
	local box = Instance.new("TextBox")
	box.Size = UDim2.new(1, -16, 0, altura or 23)
	box.Position = pos
	box.BackgroundColor3 = BOTAO_CINZA
	box.Text = ""
	box.PlaceholderText = placeholder
	box.PlaceholderColor3 = Color3.fromRGB(150, 150, 162)
	box.TextColor3 = Color3.fromRGB(240, 240, 245)
	box.Font = Enum.Font.Gotham
	box.TextSize = 11
	box.ClearTextOnFocus = false
	box.BorderSizePixel = 0
	box.Parent = pai
	Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
	aplicarBordaRoxa(box, 1)
	return box
end

local function criarSliderPadrao(pai, rotuloInicial, posY, minVal, maxVal, valorInicial, onChange)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -16, 0, 14)
	lbl.Position = UDim2.new(0, 8, 0, posY)
	lbl.BackgroundTransparency = 1
	lbl.Text = rotuloInicial .. tostring(valorInicial)
	lbl.TextColor3 = Color3.fromRGB(225, 225, 235)
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextSize = 11
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = pai

	local track = Instance.new("TextButton")
	track.Size = UDim2.new(1, -16, 0, 13)
	track.Position = UDim2.new(0, 8, 0, posY + 16)
	track.BackgroundColor3 = BOTAO_CINZA
	track.Text = ""
	track.AutoButtonColor = false
	track.BorderSizePixel = 0
	track.Parent = pai
	Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
	aplicarBordaRoxa(track, 1)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.BackgroundColor3 = ROXO_NEXUS
	fill.BorderSizePixel = 0
	fill.Parent = track
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

	local knob = Instance.new("Frame")
	knob.Size = UDim2.new(0, 13, 0, 13)
	knob.Position = UDim2.new(0, 0, 0.5, 0)
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.BackgroundColor3 = Color3.fromRGB(245, 245, 250)
	knob.BorderSizePixel = 0
	knob.Parent = track
	Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
	aplicarBordaRoxa(knob, 1)

	local function setValor(novoVal, disparar)
		local clamped = math.clamp(math.floor(novoVal + 0.5), minVal, maxVal)
		local pct = math.clamp((clamped - minVal) / math.max(maxVal - minVal, 1), 0, 1)
		fill.Size = UDim2.new(pct, 0, 1, 0)
		knob.Position = UDim2.new(pct, 0, 0.5, 0)
		lbl.Text = rotuloInicial .. tostring(clamped)
		if disparar and onChange then
			onChange(clamped)
		end
	end

	setValor(valorInicial, false)

	return {
		track = track,
		setValorPorPosicaoX = function(posX)
			local largura = math.max(track.AbsoluteSize.X, 1)
			local rel = math.clamp((posX - track.AbsolutePosition.X) / largura, 0, 1)
			setValor(minVal + rel * (maxVal - minVal), true)
		end
	}
end

local function criarPainelHitbox()
	if not parentGui then return end
	local antigo = parentGui:FindFirstChild("UniversalCombatPanel")
	if antigo then antigo:Destroy() end

	local gui = Instance.new("ScreenGui")
	gui.Name = "UniversalCombatPanel"
	gui.ResetOnSpawn = false
	gui.Parent = parentGui

	local frame = Instance.new("Frame")
	frame.Name = "MainPanel"
	frame.Size = UDim2.new(0, 200, 0, 476)
	frame.Position = POSICAO_PAINEL_PADRAO
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	frame.BorderSizePixel = 0
	frame.Active = true
	frame.Parent = gui

	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
	aplicarBordaRoxa(frame, 1.5)

	local titulo = Instance.new("TextLabel")
	titulo.Name = "PanelTitle"
	titulo.Size = UDim2.new(1, -16, 0, 18)
	titulo.Position = UDim2.new(0, 8, 0, 6)
	titulo.BackgroundTransparency = 1
	titulo.Text = "The VOID Painel"
	titulo.TextColor3 = ROXO_NEXUS
	titulo.Font = Enum.Font.GothamBold
	titulo.TextSize = 13
	titulo.TextXAlignment = Enum.TextXAlignment.Center
	titulo.Parent = frame

	local abasNomes = { "Combat", "Move", "Visual", "Config" }
	local abasBotoes = {}
	local abasPaginas = {}

	local barraAbas = Instance.new("Frame")
	barraAbas.Name = "TopTabsBar"
	barraAbas.Size = UDim2.new(1, -16, 0, 22)
	barraAbas.Position = UDim2.new(0, 8, 0, 27)
	barraAbas.BackgroundTransparency = 1
	barraAbas.Parent = frame

	local larguraDisponivel = 184
	local espacoEntreAbas = 3
	local larguraAba = math.floor((larguraDisponivel - espacoEntreAbas * (#abasNomes - 1)) / #abasNomes)

	for idx, nomeAba in ipairs(abasNomes) do
		local xPos = (idx - 1) * (larguraAba + espacoEntreAbas)
		local tabBtn = Instance.new("TextButton")
		tabBtn.Name = "Tab_" .. nomeAba
		tabBtn.Size = UDim2.new(0, larguraAba, 1, 0)
		tabBtn.Position = UDim2.new(0, xPos, 0, 0)
		tabBtn.BackgroundColor3 = BOTAO_CINZA
		tabBtn.Text = nomeAba
		tabBtn.TextColor3 = Color3.fromRGB(235, 235, 245)
		tabBtn.Font = Enum.Font.GothamBold
		tabBtn.TextSize = 9
		tabBtn.BorderSizePixel = 0
		tabBtn.Parent = barraAbas
		Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 4)
		aplicarBordaRoxa(tabBtn, 1)

		local pagina = Instance.new("Frame")
		pagina.Name = "Page_" .. nomeAba
		pagina.Size = UDim2.new(1, 0, 1, -74)
		pagina.Position = UDim2.new(0, 0, 0, 53)
		pagina.BackgroundTransparency = 1
		pagina.Visible = (idx == 1)
		pagina.Parent = frame

		abasBotoes[nomeAba] = tabBtn
		abasPaginas[nomeAba] = pagina
	end

	local function selecionarAba(nomeEscolhido)
		for nomeAba, pagina in pairs(abasPaginas) do
			local estaSelecionada = (nomeAba == nomeEscolhido)
			pagina.Visible = estaSelecionada
			local btn = abasBotoes[nomeAba]
			if btn then
				btn.BackgroundColor3 = estaSelecionada and BOTAO_ROXO_ON or BOTAO_CINZA
				btn.TextColor3 = estaSelecionada and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(205, 205, 220)
			end
		end
	end

	for nomeAba, tabBtn in pairs(abasBotoes) do
		tabBtn.MouseButton1Click:Connect(function()
			selecionarAba(nomeAba)
		end)
	end

	local pagCombat = abasPaginas.Combat
	local btnAuto = criarBotaoPadrao(pagCombat, "AutoClick VOID (E): OFF", UDim2.new(0, 8, 0, 0), UDim2.new(1, -16, 0, 19), 11)
	local btnLock = criarBotaoPadrao(
		pagCombat,
		targetLockHabilitadoNoPainel and "Target Lock: ON" or "Target Lock: OFF",
		UDim2.new(0, 8, 0, 21),
		UDim2.new(1, -16, 0, 19),
		11
	)
	btnLock.BackgroundColor3 = targetLockHabilitadoNoPainel and BOTAO_ROXO_ON or BOTAO_CINZA

	local btnBackCostas = criarBotaoPadrao(
		pagCombat,
		backCostasAtivo and "Back / Costas: ON" or "Back / Costas: OFF",
		UDim2.new(0, 8, 0, 42),
		UDim2.new(1, -16, 0, 19),
		11
	)
	btnBackCostas.BackgroundColor3 = backCostasAtivo and BOTAO_ROXO_ON or BOTAO_CINZA

	local btnAntiRagdoll = criarBotaoPadrao(
		pagCombat,
		antiRagdollAtivo and "Anti-Ragdoll: ON" or "Anti-Ragdoll: OFF",
		UDim2.new(0, 8, 0, 63),
		UDim2.new(1, -16, 0, 19),
		11
	)
	btnAntiRagdoll.BackgroundColor3 = antiRagdollAtivo and BOTAO_ROXO_ON or BOTAO_CINZA

	local btnAntiGrabRag = criarBotaoPadrao(
		pagCombat,
		antiGrabRagAtivo and "Anti Grab Rag: ON" or "Anti Grab Rag: OFF",
		UDim2.new(0, 8, 0, 84),
		UDim2.new(1, -16, 0, 19),
		11
	)
	btnAntiGrabRag.BackgroundColor3 = antiGrabRagAtivo and BOTAO_ROXO_ON or BOTAO_CINZA

	local btnDeathTp = criarBotaoPadrao(
		pagCombat,
		deathTpAtivo and "Death TP: ON" or "Death TP: OFF",
		UDim2.new(0, 8, 0, 105),
		UDim2.new(1, -16, 0, 19),
		11
	)
	btnDeathTp.BackgroundColor3 = deathTpAtivo and BOTAO_ROXO_ON or BOTAO_CINZA

	local btnNoSlow = criarBotaoPadrao(
		pagCombat,
		noSlowAtivo and "No Slow: ON" or "No Slow: OFF",
		UDim2.new(0, 8, 0, 126),
		UDim2.new(1, -16, 0, 19),
		11
	)
	btnNoSlow.BackgroundColor3 = noSlowAtivo and BOTAO_ROXO_ON or BOTAO_CINZA

	local btnKillAura = criarBotaoPadrao(
		pagCombat,
		killAuraAtivo and "Kill Aura (Q): ON" or "Kill Aura (Q): OFF",
		UDim2.new(0, 8, 0, 147),
		UDim2.new(1, -16, 0, 19),
		11
	)
	btnKillAura.BackgroundColor3 = killAuraAtivo and BOTAO_ROXO_ON or BOTAO_CINZA

	local btnHit = criarBotaoPadrao(
		pagCombat,
		hitboxAtivo and "Hitbox: ON" or "Hitbox: OFF",
		UDim2.new(0, 8, 0, 168),
		UDim2.new(0.5, -10, 0, 19),
		10
	)
	btnHit.BackgroundColor3 = hitboxAtivo and BOTAO_ROXO_ON or BOTAO_CINZA

	local btnVis = criarBotaoPadrao(
		pagCombat,
		hitboxVisivel and "Visivel: Sim" or "Visivel: Nao",
		UDim2.new(0.5, 2, 0, 168),
		UDim2.new(0.5, -10, 0, 19),
		10
	)
	btnVis.BackgroundColor3 = hitboxVisivel and BOTAO_ROXO_ON or BOTAO_CINZA

	local sliderSize = criarSliderPadrao(pagCombat, "Size: ", 190, 3, HITBOX_MAX_SLIDER, hitboxSize, function(novoSize)
		hitboxSize = novoSize
		sincronizarHitboxEMarcadores()
	end)

	local boxAMG = criarCampoTextoPadrao(pagCombat, "AMG (ignorar)...", UDim2.new(0, 8, 0, 223), 18)
	local boxFocus = criarCampoTextoPadrao(pagCombat, "Focus (alvo PvP)...", UDim2.new(0, 8, 0, 243), 18)
	local boxBackFilter = criarCampoTextoPadrao(pagCombat, "Back Filtro (costas)...", UDim2.new(0, 8, 0, 263), 18)

	boxAMG:GetPropertyChangedSignal("Text"):Connect(function()
		amgTexto = boxAMG.Text
		alvoKillAuraPlayer = nil
		sincronizarHitboxEMarcadores()
	end)

	boxFocus:GetPropertyChangedSignal("Text"):Connect(function()
		focusTexto = boxFocus.Text
		alvoKillAuraPlayer = nil
		sincronizarHitboxEMarcadores()
	end)

	boxBackFilter:GetPropertyChangedSignal("Text"):Connect(function()
		backFilterTexto = boxBackFilter.Text
	end)

	local pagMove = abasPaginas.Move
	local btnSpeed = criarBotaoPadrao(
		pagMove,
		speedAtivo and "Speed: ON" or "Speed: OFF",
		UDim2.new(0, 8, 0, 4),
		UDim2.new(0.5, -10, 0, 24),
		10
	)
	btnSpeed.BackgroundColor3 = speedAtivo and BOTAO_ROXO_ON or BOTAO_CINZA

	local btnModoSpeed = criarBotaoPadrao(
		pagMove,
		"Modo: " .. getModoSpeedAtual(),
		UDim2.new(0.5, 2, 0, 4),
		UDim2.new(0.5, -10, 0, 24),
		10
	)
	btnModoSpeed.BackgroundColor3 = BOTAO_ROXO_ON

	local sliderSpeed = criarSliderPadrao(pagMove, "Speed Valor: ", 36, SPEED_MIN, SPEED_MAX, speedValor, function(novoSpeed)
		speedValor = novoSpeed
	end)

	local btnJumpMult = criarBotaoPadrao(
		pagMove,
		jumpMultAtivo and "Jump Mult: ON" or "Jump Mult: OFF",
		UDim2.new(0, 8, 0, 74),
		UDim2.new(1, -16, 0, 24),
		11
	)
	btnJumpMult.BackgroundColor3 = jumpMultAtivo and BOTAO_ROXO_ON or BOTAO_CINZA

	local sliderJumpMult = criarSliderPadrao(pagMove, "Jump x: ", 106, JUMP_MULT_MIN, JUMP_MULT_MAX, jumpMultValor, function(novoJump)
		jumpMultValor = novoJump
		aplicarJumpMultiplier()
	end)

	local dicaMove = Instance.new("TextLabel")
	dicaMove.Size = UDim2.new(1, -16, 0, 42)
	dicaMove.Position = UDim2.new(0, 8, 0, 144)
	dicaMove.BackgroundTransparency = 1
	dicaMove.Text = "Modos Speed: CFrame, WalkSpeed ou Passo. Jump x ajusta JumpPower."
	dicaMove.TextColor3 = Color3.fromRGB(165, 165, 180)
	dicaMove.TextWrapped = true
	dicaMove.Font = Enum.Font.Gotham
	dicaMove.TextSize = 10
	dicaMove.TextXAlignment = Enum.TextXAlignment.Left
	dicaMove.Parent = pagMove

	local pagVisual = abasPaginas.Visual
	local btnNoAnim = criarBotaoPadrao(
		pagVisual,
		noAnimationAtivo and "No Animation: ON" or "No Animation: OFF",
		UDim2.new(0, 8, 0, 4),
		UDim2.new(1, -16, 0, 25),
		11
	)
	btnNoAnim.BackgroundColor3 = noAnimationAtivo and BOTAO_ROXO_ON or BOTAO_CINZA

	local btnHudLosango = criarBotaoPadrao(
		pagVisual,
		hudLosangoVisivel and "HUD Losango: ON" or "HUD Losango: OFF",
		UDim2.new(0, 8, 0, 35),
		UDim2.new(1, -16, 0, 25),
		11
	)
	btnHudLosango.BackgroundColor3 = hudLosangoVisivel and BOTAO_ROXO_ON or BOTAO_CINZA

	local btnHudStats = criarBotaoPadrao(
		pagVisual,
		hudStatsVisivel and "FPS / MS: ON" or "FPS / MS: OFF",
		UDim2.new(0, 8, 0, 66),
		UDim2.new(1, -16, 0, 25),
		11
	)
	btnHudStats.BackgroundColor3 = hudStatsVisivel and BOTAO_ROXO_ON or BOTAO_CINZA

	local dicaVisual = Instance.new("TextLabel")
	dicaVisual.Size = UDim2.new(1, -16, 0, 48)
	dicaVisual.Position = UDim2.new(0, 8, 0, 99)
	dicaVisual.BackgroundTransparency = 1
	dicaVisual.Text = "No Animation corta soco/G e silencia sons de ataque no cliente."
	dicaVisual.TextColor3 = Color3.fromRGB(165, 165, 180)
	dicaVisual.TextWrapped = true
	dicaVisual.Font = Enum.Font.Gotham
	dicaVisual.TextSize = 10
	dicaVisual.TextXAlignment = Enum.TextXAlignment.Left
	dicaVisual.Parent = pagVisual

	local pagConfig = abasPaginas.Config
	local btnOtimizar = criarBotaoPadrao(
		pagConfig,
		boostFpsRedeAtivo and "Otimizar FPS / Rede: ON" or "Otimizar FPS / Rede: OFF",
		UDim2.new(0, 8, 0, 4),
		UDim2.new(1, -16, 0, 25),
		10
	)
	btnOtimizar.BackgroundColor3 = boostFpsRedeAtivo and BOTAO_ROXO_ON or BOTAO_CINZA

	local btnResetPos = criarBotaoPadrao(
		pagConfig,
		"Resetar Posicao",
		UDim2.new(0, 8, 0, 34),
		UDim2.new(1, -16, 0, 25),
		11
	)

	local infoAtalhos = Instance.new("TextLabel")
	infoAtalhos.Size = UDim2.new(1, -16, 0, 88)
	infoAtalhos.Position = UDim2.new(0, 8, 0, 66)
	infoAtalhos.BackgroundTransparency = 1
	infoAtalhos.Text = "AutoClick: E\nKill Aura: Q\nPainel: J\nMortos (Health <= 0) sao ignorados.\nFocus prioriza alvo do PvP."
	infoAtalhos.TextColor3 = Color3.fromRGB(190, 190, 205)
	infoAtalhos.TextWrapped = true
	infoAtalhos.Font = Enum.Font.GothamMedium
	infoAtalhos.TextSize = 10
	infoAtalhos.TextXAlignment = Enum.TextXAlignment.Left
	infoAtalhos.TextYAlignment = Enum.TextYAlignment.Top
	infoAtalhos.Parent = pagConfig

	local rodape = Instance.new("TextLabel")
	rodape.Name = "FooterCredits"
	rodape.Size = UDim2.new(1, -16, 0, 14)
	rodape.Position = UDim2.new(0, 8, 1, -18)
	rodape.BackgroundTransparency = 1
	rodape.Text = "By: VOID Santos7x"
	rodape.TextColor3 = Color3.fromRGB(255, 255, 255)
	rodape.Font = Enum.Font.GothamMedium
	rodape.TextSize = 9
	rodape.Parent = frame

	local arrastandoSlider = nil
	local arrastandoPainel = false
	local offsetPainel = Vector2.zero

	sliderSize.track.MouseButton1Down:Connect(function()
		arrastandoSlider = sliderSize
		arrastandoPainel = false
		sliderSize.setValorPorPosicaoX(UserInputService:GetMouseLocation().X)
	end)

	sliderSpeed.track.MouseButton1Down:Connect(function()
		arrastandoSlider = sliderSpeed
		arrastandoPainel = false
		sliderSpeed.setValorPorPosicaoX(UserInputService:GetMouseLocation().X)
	end)

	sliderJumpMult.track.MouseButton1Down:Connect(function()
		arrastandoSlider = sliderJumpMult
		arrastandoPainel = false
		sliderJumpMult.setValorPorPosicaoX(UserInputService:GetMouseLocation().X)
	end)

	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and not arrastandoSlider then
			arrastandoPainel = true
			offsetPainel = Vector2.new(
				input.Position.X - frame.AbsolutePosition.X,
				input.Position.Y - frame.AbsolutePosition.Y
			)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			if arrastandoSlider then
				arrastandoSlider.setValorPorPosicaoX(input.Position.X)
			elseif arrastandoPainel then
				frame.Position = UDim2.new(
					0,
					input.Position.X - offsetPainel.X,
					0,
					input.Position.Y - offsetPainel.Y
				)
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			arrastandoSlider = nil
			arrastandoPainel = false
		end
	end)

	btnAuto.MouseButton1Click:Connect(function()
		setEstado(not ativo)
	end)

	btnLock.MouseButton1Click:Connect(function()
		targetLockHabilitadoNoPainel = not targetLockHabilitadoNoPainel
		btnLock.Text = targetLockHabilitadoNoPainel and "Target Lock: ON" or "Target Lock: OFF"
		btnLock.BackgroundColor3 = targetLockHabilitadoNoPainel and BOTAO_ROXO_ON or BOTAO_CINZA
		if not targetLockHabilitadoNoPainel then
			alvoAtual = nil
		end
	end)

	btnBackCostas.MouseButton1Click:Connect(function()
		backCostasAtivo = not backCostasAtivo
		btnBackCostas.Text = backCostasAtivo and "Back / Costas: ON" or "Back / Costas: OFF"
		btnBackCostas.BackgroundColor3 = backCostasAtivo and BOTAO_ROXO_ON or BOTAO_CINZA
	end)

	btnAntiRagdoll.MouseButton1Click:Connect(function()
		antiRagdollAtivo = not antiRagdollAtivo
		btnAntiRagdoll.Text = antiRagdollAtivo and "Anti-Ragdoll: ON" or "Anti-Ragdoll: OFF"
		btnAntiRagdoll.BackgroundColor3 = antiRagdollAtivo and BOTAO_ROXO_ON or BOTAO_CINZA
	end)

	btnAntiGrabRag.MouseButton1Click:Connect(function()
		antiGrabRagAtivo = not antiGrabRagAtivo
		btnAntiGrabRag.Text = antiGrabRagAtivo and "Anti Grab Rag: ON" or "Anti Grab Rag: OFF"
		btnAntiGrabRag.BackgroundColor3 = antiGrabRagAtivo and BOTAO_ROXO_ON or BOTAO_CINZA
	end)

	btnDeathTp.MouseButton1Click:Connect(function()
		deathTpAtivo = not deathTpAtivo
		btnDeathTp.Text = deathTpAtivo and "Death TP: ON" or "Death TP: OFF"
		btnDeathTp.BackgroundColor3 = deathTpAtivo and BOTAO_ROXO_ON or BOTAO_CINZA
	end)

	btnNoSlow.MouseButton1Click:Connect(function()
		noSlowAtivo = not noSlowAtivo
		btnNoSlow.Text = noSlowAtivo and "No Slow: ON" or "No Slow: OFF"
		btnNoSlow.BackgroundColor3 = noSlowAtivo and BOTAO_ROXO_ON or BOTAO_CINZA
	end)

	btnKillAura.MouseButton1Click:Connect(function()
		setKillAuraEstado(not killAuraAtivo)
	end)

	btnHit.MouseButton1Click:Connect(function()
		hitboxAtivo = not hitboxAtivo
		btnHit.Text = hitboxAtivo and "Hitbox: ON" or "Hitbox: OFF"
		btnHit.BackgroundColor3 = hitboxAtivo and BOTAO_ROXO_ON or BOTAO_CINZA
		sincronizarHitboxEMarcadores()
	end)

	btnVis.MouseButton1Click:Connect(function()
		hitboxVisivel = not hitboxVisivel
		btnVis.Text = hitboxVisivel and "Visivel: Sim" or "Visivel: Nao"
		btnVis.BackgroundColor3 = hitboxVisivel and BOTAO_ROXO_ON or BOTAO_CINZA
		sincronizarHitboxEMarcadores()
	end)

	btnSpeed.MouseButton1Click:Connect(function()
		speedAtivo = not speedAtivo
		btnSpeed.Text = speedAtivo and "Speed: ON" or "Speed: OFF"
		btnSpeed.BackgroundColor3 = speedAtivo and BOTAO_ROXO_ON or BOTAO_CINZA
		if not speedAtivo and getModoSpeedAtual() == "WalkSpeed" then
			local _, _, hum = getCharAndRoot(LocalPlayer)
			if hum then
				pcall(function() hum.WalkSpeed = WALKSPEED_BASE end)
			end
		end
	end)

	btnModoSpeed.MouseButton1Click:Connect(function()
		local modoAnterior = getModoSpeedAtual()
		speedModoIndex = (speedModoIndex % #MODOS_SPEED) + 1
		btnModoSpeed.Text = "Modo: " .. getModoSpeedAtual()
		if modoAnterior == "WalkSpeed" and getModoSpeedAtual() ~= "WalkSpeed" then
			local _, _, hum = getCharAndRoot(LocalPlayer)
			if hum then
				pcall(function() hum.WalkSpeed = WALKSPEED_BASE end)
			end
		end
	end)

	btnJumpMult.MouseButton1Click:Connect(function()
		jumpMultAtivo = not jumpMultAtivo
		btnJumpMult.Text = jumpMultAtivo and "Jump Mult: ON" or "Jump Mult: OFF"
		btnJumpMult.BackgroundColor3 = jumpMultAtivo and BOTAO_ROXO_ON or BOTAO_CINZA
		aplicarJumpMultiplier()
	end)

	btnNoAnim.MouseButton1Click:Connect(function()
		noAnimationAtivo = not noAnimationAtivo
		btnNoAnim.Text = noAnimationAtivo and "No Animation: ON" or "No Animation: OFF"
		btnNoAnim.BackgroundColor3 = noAnimationAtivo and BOTAO_ROXO_ON or BOTAO_CINZA
		sincronizarNoAnimation()
	end)

	btnHudLosango.MouseButton1Click:Connect(function()
		hudLosangoVisivel = not hudLosangoVisivel
		btnHudLosango.Text = hudLosangoVisivel and "HUD Losango: ON" or "HUD Losango: OFF"
		btnHudLosango.BackgroundColor3 = hudLosangoVisivel and BOTAO_ROXO_ON or BOTAO_CINZA
		if losangoGuiRoot then
			losangoGuiRoot.Enabled = hudLosangoVisivel
		end
	end)

	btnHudStats.MouseButton1Click:Connect(function()
		hudStatsVisivel = not hudStatsVisivel
		btnHudStats.Text = hudStatsVisivel and "FPS / MS: ON" or "FPS / MS: OFF"
		btnHudStats.BackgroundColor3 = hudStatsVisivel and BOTAO_ROXO_ON or BOTAO_CINZA
		if statsLabelUI then
			statsLabelUI.Visible = hudStatsVisivel
		end
	end)

	btnOtimizar.MouseButton1Click:Connect(function()
		aplicarOtimizacaoFpsERede(not boostFpsRedeAtivo)
		btnOtimizar.Text = boostFpsRedeAtivo and "Otimizar FPS / Rede: ON" or "Otimizar FPS / Rede: OFF"
		btnOtimizar.BackgroundColor3 = boostFpsRedeAtivo and BOTAO_ROXO_ON or BOTAO_CINZA
	end)

	btnResetPos.MouseButton1Click:Connect(function()
		frame.Position = POSICAO_PAINEL_PADRAO
	end)

	selecionarAba("Combat")
	painelFrameUI = frame
	btnAutoClickUI = btnAuto
	btnKillAuraUI = btnKillAura
	atualizarKillAuraUI(killAuraAtivo)
end

criarPainelHitbox()
atualizarVisual(ativo)
sincronizarNoAnimation()

local function distanciaPara(meuRoot, alvoRoot)
	if not meuRoot or not alvoRoot or not alvoRoot.Parent then
		return math.huge
	end
	return (alvoRoot.Position - meuRoot.Position).Magnitude
end

local function acharMaisProximo(meuRoot)
	return acharMaisProximoGeral(meuRoot, DISTANCIA_MAXIMA)
end

local function aplicarFocoNoAlvo()
	if getgenv and getgenv().UniversalTargetLockActive ~= nil then
		ativo = getgenv().UniversalTargetLockActive
	end
	atualizarVisual(ativo)

	if not ativo or not targetLockHabilitadoNoPainel then
		alvoAtual = nil
		return
	end

	local _, meuRoot = getCharAndRoot(LocalPlayer)
	if not meuRoot then return end

	local maisProximo, distMaisProximo = acharMaisProximo(meuRoot)
	local distAtual = distanciaPara(meuRoot, alvoAtual)

	if not maisProximo then
		alvoAtual = nil
		return
	elseif not alvoAtual or distAtual > DISTANCIA_MAXIMA then
		alvoAtual = maisProximo
	elseif maisProximo ~= alvoAtual and (distAtual - distMaisProximo) > MARGEM_TROCA then
		alvoAtual = maisProximo
	end

	if not alvoAtual or not alvoAtual.Parent then return end

	local meuPos = meuRoot.Position
	local alvoPos = alvoAtual.Position
	local dx = alvoPos.X - meuPos.X
	local dz = alvoPos.Z - meuPos.Z

	if not ORBITAR and (dx * dx + dz * dz) > 0.0025 then
		local _, yawAtual, _ = meuRoot.CFrame:ToEulerAnglesYXZ()
		local yawDesejado = math.atan2(-dx, -dz)
		local diff = normalizarAngulo(yawDesejado - yawAtual)
		local fator = math.clamp(FIRMEZA_GIRO, 0.05, 1)
		local novoYaw = yawAtual + (diff * fator)

		meuRoot.CFrame = CFrame.new(meuPos) * CFrame.fromEulerAnglesYXZ(0, novoYaw, 0)
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == TECLA_ESPECIAL then
		ultimoEspecialTick = os.clock()
	elseif input.KeyCode == TECLA_KILL_AURA then
		setKillAuraEstado(not killAuraAtivo)
	elseif input.KeyCode == TECLA_ATALHO then
		setEstado(not ativo)
	elseif input.KeyCode == TECLA_PAINEL and painelFrameUI then
		painelFrameUI.Visible = not painelFrameUI.Visible
	end
end)

pcall(function()
	RunService:UnbindFromRenderStep("UniversalCharTargetLock")
end)

local acumuladorFps = 0
local framesContados = 0
local ultimoFpsExibido = nil
local ultimoPingExibido = nil

RunService.RenderStepped:Connect(function(dt)
	aplicarFocoNoAlvo()
	restaurarPulsoMiraKillAura()

	if hudLosangoVisivel and hudStatsVisivel and statsLabelUI then
		acumuladorFps += dt
		framesContados += 1
		if acumuladorFps >= 0.35 then
			local fpsAtual = math.floor((framesContados / acumuladorFps) + 0.5)
			local pingAtual = lerPingMs()
			if fpsAtual ~= ultimoFpsExibido or pingAtual ~= ultimoPingExibido then
				ultimoFpsExibido = fpsAtual
				ultimoPingExibido = pingAtual
				local textoPing = pingAtual and (tostring(pingAtual) .. " MS") or "-- MS"
				statsLabelUI.Text = "FPS: " .. tostring(fpsAtual) .. " | " .. textoPing
			end
			acumuladorFps = 0
			framesContados = 0
		end
	end
end)

RunService.Heartbeat:Connect(function(dt)
	local agora = os.clock()
	aplicarBackCostas()
	aplicarNoSlow()
	aplicarJumpMultiplier()
	aplicarAntiRagdoll()
	aplicarAntiGrabRag()
	aplicarSpeed(dt)

	local killAuraAtacou = processarKillAuraFrame(agora)
	processarAutoClickFrame(agora, killAuraAtacou)
end)

task.spawn(function()
	while true do
		pcall(sincronizarHitboxEMarcadores)
		task.wait(0.35)
	end
end)

Players.PlayerRemoving:Connect(function(plr)
	if alvoKillAuraPlayer == plr then
		alvoKillAuraPlayer = nil
	end
	limparMarcador(plr)
end)

print("[The VOID Painel] Atualizacao completa (1-11) aplicada com foco em desempenho no PvP!")
