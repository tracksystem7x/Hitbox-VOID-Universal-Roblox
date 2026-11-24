if getgenv and getgenv().UniversalTargetLockLoaded then
	getgenv().UniversalTargetLockActive = not getgenv().UniversalTargetLockActive
	if getgenv().SetTargetLockUI then
		getgenv().SetTargetLockUI(getgenv().UniversalTargetLockActive)
	end
	warn("[Hitbox VOID] Alternado para:", getgenv().UniversalTargetLockActive and "ON" or "OFF")
	return
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- ==========================================
-- CONFIGURACAO GERAL
-- ==========================================
local TECLA_ATALHO = Enum.KeyCode.E
local TECLA_PAINEL = Enum.KeyCode.J
local TECLA_ESPECIAL = Enum.KeyCode.G
local JANELA_ESPECIAL_SEG = 1.2

local DISTANCIA_MAXIMA = 22
local MARGEM_TROCA = 3.5
local FIRMEZA_GIRO = 1.0
local ORBITAR = false

local ATIVAR_AUTOCLICK_JUNTO = true
local DELAY_CLIQUE = 0.001

local TARGET_LOCK_PADRAO_HABILITADO = true
local NO_ANIMATION_PADRAO_ATIVO = false
local SPEED_CFRAME_PADRAO_ATIVO = false
local SPEED_CFRAME_PADRAO = 24 -- Studs por segundo via CFrame
local SPEED_CFRAME_MIN = 8
local SPEED_CFRAME_MAX = 80

local HITBOX_PADRAO_ATIVO = false
local HITBOX_TAMANHO_PADRAO = 12
local HITBOX_MAX_SLIDER = 27
local HITBOX_VISIVEL_PADRAO = true
local HITBOX_TRANSPARENCIA_VISIVEL = 0.965
local COR_HITBOX_AURA = Color3.fromRGB(220, 55, 55)

-- Tema Roxo Nexus
local ROXO_NEXUS = Color3.fromRGB(155, 65, 255)
local BOTAO_CINZA = Color3.fromRGB(42, 42, 50)
local BOTAO_ROXO_ON = Color3.fromRGB(145, 50, 250)
-- ==========================================

if getgenv then
	getgenv().UniversalTargetLockLoaded = true
	getgenv().UniversalTargetLockActive = false
end

local ativo = false
local targetLockHabilitadoNoPainel = TARGET_LOCK_PADRAO_HABILITADO
local noAnimationAtivo = NO_ANIMATION_PADRAO_ATIVO
local speedCFrameAtivo = SPEED_CFRAME_PADRAO_ATIVO
local speedCFrameValor = SPEED_CFRAME_PADRAO
local alvoAtual = nil

local hitboxAtivo = HITBOX_PADRAO_ATIVO
local hitboxVisivel = HITBOX_VISIVEL_PADRAO
local hitboxSize = HITBOX_TAMANHO_PADRAO
local amgTexto = ""
local focusTexto = ""

local originaisRoot = {}
local ultimoEstadoAplicado = {}
local marcadoresJogadores = {}
local animConexoes = {}
local ultimoEspecialTick = 0

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

local losangoUI, statusUI

