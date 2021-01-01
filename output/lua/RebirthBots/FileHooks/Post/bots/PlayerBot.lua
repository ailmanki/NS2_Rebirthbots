Script.Load("lua/RebirthBots/bots/MinigunBrain.lua")


local personalities = {
    {["names"] = {"Shooty", "ShooterMcShooterface", "FPSer", "XxXkillaXxX", "SniperLyfe", "Bulletz4Breakfast", "XenoMorphing", "SeekNDstroy", "supercodplayer1995", "woman_respector69"},
        ["aim"] = 0.9,
        ["help"] = 0.0,
        ["aggro"] = 0.9,
        ["sneaky"] = true,
        ["tricky"] = false
    },
    {["names"] = {"garbage_fire.jpg", "Apache Attack Helicopter", "Poor Life Decisions", "Suspiciously Slow", "Kony Hawk Pro Slaver", "Shaving Ryan's Privates", "Not A Human, Promise", "The Terrible Spicy Tea", "Believe it or not, France", "Nipple of the North", "Hank Hill", "Obesity Related Illness", "Nein Lives", "Gorge of the Jungle", "Sock Full of Shame", "Country-Steak:Sauce", "Only Couches Pull Out", "Stop Dying, you Cowards!", "Stone Cold Steve Autism", "Syndrome of a Down", "I Only Love My Mom", "I Hope Senpai Notices Me", "Harry P. Ness"},
        ["aim"] = 0.5,
        ["help"] = 0.9,
        ["aggro"] = 0.4,
        ["sneaky"] = true,
        ["tricky"] = false
    },
    {["names"] = {"IronHorse", "BeigeAlert", "McGlaspie", "Flayra", "Ghoul", "sclark39", "fsfod", "rantology", "WasabiOne"},
        ["aim"] = 0.0,
        ["help"] = 0.0,
        ["aggro"] = 0.0,
        ["sneaky"] = false,
        ["tricky"] = false
    },
    {["names"] = {"Tachi", "Bleu", "Jon", "Nordic", "Tiny Rick", "Bums", "jusma", "Fluffy Cloud Zombie", "barlth", "wooza", "Death", "Sog", "technicsix", "Parite.B", "Term", "AmarBot"},
        ["aim"] = 0.8,
        ["help"] = 0.5,
        ["aggro"] = 0.5,
        ["sneaky"] = true,
        ["tricky"] = true
    },
}

