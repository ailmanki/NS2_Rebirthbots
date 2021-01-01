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