local function criarIndicadorUI()
	if not parentGui then return end
	local antiga = parentGui:FindFirstChild("UniversalLockDiamondHUD")
	if antiga then antiga:Destroy() end

	local gui = Instance.new("ScreenGui")
	gui.Name = "UniversalLockDiamondHUD"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = parentGui

	local holder = Instance.new("Frame")
	holder.Name = "DiamondHolder"
	holder.Size = UDim2.new(0, 34, 0, 34)
	holder.Position = UDim2.new(0, 14, 0, 66)
	holder.BackgroundTransparency = 1
	holder.Parent = gui

	local losango = Instance.new("Frame")
	losango.Name = "DiamondShape"
	losango.Size = UDim2.new(0, 22, 0, 22)
	losango.Position = UDim2.new(0.5, 0, 0.5, 0)
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
	textoEstado.Position = UDim2.new(1, 8, 0.5, 0)
	textoEstado.AnchorPoint = Vector2.new(0, 0.5)
	textoEstado.BackgroundTransparency = 1
	textoEstado.Text = "OFF"
	textoEstado.TextColor3 = Color3.fromRGB(235, 65, 65)
	textoEstado.TextStrokeTransparency = 0.2
	textoEstado.Font = Enum.Font.GothamBold
	textoEstado.TextSize = 13
	textoEstado.TextXAlignment = Enum.TextXAlignment.Left
	textoEstado.Parent = holder

	losangoUI = losango
	statusUI = textoEstado
end

criarIndicadorUI()

local btnAutoClickUI

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
	print("[Hitbox VOID]", ativo and "ATIVADO (ON)" or "DESATIVADO (OFF)")
end

if getgenv then
	getgenv().SetTargetLockUI = atualizarVisual
end

atualizarVisual(false)

-- ==========================================
-- NO ANIMATION (PACOTE PADRAO + SEM SOCO / SEM ESPECIAL G)
-- ==========================================
local NOMES_MOVIMENTO_PADRAO = {
	"idle", "walk", "run", "jump", "fall", "swim", "climb", "land", "freefall", "running", "walking"
}