function PlayerBot:OnThink()
    PROFILE("PlayerBot:OnThink")

    Bot.OnThink(self)

    local player = self:GetPlayer()
    if player then
        player.is_a_robot = true
    end
    
    self:_LazilyInitBrain()

    if not self.initializedBot then
        local botType = personalities[math.random(#personalities)]
        if not botType.nameNum then
            botType.nameNum =  math.random(#botType.names)
        end
        local botName = botType.names[botType.nameNum]
        botType.nameNum = (botType.nameNum) % #botType.names + 1
        self.botName = botName
        self.aimAbility = botType.aim
        self.helpAbility = botType.help
        self.aggroAbility = botType.aggro
        self.sneakyAbility = botType.sneaky
        self.trickyAbility = botType.tricky
        self.initializedBot = true
    end
        
    self:UpdateNameAndGender()
end

function PlayerBot:GetNamePrefix()
    return "BOT "
end

function PlayerBot:_LazilyInitBrain()
    local player = self:GetPlayer()
    if not player then return end
    
    if self.brain == nil then
        
        if player:isa("Marine") then
            self.brain = MarineBrain()
        elseif player:isa("Skulk") then
            self.brain = SkulkBrain()
        elseif player:isa("Gorge") then
            self.brain = GorgeBrain()
        elseif player:isa("Lerk") then
            self.brain = LerkBrain()
        elseif player:isa("Fade") then
            self.brain = FadeBrain()
        elseif player:isa("Onos") then
            self.brain = OnosBrain()
        elseif player:isa("Exo") then
            self.brain = MinigunBrain()
        end

        if self.brain ~= nil then
            self.brain:Initialize()
            player.botBrain = self.brain
            self.aim = BotAim()
            self.aim:Initialize(self)
        end

    else
    
        -- destroy brain if we are ready room
        if player:isa("ReadyRoomPlayer") then
            self.brain = nil
            player.botBrain = nil
        end

    end

end


function PlayerBot:UpdateNameAndGender()
    PROFILE("PlayerBot:UpdateNameAndGender")
    
    local player = self:GetPlayer()

    if self.botSetName == nil and player then

        local name = player:GetName()
        
        self.botSetName = true
        
        name = self:GetNamePrefix()..TrimName(self.botName)
        player:SetName(name)

		self.client.variantData = {
            isMale = math.random() < 0.8,
            marineVariant = kMarineHumanVariants[kMarineHumanVariants[math.random(1, #kMarineHumanVariants)]],
            skulkVariant = kSkulkVariants[kSkulkVariants[math.random(1, #kSkulkVariants)]],
            gorgeVariant = kGorgeVariants[kGorgeVariants[math.random(1, #kGorgeVariants)]],
            lerkVariant = kLerkVariants[kLerkVariants[math.random(1, #kLerkVariants)]],
            fadeVariant = kFadeVariants[kFadeVariants[math.random(1, #kFadeVariants)]],
            onosVariant = kOnosVariants[kOnosVariants[math.random(1, #kOnosVariants)]],
            rifleVariant = kRifleVariants[kRifleVariants[math.random(1, #kRifleVariants)]],
            pistolVariant = kPistolVariants[kPistolVariants[math.random(1, #kPistolVariants)]],
            axeVariant = kAxeVariants[kAxeVariants[math.random(1, #kAxeVariants)]],
            shotgunVariant = kShotgunVariants[kShotgunVariants[math.random(1, #kShotgunVariants)]],
            exoVariant = kExoVariants[kExoVariants[math.random(1, #kExoVariants)]],
            flamethrowerVariant = kFlamethrowerVariants[kFlamethrowerVariants[math.random(1, #kFlamethrowerVariants)]],
            grenadeLauncherVariant = kGrenadeLauncherVariants[kGrenadeLauncherVariants[math.random(1, #kGrenadeLauncherVariants)]],
            welderVariant = kWelderVariants[kWelderVariants[math.random(1, #kWelderVariants)]],
            hmgVariant = kHMGVariants[kHMGVariants[math.random(1, #kHMGVariants)]],
            shoulderPadIndex = 0
		}
        self.client:GetControllingPlayer():OnClientUpdated(self.client)
        
    end
    
end


local kSayTeamDelay = 20 -- don't want to make them too chatty
function PlayerBot:SendTeamMessage(message, extraTime)

    if self.brain then
        local brain = self.brain
        if not extraTime then
            extraTime = 0
        end
        if not brain.timeLastSayTeam or brain.timeLastSayTeam + kSayTeamDelay + extraTime < Shared.GetTime() then
            
            local chatMessage = string.UTF8Sub(message, 1, kMaxChatLength)
            
            if string.len(chatMessage) > 0 then
                
                local player = self:GetPlayer()
                local playerName = player:GetName()
                local playerLocationId = player.locationId
                local playerTeamNumber = player:GetTeamNumber()
                local playerTeamType = player:GetTeamType()
                
                local players = GetEntitiesForTeam("Player", playerTeamNumber)
                for _, player in ipairs(players) do
                    Server.SendNetworkMessage(player, "Chat", BuildChatMessage(true, playerName, playerLocationId, playerTeamNumber, playerTeamType, chatMessage), true)
                end
            end
            
            brain.timeLastSayTeam = Shared.GetTime()
        end
    end
end



--
-- Responsible for generating the "input" for the bot. This is equivalent to
-- what a client sends across the network.
--
function PlayerBot:GenerateMove()
    PROFILE("PlayerBot:GenerateMove")

    if gBotDebug:Get("spam") then
        Log("PlayerBot:GenerateMove")
    end

    self:_LazilyInitBrain()

    local move = Move()

    -- Brain will modify move.commands and send desired motion to self.motion
    if self.brain then

        -- always clear view each frame if we have a move direction
        if self:GetMotion().desiredMoveTarget then
            self:GetMotion():SetDesiredViewTarget(nil)
        end
        self.brain:Update(self,  move)

    end

    -- Now do look/wasd
    local player = self:GetPlayer()
    if player then
    
        if self.brain and self.brain.teamBrain and not player:GetIsAlive() then
            self.brain.teamBrain:UnassignBot(self)
        end
        
        local viewDir, moveDir, doJump = self:GetMotion():OnGenerateMove(player)

        move.yaw = GetYawFromVector(viewDir) - player:GetBaseViewAngles().yaw
        move.pitch = GetPitchFromVector(viewDir)

        moveDir.y = 0
        moveDir = moveDir:GetUnit()
        local zAxis = Vector(viewDir.x, 0, viewDir.z):GetUnit()
        local xAxis = zAxis:CrossProduct(Vector(0, -1, 0))
        local moveZ = moveDir:DotProduct(zAxis)
        local moveX = moveDir:DotProduct(xAxis)
        move.move = GetNormalizedVector(Vector(moveX, 0, moveZ))

        if doJump then
            move.commands = AddMoveCommand(move.commands, Move.Jump)
        end

    end
    
    return move

end