local PALAVRAS_ACAO_SOCO_G = {
	"punch", "hit", "attack", "atk", "combat", "fight", "combo",
	"grab", "catch", "special", "ult", "skill", "ability", "g_", "kick", "slap"
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
end

LocalPlayer.CharacterAdded:Connect(function()
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
			end
		end
		task.wait(0.1)
	end
end)

local function getCharAndRoot(plr)
	local char = plr and plr.Character
	if not char then return nil, nil, nil end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum and hum.Health <= 0 then return char, nil, hum end
	local root = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
	return char, root, hum
end

-- ==========================================
-- SPEED POR CFRAME (SEM ALTERAR WALKSPEED)
-- ==========================================
local function obterDirecaoMovimentoCFrame(hum)
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

local function aplicarSpeedCFrame(dt)
	if not speedCFrameAtivo then return end
	if UserInputService:GetFocusedTextBox() then return end

	local char, meuRoot, hum = getCharAndRoot(LocalPlayer)
	if not char or not meuRoot or not hum then return end
	if hum.Sit then return end

	local dir = obterDirecaoMovimentoCFrame(hum)
	if dir.Magnitude > 0.01 then
		local passo = dir * (speedCFrameValor * math.clamp(dt, 0.001, 0.05))
		pcall(function()
			meuRoot.CFrame = meuRoot.CFrame + passo
		end)
	end
end

local function splitListaNomes(texto)
	local lista = {}
	if not texto or texto:match("^%s*$") then
		return lista
	end
	for token in texto:gmatch("[^%s,;|]+") do
		local limpo = token:lower()
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
		if nomeUser:find(termo, 1, true) or nomeDisplay:find(termo, 1, true) then
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
			local char, root = getCharAndRoot(plr)
			if char and root then
				local isAMG = ehAmigoAMG(plr)
				local isFocus = temFiltroFocusAtivo() and ehAlvoFocus(plr)

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

				local deveExpandir = hitboxAtivo and (not isAMG) and ehAlvoFocus(plr)
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
	frame.Size = UDim2.new(0, 188, 0, 326)
	frame.Position = UDim2.new(1, -202, 1, -382)
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
	titulo.Text = "Hitbox VOID"
	titulo.TextColor3 = ROXO_NEXUS
	titulo.Font = Enum.Font.GothamBold
	titulo.TextSize = 13
	titulo.TextXAlignment = Enum.TextXAlignment.Center
	titulo.Parent = frame

	local btnAuto = Instance.new("TextButton")
	btnAuto.Size = UDim2.new(1, -16, 0, 24)
	btnAuto.Position = UDim2.new(0, 8, 0, 28)
	btnAuto.BackgroundColor3 = BOTAO_CINZA
	btnAuto.Text = "AutoClick VOID (E): OFF"
	btnAuto.TextColor3 = Color3.fromRGB(235, 235, 240)
	btnAuto.Font = Enum.Font.GothamBold
	btnAuto.TextSize = 11
	btnAuto.BorderSizePixel = 0
	btnAuto.Parent = frame
	Instance.new("UICorner", btnAuto).CornerRadius = UDim.new(0, 4)
	aplicarBordaRoxa(btnAuto, 1)

	local btnLock = Instance.new("TextButton")
	btnLock.Size = UDim2.new(1, -16, 0, 24)
	btnLock.Position = UDim2.new(0, 8, 0, 56)
	btnLock.BackgroundColor3 = targetLockHabilitadoNoPainel and BOTAO_ROXO_ON or BOTAO_CINZA
	btnLock.Text = targetLockHabilitadoNoPainel and "Target Lock: ON" or "Target Lock: OFF"
	btnLock.TextColor3 = Color3.fromRGB(255, 255, 255)
	btnLock.Font = Enum.Font.GothamBold
	btnLock.TextSize = 11
	btnLock.BorderSizePixel = 0
	btnLock.Parent = frame
	Instance.new("UICorner", btnLock).CornerRadius = UDim.new(0, 4)
	aplicarBordaRoxa(btnLock, 1)

	local btnNoAnim = Instance.new("TextButton")
	btnNoAnim.Size = UDim2.new(1, -16, 0, 24)
	btnNoAnim.Position = UDim2.new(0, 8, 0, 84)
	btnNoAnim.BackgroundColor3 = noAnimationAtivo and BOTAO_ROXO_ON or BOTAO_CINZA
	btnNoAnim.Text = noAnimationAtivo and "No Animation: ON" or "No Animation: OFF"
	btnNoAnim.TextColor3 = Color3.fromRGB(255, 255, 255)
	btnNoAnim.Font = Enum.Font.GothamBold
	btnNoAnim.TextSize = 11
	btnNoAnim.BorderSizePixel = 0
	btnNoAnim.Parent = frame
	Instance.new("UICorner", btnNoAnim).CornerRadius = UDim.new(0, 4)
	aplicarBordaRoxa(btnNoAnim, 1)

	local btnSpeed = Instance.new("TextButton")
	btnSpeed.Size = UDim2.new(1, -16, 0, 24)
	btnSpeed.Position = UDim2.new(0, 8, 0, 112)
	btnSpeed.BackgroundColor3 = speedCFrameAtivo and BOTAO_ROXO_ON or BOTAO_CINZA
	btnSpeed.Text = speedCFrameAtivo and "Speed (CFrame): ON" or "Speed (CFrame): OFF"
	btnSpeed.TextColor3 = Color3.fromRGB(255, 255, 255)
	btnSpeed.Font = Enum.Font.GothamBold
	btnSpeed.TextSize = 11
	btnSpeed.BorderSizePixel = 0
	btnSpeed.Parent = frame
	Instance.new("UICorner", btnSpeed).CornerRadius = UDim.new(0, 4)
	aplicarBordaRoxa(btnSpeed, 1)

	local btnHit = Instance.new("TextButton")
	btnHit.Size = UDim2.new(0.5, -10, 0, 24)
	btnHit.Position = UDim2.new(0, 8, 0, 141)
	btnHit.BackgroundColor3 = hitboxAtivo and BOTAO_ROXO_ON or BOTAO_CINZA
	btnHit.Text = hitboxAtivo and "Hitbox: ON" or "Hitbox: OFF"
	btnHit.TextColor3 = Color3.fromRGB(255, 255, 255)
	btnHit.Font = Enum.Font.GothamBold
	btnHit.TextSize = 10
	btnHit.BorderSizePixel = 0
	btnHit.Parent = frame
	Instance.new("UICorner", btnHit).CornerRadius = UDim.new(0, 4)
	aplicarBordaRoxa(btnHit, 1)

	local btnVis = Instance.new("TextButton")
	btnVis.Size = UDim2.new(0.5, -10, 0, 24)
	btnVis.Position = UDim2.new(0.5, 2, 0, 141)
	btnVis.BackgroundColor3 = hitboxVisivel and BOTAO_ROXO_ON or BOTAO_CINZA
	btnVis.Text = hitboxVisivel and "Visivel: Sim" or "Visivel: Nao"
	btnVis.TextColor3 = Color3.fromRGB(255, 255, 255)
	btnVis.Font = Enum.Font.GothamBold
	btnVis.TextSize = 10
	btnVis.BorderSizePixel = 0
	btnVis.Parent = frame
	Instance.new("UICorner", btnVis).CornerRadius = UDim.new(0, 4)
	aplicarBordaRoxa(btnVis, 1)

	-- Slider Speed (CFrame)
	local lblSpeed = Instance.new("TextLabel")
	lblSpeed.Size = UDim2.new(1, -16, 0, 14)
	lblSpeed.Position = UDim2.new(0, 8, 0, 169)
	lblSpeed.BackgroundTransparency = 1
	lblSpeed.Text = "Speed: " .. tostring(speedCFrameValor)
	lblSpeed.TextColor3 = Color3.fromRGB(225, 225, 235)
	lblSpeed.Font = Enum.Font.GothamMedium
	lblSpeed.TextSize = 11
	lblSpeed.TextXAlignment = Enum.TextXAlignment.Left
	lblSpeed.Parent = frame

	local speedSliderBg = Instance.new("TextButton")
	speedSliderBg.Name = "SpeedSliderTrack"
	speedSliderBg.Size = UDim2.new(1, -16, 0, 13)
	speedSliderBg.Position = UDim2.new(0, 8, 0, 185)
	speedSliderBg.BackgroundColor3 = BOTAO_CINZA
	speedSliderBg.Text = ""
	speedSliderBg.AutoButtonColor = false
	speedSliderBg.BorderSizePixel = 0
	speedSliderBg.Parent = frame
	Instance.new("UICorner", speedSliderBg).CornerRadius = UDim.new(1, 0)
	aplicarBordaRoxa(speedSliderBg, 1)

	local speedFill = Instance.new("Frame")
	speedFill.Size = UDim2.new(0.22, 0, 1, 0)
	speedFill.BackgroundColor3 = ROXO_NEXUS
	speedFill.BorderSizePixel = 0
	speedFill.Parent = speedSliderBg
	Instance.new("UICorner", speedFill).CornerRadius = UDim.new(1, 0)

	local speedKnob = Instance.new("Frame")
	speedKnob.Size = UDim2.new(0, 13, 0, 13)
	speedKnob.Position = UDim2.new(0.22, 0, 0.5, 0)
	speedKnob.AnchorPoint = Vector2.new(0.5, 0.5)
	speedKnob.BackgroundColor3 = Color3.fromRGB(245, 245, 250)
	speedKnob.BorderSizePixel = 0
	speedKnob.Parent = speedSliderBg
	Instance.new("UICorner", speedKnob).CornerRadius = UDim.new(1, 0)
	aplicarBordaRoxa(speedKnob, 1)

	-- Slider Hitbox Size
	local lblSize = Instance.new("TextLabel")
	lblSize.Size = UDim2.new(1, -16, 0, 14)
	lblSize.Position = UDim2.new(0, 8, 0, 202)
	lblSize.BackgroundTransparency = 1
	lblSize.Text = "Size: " .. tostring(hitboxSize)
	lblSize.TextColor3 = Color3.fromRGB(225, 225, 235)
	lblSize.Font = Enum.Font.GothamMedium
	lblSize.TextSize = 11
	lblSize.TextXAlignment = Enum.TextXAlignment.Left
	lblSize.Parent = frame

	local sliderBg = Instance.new("TextButton")
	sliderBg.Name = "SizeSliderTrack"
	sliderBg.Size = UDim2.new(1, -16, 0, 13)
	sliderBg.Position = UDim2.new(0, 8, 0, 218)
	sliderBg.BackgroundColor3 = BOTAO_CINZA
	sliderBg.Text = ""
	sliderBg.AutoButtonColor = false
	sliderBg.BorderSizePixel = 0
	sliderBg.Parent = frame
	Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(1, 0)
	aplicarBordaRoxa(sliderBg, 1)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(0.28, 0, 1, 0)
	fill.BackgroundColor3 = ROXO_NEXUS
	fill.BorderSizePixel = 0
	fill.Parent = sliderBg
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

	local knob = Instance.new("Frame")
	knob.Size = UDim2.new(0, 13, 0, 13)
	knob.Position = UDim2.new(0.28, 0, 0.5, 0)
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.BackgroundColor3 = Color3.fromRGB(245, 245, 250)
	knob.BorderSizePixel = 0
	knob.Parent = sliderBg
	Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
	aplicarBordaRoxa(knob, 1)

	local minSize, maxSize = 3, HITBOX_MAX_SLIDER
	local arrastandoSpeed = false
	local arrastandoSize = false
	local arrastandoPainel = false
	local offsetPainel = Vector2.zero

	local function aplicarSpeedPorPosicaoX(posX)
		local largura = math.max(speedSliderBg.AbsoluteSize.X, 1)
		local rel = math.clamp((posX - speedSliderBg.AbsolutePosition.X) / largura, 0, 1)
		speedCFrameValor = math.clamp(math.floor((SPEED_CFRAME_MIN + rel * (SPEED_CFRAME_MAX - SPEED_CFRAME_MIN)) + 0.5), SPEED_CFRAME_MIN, SPEED_CFRAME_MAX)
		local pct = (speedCFrameValor - SPEED_CFRAME_MIN) / (SPEED_CFRAME_MAX - SPEED_CFRAME_MIN)
		speedFill.Size = UDim2.new(pct, 0, 1, 0)
		speedKnob.Position = UDim2.new(pct, 0, 0.5, 0)
		lblSpeed.Text = "Speed: " .. tostring(speedCFrameValor)
	end

	local function aplicarSizePorPosicaoX(posX)
		local largura = math.max(sliderBg.AbsoluteSize.X, 1)
		local rel = math.clamp((posX - sliderBg.AbsolutePosition.X) / largura, 0, 1)
		hitboxSize = math.clamp(math.floor((minSize + rel * (maxSize - minSize)) + 0.5), minSize, maxSize)
		local pct = (hitboxSize - minSize) / (maxSize - minSize)
		fill.Size = UDim2.new(pct, 0, 1, 0)
		knob.Position = UDim2.new(pct, 0, 0.5, 0)
		lblSize.Text = "Size: " .. tostring(hitboxSize)
		sincronizarHitboxEMarcadores()
	end

	speedSliderBg.MouseButton1Down:Connect(function()
		arrastandoSpeed = true
		arrastandoSize = false
		arrastandoPainel = false
		local mousePos = UserInputService:GetMouseLocation()
		aplicarSpeedPorPosicaoX(mousePos.X)
	end)

	sliderBg.MouseButton1Down:Connect(function()
		arrastandoSize = true
		arrastandoSpeed = false
		arrastandoPainel = false
		local mousePos = UserInputService:GetMouseLocation()
		aplicarSizePorPosicaoX(mousePos.X)
	end)

	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and not arrastandoSpeed and not arrastandoSize then
			arrastandoPainel = true
			offsetPainel = Vector2.new(
				input.Position.X - frame.AbsolutePosition.X,
				input.Position.Y - frame.AbsolutePosition.Y
			)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			if arrastandoSpeed then
				aplicarSpeedPorPosicaoX(input.Position.X)
			elseif arrastandoSize then
				aplicarSizePorPosicaoX(input.Position.X)
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
			arrastandoSpeed = false
			arrastandoSize = false
			arrastandoPainel = false
		end
	end)

	local boxAMG = Instance.new("TextBox")
	boxAMG.Size = UDim2.new(1, -16, 0, 23)
	boxAMG.Position = UDim2.new(0, 8, 0, 237)
	boxAMG.BackgroundColor3 = BOTAO_CINZA
	boxAMG.Text = ""
	boxAMG.PlaceholderText = "AMG (ex: ana pedro)..."
	boxAMG.PlaceholderColor3 = Color3.fromRGB(150, 150, 162)
	boxAMG.TextColor3 = Color3.fromRGB(240, 240, 245)
	boxAMG.Font = Enum.Font.Gotham
	boxAMG.TextSize = 11
	boxAMG.ClearTextOnFocus = false
	boxAMG.BorderSizePixel = 0
	boxAMG.Parent = frame
	Instance.new("UICorner", boxAMG).CornerRadius = UDim.new(0, 4)
	aplicarBordaRoxa(boxAMG, 1)

	boxAMG:GetPropertyChangedSignal("Text"):Connect(function()
		amgTexto = boxAMG.Text
		sincronizarHitboxEMarcadores()
	end)

	local boxFocus = Instance.new("TextBox")
	boxFocus.Size = UDim2.new(1, -16, 0, 23)
	boxFocus.Position = UDim2.new(0, 8, 0, 264)
	boxFocus.BackgroundColor3 = BOTAO_CINZA
	boxFocus.Text = ""
	boxFocus.PlaceholderText = "Focus (ex: alvo1 alvo2)..."
	boxFocus.PlaceholderColor3 = Color3.fromRGB(150, 150, 162)
	boxFocus.TextColor3 = Color3.fromRGB(240, 240, 245)
	boxFocus.Font = Enum.Font.Gotham
	boxFocus.TextSize = 11
	boxFocus.ClearTextOnFocus = false
	boxFocus.BorderSizePixel = 0
	boxFocus.Parent = frame
	Instance.new("UICorner", boxFocus).CornerRadius = UDim.new(0, 4)
	aplicarBordaRoxa(boxFocus, 1)

	boxFocus:GetPropertyChangedSignal("Text"):Connect(function()
		focusTexto = boxFocus.Text
		sincronizarHitboxEMarcadores()
	end)

	local atalhos = Instance.new("TextLabel")
	atalhos.Size = UDim2.new(1, -16, 0, 14)
	atalhos.Position = UDim2.new(0, 8, 0, 291)
	atalhos.BackgroundTransparency = 1
	atalhos.Text = "Gatilho: E  |  Painel: J"
	atalhos.TextColor3 = Color3.fromRGB(165, 165, 178)
	atalhos.Font = Enum.Font.Gotham
	atalhos.TextSize = 10
	atalhos.Parent = frame

	local rodape = Instance.new("TextLabel")
	rodape.Name = "FooterCredits"
	rodape.Size = UDim2.new(1, -16, 0, 14)
	rodape.Position = UDim2.new(0, 8, 1, -17)
	rodape.BackgroundTransparency = 1
	rodape.Text = "By: VOID Santos7x"
	rodape.TextColor3 = Color3.fromRGB(255, 255, 255)
	rodape.Font = Enum.Font.GothamMedium
	rodape.TextSize = 9
	rodape.Parent = frame

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

	btnNoAnim.MouseButton1Click:Connect(function()
		noAnimationAtivo = not noAnimationAtivo
		btnNoAnim.Text = noAnimationAtivo and "No Animation: ON" or "No Animation: OFF"
		btnNoAnim.BackgroundColor3 = noAnimationAtivo and BOTAO_ROXO_ON or BOTAO_CINZA
		sincronizarNoAnimation()
	end)

	btnSpeed.MouseButton1Click:Connect(function()
		speedCFrameAtivo = not speedCFrameAtivo
		btnSpeed.Text = speedCFrameAtivo and "Speed (CFrame): ON" or "Speed (CFrame): OFF"
		btnSpeed.BackgroundColor3 = speedCFrameAtivo and BOTAO_ROXO_ON or BOTAO_CINZA
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

	local pctSpeedInicial = math.clamp((speedCFrameValor - SPEED_CFRAME_MIN) / (SPEED_CFRAME_MAX - SPEED_CFRAME_MIN), 0, 1)
	speedFill.Size = UDim2.new(pctSpeedInicial, 0, 1, 0)
	speedKnob.Position = UDim2.new(pctSpeedInicial, 0, 0.5, 0)
	lblSpeed.Text = "Speed: " .. tostring(speedCFrameValor)

	local pctSizeInicial = math.clamp((hitboxSize - minSize) / (maxSize - minSize), 0, 1)
	fill.Size = UDim2.new(pctSizeInicial, 0, 1, 0)
	knob.Position = UDim2.new(pctSizeInicial, 0, 0.5, 0)
	lblSize.Text = "Size: " .. tostring(hitboxSize)

	painelFrameUI = frame
	btnAutoClickUI = btnAuto
end

criarPainelHitbox()
atualizarVisual(ativo)
sincronizarNoAnimation()

task.spawn(function()
	while true do
		local estaLigado = ativo
		if getgenv and getgenv().UniversalTargetLockActive ~= nil then
			estaLigado = getgenv().UniversalTargetLockActive
		end

		if estaLigado and ATIVAR_AUTOCLICK_JUNTO then
			if typeof(mouse1click) == "function" then
				pcall(mouse1click)
			else
				pcall(function()
					VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
					VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
				end)
			end
			task.wait(DELAY_CLIQUE)
		else
			task.wait(0.05)
		end
	end
end)

local function distanciaPara(meuRoot, alvoRoot)
	if not meuRoot or not alvoRoot or not alvoRoot.Parent then
		return math.huge
	end
	return (alvoRoot.Position - meuRoot.Position).Magnitude
end

local function acharMaisProximo(meuRoot)
	local melhorRoot = nil
	local menorDist = DISTANCIA_MAXIMA

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and not ehAmigoAMG(plr) and ehAlvoFocus(plr) then
			local _, r = getCharAndRoot(plr)
			if r then
				local d = (r.Position - meuRoot.Position).Magnitude
				if d <= DISTANCIA_MAXIMA and d > 0.1 and d < menorDist then
					menorDist = d
					melhorRoot = r
				end
			end
		end
	end

	return melhorRoot, menorDist
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
	elseif input.KeyCode == TECLA_ATALHO then
		setEstado(not ativo)
	elseif input.KeyCode == TECLA_PAINEL and painelFrameUI then
		painelFrameUI.Visible = not painelFrameUI.Visible
	end
end)

pcall(function()
	RunService:UnbindFromRenderStep("UniversalCharTargetLock")
end)
RunService.RenderStepped:Connect(aplicarFocoNoAlvo)
RunService.Stepped:Connect(aplicarFocoNoAlvo)
RunService.Heartbeat:Connect(function(dt)
	aplicarFocoNoAlvo()
	aplicarSpeedCFrame(dt)
end)

task.spawn(function()
	while true do
		pcall(sincronizarHitboxEMarcadores)
		task.wait(0.25)
	end
end)

Players.PlayerRemoving:Connect(function(plr)
	limparMarcador(plr)
end)

print("[Hitbox VOID] Speed por CFrame + slider adicionados ao painel!")
